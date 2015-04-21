require 'erb'
require 'mina/multistage'
require 'mina/puma'
require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'

set :user_path, lambda { "/home/#{user}" }
set :deploy_to, lambda { "#{user_path}/#{application}" }
set :full_current_path, lambda { "#{deploy_to}/#{current_path}" }
set :full_shared_path, lambda { "#{deploy_to}/#{shared_path}" }
set :branch, 'master'
set :shared_directories, %w[log config public/system]
set :shared_files, %w[.env config/nginx.conf config/puma.rb]
set :shared_paths, shared_directories.zip(shared_files).flatten.compact
set :tmp_directories, %w[puma/sockets assets]
set :forward_agent, true
set :rails_env, lambda { "#{stage}" }

# Puma settings
set :puma_socket, lambda { "#{deploy_to}/tmp/puma/sockets/puma.sock" }
set :puma_pid, lambda { "#{deploy_to}/tmp/puma/pid" }
set :puma_state, lambda { "#{deploy_to}/tmp/puma/state" }
set :pumactl_socket, lambda { "#{deploy_to}/tmp/puma/sockets/pumactl.sock" }
set :puma_config, lambda { "#{full_current_path}/config/puma.rb" }
set :puma_error_log, lambda { "#{full_shared_path}/log/puma.error.log" }
set :puma_access_log, lambda { "#{full_shared_path}/log/puma.access.log" }
set :puma_log, lambda { "#{full_shared_path}/log/puma.log" }
set :puma_env, lambda { "#{rails_env}" }

# Nginx settings
set :nginx_conf, lambda { "#{full_current_path}/config/nginx.conf" }
set :nginx_symlink, lambda { "/etc/nginx/sites-enabled/#{application}" }

# Assets settings
set :precompiled_assets_dir, 'public/assets'

# Rails settings
set :temp_env_example_path, lambda { "#{user_path}/.env.example-#{application}" }
set :shared_env_path, lambda { "#{full_shared_path}/.env" }

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  invoke :'rbenv:load'
end

task :reminders do
  system %[echo ""]
  system %[echo "------------------------- REMINDERS -------------------------"]
  system %[echo ""]

  invoke 'reminders:before_deploy'
end

namespace :reminders do
  task :before_deploy do
    system %[echo ""]
    system %[echo "-------- Before First Deploy --------"]
    system %[echo ""]

    invoke 'reminders:before_deploy:edit_env'
    invoke 'reminders:before_deploy:add_github_to_known_hosts'
  end

  namespace :before_deploy do
    task :edit_env do
      system  %[echo ""]
      system  %[echo "-----> You need to add your app's secrets #{full_shared_path}/.env on the server;"]
      system  %[echo "otherwise, the app won't know your credentials and database migrations will fail on deploy."]
      system  %[echo ""]
    end

    task :add_github_to_known_hosts do
      system  %[echo ""]
      system  %[echo "-----> Run the following command on your server to add github to the list of known hosts. This will"]
      system  %[echo "-----> allow you to deploy (otherwise the git clone step will fail)."]
      system  %[echo ""]
      system  %[echo "ssh-keyscan -H github.com >> ~/.ssh/known_hosts"]
      system  %[echo ""]
    end
  end
end

task :setup => :environment do
  capture(%[ls #{full_shared_path}/.env]).split(" ")[0] == "#{shared_env_path}" ? env_exists = true : env_exists = false

  unless env_exists
    system %[scp .env.example #{user}@#{domain}:#{temp_env_example_path}]
  end

  shared_directories.each do |shared_dir|
    queue! %[mkdir -p "#{full_shared_path}/#{shared_dir}"]
    queue! %[chmod g+rx,u+rwx "#{full_shared_path}/#{shared_dir}"]
  end

  tmp_directories.each do |tmp_dir|
    queue! %[mkdir -p "#{deploy_to}/tmp/#{tmp_dir}"]
    queue! %[chmod g+rx,u+rwx "#{deploy_to}/tmp/#{tmp_dir}"]
  end

  unless env_exists
    queue! %[echo "Moving copy of local .env.example to #{shared_env_path}"]
    queue! %[mv #{temp_env_example_path} #{shared_env_path}]
    queue! %[echo ""]
    queue! %[echo "------------------------- IMPORTANT -------------------------"]
    queue! %[echo ""]
    queue! %[echo "Run the following command and add your secrets to the .env file:"]
    queue! %[echo ""]
    queue! %[echo "mina #{stage} rails:edit_env"]
    queue! %[echo ""]
    queue! %[echo "------------------------- IMPORTANT -------------------------"]
    queue! %[echo ""]
  end
end

task :post_setup do
  invoke :'nginx:create_symlink'
  invoke :'puma:jungle:add_application'
end

namespace :nginx do
  task :create_symlink do |task|
    system %[echo ""]
    system %[echo "Creating Nginx symlink: #{nginx_symlink} ===> #{nginx_conf}"]
    system %[#{sudo_ssh_cmd(task)} 'sudo ln -nfs #{nginx_conf} #{nginx_symlink}']
    system %[echo ""]
  end

  task :remove_symlink do |task|
    system %[echo ""]
    system %[echo "Removing Nginx symlink: #{nginx_symlink}"]
    system %[#{sudo_ssh_cmd(task)} 'sudo rm #{nginx_symlink}']
    system %[echo ""]
  end
end

namespace :rails do
  task :edit_env do
    queue %[vim #{shared_env_path}]
  end
end

namespace :deploy do
  task :check_revision do
    unless `git rev-parse HEAD` == `git rev-parse origin/#{branch}`
      system %[echo "WARNING: HEAD is not the same as origin/#{branch}"]
      system %[echo "Run 'git push' to sync changes."]
      exit
    end

    unless `git status`.include? 'nothing to commit, working directory clean'
      system %[echo "WARNING: There are uncommitted changes to the local git repository, which"]
      system %[echo "may cause problems for locally precompiling assets."]
      system %[echo "Please clean local repository with 'git stash' or 'git reset'."]
      exit
    end
  end

  namespace :assets do
    task :decide_whether_to_precompile do
      set :precompile_assets, false
      if ENV['precompile']
        set :precompile_assets, true
      else
        # Locations where assets may have changed; check Gemfile.lock to ensure that gem assets are the same
        asset_files_directories = "app/assets vendor/assets Gemfile.lock"

        current_commit = `git rev-parse HEAD`.strip()

        # Get deployed commit hash from FETCH_HEAD file
        deployed_commit = capture(%[cat #{deploy_to}/scm/FETCH_HEAD]).split(" ")[0]

        # If FETCH_HEAD file does not exist or deployed_commit doesn't look like a hash, ask user to force precompile
        if deployed_commit == nil || deployed_commit.length != 40
          system %[echo "WARNING: Cannot determine the commit hash of the previous release on the server."]
          system %[echo "If this is your first deploy (or you want to skip this error), deploy like this:"]
          system %[echo ""]
          system %[echo "mina #{stage} deploy precompile=true"]
          system %[echo "------ or for more information ------"]
          system %[echo "mina #{stage} deploy precompile=true --verbose"]
          system %[echo ""]
          exit
        else
          git_diff = `git diff --name-only #{deployed_commit}..#{current_commit} #{asset_files_directories}`

          # If git diff length is 0, then the assets are unchanged.
          # If the length is not 0, then one of the following are true:
          #
          # 1) The assets changed and git diff shows those files
          # 2) Git cannot recognize the deployed commit and issues an error
          #
          # In both these situations, precompile assets.
          if git_diff.length == 0
            system %[echo "-----> Assets unchanged; skipping precompile assets"]
          else
            set :precompile_assets, true
          end
        end
      end
    end

    task :local_precompile do
      system %[echo "-----> Cleaning assets locally"]
      system %[bundle exec rake assets:clean RAILS_GROUPS=assets]

      system %[echo "-----> Precompiling assets locally"]
      system %[bundle exec rake assets:precompile RAILS_GROUPS=assets]

      system %[echo "-----> RSyncing remote assets (tmp/assets) with local assets (#{precompiled_assets_dir})"]
      system %[rsync #{rsync_verbose} --recursive --times ./#{precompiled_assets_dir}/. #{user}@#{domain}:#{deploy_to}/tmp/assets]
    end

    task :copy do
      queue %[echo "-----> Copying assets from tmp/assets to current/#{precompiled_assets_dir}"]
      queue %[cp -a #{deploy_to}/tmp/assets/. ./#{precompiled_assets_dir}]
    end
  end
end

namespace :nginx do
  task :generate_conf do
    conf = ERB.new(File.read("./config/nginx.conf.erb")).result()
    queue %[echo "-----> Generating new config/nginx.conf"]
    queue %[echo '#{conf}' > #{full_shared_path}/config/nginx.conf]
  end
end

namespace :puma do
  task :generate_conf do
    conf = ERB.new(File.read("./config/puma.rb.erb")).result()
    queue %[echo "-----> Generating new config/puma.rb"]
    queue %[echo '#{conf}' > #{full_shared_path}/config/puma.rb]
  end

  namespace :jungle do
    task :add_application do |task|
      system %[echo ""]
      system %[echo "Adding application to puma jungle at /etc/puma.conf"]
      system %[#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma add #{deploy_to} #{user} #{puma_config} #{puma_log}']
      system %[echo ""]
    end

    task :remove_application do |task|
      system %[echo ""]
      system %[echo "Removing application from puma jungle at /etc/puma.conf"]
      system %[#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma remove #{deploy_to}']
      system %[echo ""]
    end

    task :start do |task|
      system %[echo ""]
      system %[echo "Starting all puma jungle applications"]
      system %[#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma start']
      system %[echo ""]
    end

    task :stop do |task|
      system %[echo ""]
      system %[echo "Stopping all puma jungle applications"]
      system %[#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma stop']
      system %[echo ""]
    end

    task :status do |task|
      system %[echo ""]
      system %[echo "Checking status of all puma jungle applications"]
      system %[#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma status']
      system %[echo ""]
    end

    task :restart do |task|
      system %[echo ""]
      system %[echo "Restarting all puma jungle applications"]
      system %[#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma restart']
      system %[echo ""]
    end
  end
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    set :rsync_verbose, "--verbose"

    unless verbose_mode?
      set :rsync_verbose, ""
      set :bundle_options, "#{bundle_options} --quiet"
    end

    invoke :'deploy:check_revision'
    system %[echo "Note: If this is the first deploy, run the following command after you finish: 'mina #{stage} post_setup sudo_user=<username>' (insert a user with sudo access into <username>)"]
    invoke :'deploy:assets:decide_whether_to_precompile'
    invoke :'deploy:assets:local_precompile' if precompile_assets
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'deploy:assets:copy'
    invoke :'nginx:generate_conf'
    invoke :'puma:generate_conf'
    invoke :'deploy:cleanup'

    to :launch do
      queue "mkdir -p #{full_current_path}/tmp/"
      queue "touch #{full_current_path}/tmp/restart.txt"
      invoke :'puma:phased_restart'
    end
  end
end

private

def sudo_ssh_cmd(task)
  return "ssh #{get_sudo_user(task)}@#{domain} -t"
end

def get_sudo_user(task)
  sudo_user = ENV['sudo_user']

  if !sudo_user
    system %[echo ""]
    system %[echo "In order to run this command, please include a 'sudo_user' option set to a user"]
    system %[echo "that has sudo permissons on the server:"]
    system %[echo ""]
    system %[echo "mina #{stage} #{task} sudo_user=<username>"]
    system %[echo ""]
    exit
  end

  return sudo_user
end