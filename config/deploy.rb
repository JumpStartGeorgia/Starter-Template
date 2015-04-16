require 'erb'
require 'mina/multistage'
require 'mina/puma'
require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'

set :deploy_to, lambda { "/home/#{user}/#{application}" }
set :full_current_path, lambda { "#{deploy_to}/#{current_path}" }
set :full_shared_path, lambda { "#{deploy_to}/#{shared_path}" }
set :branch, 'master'
set :shared_paths, ['.env', 'log', 'config/nginx.conf', 'config/puma.rb', 'public/system']
set :forward_agent, true
set :rails_env, lambda { "#{stage}" }

# Puma settings
set :puma_socket, lambda { "#{deploy_to}/tmp/puma/sockets/#{application}-puma.sock" }
set :puma_pid, lambda { "#{deploy_to}/tmp/puma/pid" }
set :puma_state, lambda { "#{deploy_to}/tmp/puma/state" }
set :pumactl_socket, lambda { "#{deploy_to}/tmp/puma/sockets/#{application}-pumactl.sock" }
set :puma_config, lambda { "#{full_current_path}/config/puma.rb" }
set :puma_error_log, lambda { "#{full_shared_path}/log/puma.error.log" }
set :puma_access_log, lambda { "#{full_shared_path}/log/puma.access.log" }
set :puma_env, lambda { "#{rails_env}" }

# Assets settings
set :precompiled_assets_dir, 'public/assets'

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  invoke :'rbenv:load'
end

namespace :reminder do
  task :create_env do
    queue  %[echo ""]
    queue  %[echo "-----> You need to create the .env file in the shared folder on the server; otherwise,"]
    queue  %[echo "          the app won't know your credentials and database migrations will fail on deploy."]
    queue  %[echo "-----> Run the below command in your local Rails root directory to copy the example .env file to"]
    queue  %[echo "          the server, then manually add your credentials to the file."]
    queue  %[echo ""]
    queue  %[echo "cd #{Dir.pwd} && scp .env.example #{user}@#{domain}:#{full_shared_path}/.env"]
    queue  %[echo ""]
  end

  task :add_github_to_known_hosts do
    queue  %[echo ""]
    queue  %[echo "-----> Run the following command on your server to add github to the list of known hosts. This will"]
    queue  %[echo "-----> allow you to deploy (otherwise the git clone step will fail)."]
    queue  %[echo ""]
    queue  %[echo "ssh-keyscan -H github.com >> ~/.ssh/known_hosts"]
    queue  %[echo ""]
  end

  task :symlink_nginx do
    queue  %[echo ""]
    queue  %[echo "-----> Run the following command on your server to create the symlink from the "]
    queue  %[echo "       nginx sites-enabled directory to the app's nginx.conf file:"]
    queue  %[echo ""]
    queue  %[echo "sudo ln -nfs #{full_current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"]
    queue  %[echo ""]
  end

  task :add_to_puma_jungle do
    queue  %[echo ""]
    queue  %[echo "-----> Run the following command on your server to add your app to the list of puma apps in "]
    queue  %[echo "       the file /etc/puma.conf. All apps in this file are automatically started"]
    queue  %[echo "       whenever the server is booted up. They can also be controlled with the script "]
    queue  %[echo "       /etc/init.d/puma (i.e. try running the command '/etc/init.d/puma status')."]
    queue  %[echo ""]
    queue  %[echo "sudo /etc/init.d/puma add #{deploy_to} #{user} #{full_current_path}/config/puma.rb #{full_shared_path}/log/puma.log"]
    queue  %[echo ""]
  end
end

# Put any custom mkdir's in here for   when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{full_shared_path}/log"]
  queue! %[chmod g+rx,u+rwx "#{full_shared_path}/log"]

  queue! %[mkdir -p "#{full_shared_path}/config"]
  queue! %[chmod g+rx,u+rwx "#{full_shared_path}/config"]

  queue! %[mkdir -p "#{full_shared_path}/public/system"]
  queue! %[chmod g+rx,u+rwx "#{full_shared_path}/public/system"]

  queue! %[mkdir -p "#{deploy_to}/tmp/puma/sockets"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/tmp/puma/sockets"]

  queue! %[mkdir -p "#{deploy_to}/tmp/assets"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/tmp/assets"]

  queue %[echo ""]
  queue %[echo "------------------------- REMINDERS -------------------------"]
  queue %[echo ""]
  queue %[echo ""]
  queue %[echo "-------- Before First Deploy --------"]
  queue %[echo ""]

  invoke :'reminder:create_env'
  invoke :'reminder:add_github_to_known_hosts'

  queue %[echo ""]
  queue %[echo "-------- After First Deploy --------"]
  queue %[echo ""]

  invoke 'reminder:symlink_nginx'
  invoke 'reminder:add_to_puma_jungle'
end

namespace :deploy do
  task :check_revision do
    unless `git rev-parse HEAD` == `git rev-parse origin/#{branch}`
      puts "WARNING: HEAD is not the same as origin/#{branch}"
      puts "Run `git push` to sync changes."
      exit
    end

    unless `git status`.include? 'nothing to commit, working directory clean'
      puts "WARNING: There are uncommitted changes to the local git repository, which"
      puts "may cause problems for locally precompiling assets."
      puts "Please clean local repository with `git stash` or `git reset`."
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
          system %[echo "mina #{stage} deploy precompile=true verbose=true"]
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
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    if ENV['verbose']
      set :rsync_verbose, "--verbose"
    else
      set :bundle_options, "#{bundle_options} --quiet"
      set :rsync_verbose, ""
    end

    system %[echo "Note: If this is the first deploy, run 'mina #{stage} setup' to view important reminders"]
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
      invoke :'puma:phased_restart'
    end
  end
end