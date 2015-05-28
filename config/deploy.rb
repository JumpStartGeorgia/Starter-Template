require 'erb'
require 'mina/multistage'
require 'mina/puma'
require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'

set :user_path, -> { "/home/#{user}" }
set :deploy_to, -> { "#{user_path}/#{application}" }
set :full_current_path, -> { "#{deploy_to}/#{current_path}" }
set :full_shared_path, -> { "#{deploy_to}/#{shared_path}" }
set :full_tmp_path, -> { "#{deploy_to}/tmp" }
set :branch, 'master'
set :initial_directories, -> { ["#{full_shared_path}/log", "#{full_shared_path}/config", "#{full_shared_path}/public/system", "#{full_tmp_path}/puma/sockets", "#{full_tmp_path}/assets"] }
set :shared_paths, %w(.env log public/system)
set :forward_agent, true
set :rails_env, -> { "#{stage}" }

# Puma settings
set :puma_socket, -> { "#{deploy_to}/tmp/puma/sockets/puma.sock" }
set :puma_pid, -> { "#{deploy_to}/tmp/puma/pid" }
set :puma_state, -> { "#{deploy_to}/tmp/puma/state" }
set :pumactl_socket, -> { "#{deploy_to}/tmp/puma/sockets/pumactl.sock" }
set :puma_config, -> { "#{full_shared_path}/config/puma.rb" }
set :puma_error_log, -> { "#{full_shared_path}/log/puma.error.log" }
set :puma_access_log, -> { "#{full_shared_path}/log/puma.access.log" }
set :puma_log, -> { "#{full_shared_path}/log/puma.log" }
set :puma_env, -> { "#{rails_env}" }

# Nginx settings
set :nginx_conf, -> { "#{full_shared_path}/config/nginx.conf" }
set :nginx_symlink, -> { "/etc/nginx/sites-enabled/#{application}" }

# Assets settings
set :precompiled_assets_dir, 'public/assets'

# Rails settings
set :temp_env_example_path, -> { "#{user_path}/.env.example-#{application}" }
set :shared_env_path, -> { "#{full_shared_path}/.env" }

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  invoke :'rbenv:load'
end

namespace :rails do
  desc "Opens the deployed application's .env file in vim so that you can edit application secrets."
  task :edit_env do
    queue %(vim #{shared_env_path})
  end
end

namespace :nginx do
  desc "Generates a new Nginx configuration in the app's shared folder from the local nginx.conf.erb layout."
  task :generate_conf do
    conf = ERB.new(File.read('./config/nginx.conf.erb')).result
    queue %(echo "-----> Generating new config/nginx.conf")
    queue %(echo '#{conf}' > #{full_shared_path}/config/nginx.conf)
  end

  desc "Creates a symlink to the app's Nginx configuration in the server's sites-enabled directory."
  task :create_symlink do |task|
    system %(echo "")
    system %(echo "Creating Nginx symlink: #{nginx_symlink} ===> #{nginx_conf}")
    system %(#{sudo_ssh_cmd(task)} 'sudo ln -nfs #{nginx_conf} #{nginx_symlink}')
    system %(echo "")
  end

  desc "Removes the symlink to the app's Nginx configuration from the server's sites-enabled directory."
  task :remove_symlink do |task|
    system %(echo "")
    system %(echo "Removing Nginx symlink: #{nginx_symlink}")
    system %(#{sudo_ssh_cmd(task)} 'sudo rm #{nginx_symlink}')
    system %(echo "")
  end

  desc 'Starts the Nginx server.'
  task :start do |task|
    system %(echo "")
    system %(echo "Starting Nginx.")
    system %(#{sudo_ssh_cmd(task)} 'sudo service nginx start')
    system %(echo "")
  end

  desc 'Stops the Nginx server.'
  task :stop do |task|
    system %(echo "")
    system %(echo "Stopping Nginx.")
    system %(#{sudo_ssh_cmd(task)} 'sudo service nginx stop')
    system %(echo "")
  end

  desc 'Checks the status of the Nginx server. Requires sudo_user option.'
  task :status do |task|
    system %(echo "")
    system %(echo "Checking Nginx status.")
    system %(#{sudo_ssh_cmd(task)} 'sudo service nginx status')
    system %(echo "")
  end
end

namespace :puma do
  desc "Generates a new Puma configuration in the app's shared folder from the local puma.rb.erb layout."
  task :generate_conf do
    conf = ERB.new(File.read('./config/puma.rb.erb')).result
    queue %(echo "-----> Generating new config/puma.rb")
    queue %(echo '#{conf}' > #{full_shared_path}/config/puma.rb)
  end

  namespace :jungle do
    desc 'Adds the application to the puma jungle (list of apps controlled by /etc/init.d/puma). Requires sudo_user option.'
    task :add do |task|
      system %(echo "")
      system %(echo "Adding application to puma jungle at /etc/puma.conf")
      system %(#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma add #{deploy_to} #{user} #{puma_config} #{puma_log}')
      system %(echo "")
    end

    desc 'Removes the application from the puma jungle (list of apps controlled by /etc/init.d/puma). Requires sudo_user option.'
    task :remove do |task|
      system %(echo "")
      system %(echo "Removing application from puma jungle at /etc/puma.conf")
      system %(#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma remove #{deploy_to}')
      system %(echo "")
    end

    desc 'Starts the puma jungle. Requires sudo_user option.'
    task :start do |task|
      system %(echo "")
      system %(echo "Starting all puma jungle applications")
      system %(#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma start')
      system %(echo "")
    end

    desc 'Stops the puma jungle. Requires sudo_user option.'
    task :stop do |task|
      system %(echo "")
      system %(echo "Stopping all puma jungle applications")
      system %(#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma stop')
      system %(echo "")
    end

    desc 'Checks the status of the puma jungle. Requires sudo_user option.'
    task :status do |task|
      system %(echo "")
      system %(echo "Checking status of all puma jungle applications")
      system %(#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma status')
      system %(echo "")
    end

    desc 'Restarts the puma jungle. Requires sudo_user option.'
    task :restart do |task|
      system %(echo "")
      system %(echo "Restarting all puma jungle applications")
      system %(#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma restart')
      system %(echo "")
    end

    desc 'Lists the apps in the puma jungle (outputs /etc/puma.conf). Requires sudo_user option.'
    task :list do |task|
      system %(echo "")
      system %(echo "Listing all apps in puma jungle")
      system %(#{sudo_ssh_cmd(task)} 'sudo cat /etc/puma.conf')
      system %(echo "")
    end
  end
end

namespace :deploy do
  desc 'Ensures that local git repository is clean and in sync with the origin repository used for deploy.'
  task :check_revision do
    unless `git rev-parse HEAD` == `git rev-parse origin/#{branch}`
      system %(echo "WARNING: HEAD is not the same as origin/#{branch}")
      system %(echo "Run 'git push' to sync changes.")
      exit
    end

    unless `git status`.include? 'nothing to commit, working directory clean'
      system %(echo "WARNING: There are uncommitted changes to the local git repository, which")
      system %(echo "may cause problems for locally precompiling assets.")
      system %(echo "Please clean local repository with 'git stash' or 'git reset'.")
      exit
    end
  end

  namespace :assets do
    desc 'Decides whether to precompile assets based on whether there have been changes to the assets since last deploy.'
    task :decide_whether_to_precompile do
      set :precompile_assets, false
      if ENV['precompile'] == 'true'
        set :precompile_assets, true
      else
        # Locations where assets may have changed; check Gemfile.lock to ensure that gem assets are the same
        asset_files_directories = 'app/assets vendor/assets Gemfile.lock'

        current_commit = `git rev-parse HEAD`.strip

        # Get deployed commit hash
        deployed_commit = capture(%(cat #{deploy_to}/scm/FETCH_HEAD)).split(' ')[0]

        # If FETCH_HEAD file does not exist or deployed_commit doesn't look like a hash, ask user to force precompile
        if deployed_commit.nil? || deployed_commit.length != 40
          system %(echo "WARNING: Cannot determine the commit hash of the previous release on the server.")
          system %(echo "If this is your first deploy, deploy like this:")
          system %(echo "")
          system %(echo "mina #{stage} deploy first_deploy=true --verbose")
          system %(echo "")
          system %(echo "To skip this error and force precompile, deploy like this:")
          system %(echo "")
          system %(echo "mina #{stage} deploy precompile=true --verbose")
          system %(echo "")
          exit
        else
          git_diff = `git diff --name-only #{deployed_commit}..#{current_commit} #{asset_files_directories}`

          # If git diff length is not 0, then either 1) the assets have changed or 2) git cannot recognize the deployed
          # commit and issues an error. In both these situations, precompile assets.
          if git_diff.length == 0
            system %(echo "-----> Assets unchanged; skipping precompile assets")
          else
            set :precompile_assets, true
          end
        end
      end
    end

    desc 'Precompile assets locally and rsync to tmp/assets folder on server.'
    task :local_precompile do
      system %(echo "-----> Cleaning assets locally")
      system %(bundle exec rake assets:clean RAILS_GROUPS=assets)

      system %(echo "-----> Precompiling assets locally")
      system %(bundle exec rake assets:precompile RAILS_GROUPS=assets)

      system %[echo "-----> RSyncing remote assets (tmp/assets) with local assets (#{precompiled_assets_dir})"]
      system %(rsync #{rsync_verbose} --recursive --times ./#{precompiled_assets_dir}/. #{user}@#{domain}:#{deploy_to}/tmp/assets)
    end

    task :copy do
      queue %(echo "-----> Copying assets from tmp/assets to current/#{precompiled_assets_dir}")
      queue %(cp -a #{deploy_to}/tmp/assets/. ./#{precompiled_assets_dir})
    end
  end
end

desc 'Setup directories and .env file; should be run before first deploy.'
task setup: :environment do
  capture(%(ls #{full_shared_path}/.env)).split(' ')[0] == "#{shared_env_path}" ? env_exists = true : env_exists = false

  unless env_exists
    system %(scp .env.example #{user}@#{domain}:#{temp_env_example_path})
  end

  initial_directories.each do |dir|
    queue! %(mkdir -p "#{dir}")
    queue! %(chmod g+rx,u+rwx "#{dir}")
  end

  unless env_exists
    queue! %(echo "Moving copy of local .env.example to #{shared_env_path}")
    queue! %(mv #{temp_env_example_path} #{shared_env_path})
    queue! %(echo "")
    queue! %(echo "------------------------- IMPORTANT -------------------------")
    queue! %(echo "")
    queue! %(echo "Run the following command and add your secrets to the .env file:")
    queue! %(echo "")
    queue! %(echo "mina #{stage} rails:edit_env")
    queue! %(echo "")
    queue! %(echo "Then deploy for the first time like this:")
    queue! %(echo "")
    queue! %(echo "mina #{stage} deploy first_deploy=true --verbose")
    queue! %(echo "")
    queue! %(echo "------------------------- IMPORTANT -------------------------")
    queue! %(echo "")
  end
end

desc 'Deploys the current version to the server.'
task deploy: :environment do
  deploy do
    if ENV['first_deploy'] == 'true'
      first_deploy = true
      ENV['precompile'] = 'true'
    end

    set :rsync_verbose, '--verbose'
    unless verbose_mode?
      set :rsync_verbose, ''
      set :bundle_options, "#{bundle_options} --quiet"
    end

    invoke :'deploy:check_revision'
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
      if first_deploy
        invoke :'puma:start'
        queue! %(echo "")
        queue! %(echo "------------------------- IMPORTANT -------------------------")
        queue! %(echo "")
        queue! %(echo "As this is the first deploy, you need to run the following command:")
        queue! %[echo "(Insert a user with sudo access into <username>)"]
        queue! %(echo "")
        queue! %(echo "mina #{stage} post_setup sudo_user=<username>")
        queue! %(echo "")
        queue! %(echo "------------------------- IMPORTANT -------------------------")
        queue! %(echo "")
      else
        invoke :'puma:phased_restart'
      end
    end
  end
end

desc 'Creates Nginx symlink, adds app to puma jungle, and starts and stops Nginx; should be run after first deploy.'
task :post_setup do
  invoke :'nginx:create_symlink'
  invoke :'puma:jungle:add'
  invoke :'nginx:stop'
  invoke :'nginx:start'
end

desc 'Removes application directory from server, removes nginx symlink, removes app from puma jungle and restarts nginx.'
task :destroy do
  invoke :remove_application
  invoke :'nginx:remove_symlink'
  invoke :'puma:jungle:remove'
  invoke :'nginx:stop'
  invoke :'nginx:start'
end

desc 'Removes application directory from server.'
task :remove_application do |task|
  system %(echo "")
  system %(echo "Removing application at #{deploy_to}")
  system %(echo "WARNING: DO NOT ENTER sudo password if you're not sure about this.")
  system %(#{sudo_ssh_cmd(task)} 'sudo rm -rf #{deploy_to}')
  system %(echo "")
end

private

def sudo_ssh_cmd(task)
  "ssh #{get_sudo_user(task)}@#{domain} -t"
end

def get_sudo_user(task)
  sudo_user = ENV['sudo_user']

  unless sudo_user
    system %(echo "")
    system %(echo "In order to run this command, please include a 'sudo_user' option set to a user")
    system %(echo "that has sudo permissons on the server:")
    system %(echo "")
    system %(echo "mina #{stage} #{task} sudo_user=<username>")
    system %(echo "")
    exit
  end

  sudo_user
end
