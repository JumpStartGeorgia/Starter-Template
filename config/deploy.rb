require 'erb'
require 'mina/multistage'
require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'

set :user_path, -> { "/home/#{user}" }
set :deploy_to, -> { "#{user_path}/#{application}" }
set :full_current_path, -> { "#{deploy_to}/#{current_path}" }
set :full_shared_path, -> { "#{deploy_to}/#{shared_path}" }
set :full_tmp_path, -> { "#{deploy_to}/tmp" }
set_default :repo_branch, 'master'
set :branch, -> { "#{repo_branch}" }
set :initial_directories, -> { ["#{full_shared_path}/log", "#{full_shared_path}/config", "#{full_shared_path}/public/system", "#{full_tmp_path}/puma/sockets", "#{full_tmp_path}/assets"] }
set :shared_paths, %w(.env log public/system)
set :forward_agent, true
set :rails_env, -> { "#{stage}" }
set :robots_path, -> { "#{full_current_path}/public/robots.txt" }
set_default :visible_to_robots, true

# Puma settings
set :web_server, :puma
set :puma_role, -> { user }
set :puma_socket, -> { "#{deploy_to}/tmp/puma/sockets/puma.sock" }
set :puma_pid, -> { "#{deploy_to}/tmp/puma/pid" }
set :puma_state, -> { "#{deploy_to}/tmp/puma/state" }
set :pumactl_socket, -> { "#{deploy_to}/tmp/puma/sockets/pumactl.sock" }
set :puma_conf, -> { "#{full_current_path}/config/puma.rb" }
set :puma_cmd,       -> { "#{bundle_prefix} puma" }
set :pumactl_cmd,    -> { "#{bundle_prefix} pumactl" }
set :puma_error_log, -> { "#{full_shared_path}/log/puma.error.log" }
set :puma_access_log, -> { "#{full_shared_path}/log/puma.access.log" }
set :puma_log, -> { "#{full_shared_path}/log/puma.log" }
set :puma_env, -> { "#{rails_env}" }
set :puma_port, '9292'

# Nginx settings
set :nginx_conf, -> { "#{full_current_path}/config/nginx.conf" }
set :nginx_symlink, -> { "/etc/nginx/sites-enabled/#{application}" }

# SSL settings
set :ssl_key, -> { "/etc/sslmate/#{web_url}.key" }
set :ssl_cert, -> { "/etc/sslmate/#{web_url}.chained.crt" }

# Assets settings
set :precompiled_assets_dir, 'public/assets'

# Rails settings
set :temp_env_example_path, -> { "#{user_path}/.env.example-#{application}" }
set :shared_env_path, -> { "#{full_shared_path}/.env" }

# Fetch Head location: this file contains the currently deployed git commit hash
set :fetch_head, -> { "#{deploy_to}/scm/FETCH_HEAD" }

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

  desc 'Creates new robots.txt on server from robots.txt.erb template'
  task :generate_robots do
    robots = ERB.new(File.read('./config/robots.txt.erb')).result
    queue %(echo "-----> Generating new public/robots.txt")

    queue %(
    PWD="$(pwd)"
    if [ $PWD = #{user_path} ]; then
      echo "-----> Copying new robots.txt to: #{robots_path}"
      echo '#{robots}' > #{robots_path};
    else
      echo "-----> Copying new puma.rb to: $PWD/public/robots.txt"
      echo '#{robots}' > ./public/robots.txt;
    fi
    )
  end

  namespace :log do
    desc "Tail a log file; set `lines` to number of lines and `log` to log file name; example: 'mina rails:log lines=100 log=production.log'"
    task :tail do
      ENV['n'] ||= '10'
      ENV['f'] ||= "#{stage}.log"

      puts "Tailing file #{ENV['f']}; showing last #{ENV['n']} lines"
      queue %(tail -n #{ENV['n']} -f #{full_current_path}/log/#{ENV['f']})
    end

    desc 'List all log files'
    task :list do
      queue %(ls -la #{full_current_path}/log/)
    end
  end
end

namespace :nginx do
  desc "Generates a new Nginx configuration in the app's shared folder from the local nginx.conf.erb layout."
  task :generate_conf do
    conf = if use_ssl
             queue %(echo "-----> Generating SSL Nginx Config file")
             ERB.new(File.read('./config/nginx_ssl.conf.erb')).result
           else
             queue %(echo "-----> Generating Non-SSL Nginx Config file")
             ERB.new(File.read('./config/nginx.conf.erb')).result
    end

    queue %(
    PWD="$(pwd)"
    if [ $PWD = #{user_path} ]; then
      echo "-----> Copying new nginx.conf to: #{nginx_conf}"
      echo '#{conf}' > #{nginx_conf};
    else
      echo "-----> Copying new nginx.conf to: $PWD/config/nginx.conf"
      echo '#{conf}' > ./config/nginx.conf;
    fi
    )
  end

  desc 'Tests all Nginx configuration files for validity.'
  task :test do |task|
    system %(echo "")
    system %(echo "Testing Nginx configuration files for validity")
    system %(#{sudo_ssh_cmd(task)} 'sudo nginx -t')
    system %(echo "")
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

    queue %(
    PWD="$(pwd)"
    if [ $PWD = #{user_path} ]; then
      echo "-----> Copying new puma.rb to: #{puma_conf}"
      echo '#{conf}' > #{puma_conf};
    else
      echo "-----> Copying new puma.rb to: $PWD/config/puma.rb"
      echo '#{conf}' > ./config/puma.rb;
    fi
    )
  end

  desc 'Start puma'
  task start: :environment do
    queue! %(
      if [ -e '#{pumactl_socket}' ]; then
        echo 'Puma is already running!';
      else
        cd #{deploy_to}/#{current_path} && #{puma_cmd} -q -d -e #{puma_env} -C #{puma_conf}
      fi
        )
  end

  desc 'Stop puma'
  task stop: :environment do
    queue! %(
      if [ -e '#{pumactl_socket}' ]; then
        cd #{deploy_to}/#{current_path} && #{pumactl_cmd} -F #{puma_conf} stop
        rm -f '#{pumactl_socket}'
      else
        echo 'Puma is not running!';
      fi
        )
  end

  desc 'Restart puma'
  task restart: :environment do
    invoke :'puma:stop'
    invoke :'puma:start'
  end

  desc 'Restart puma (phased restart)'
  task phased_restart: :environment do
    queue! %(
      if [ -e '#{pumactl_socket}' ]; then
        cd #{deploy_to}/#{current_path} && #{pumactl_cmd} -F #{puma_conf} phased-restart
      else
        echo 'Puma is not running!';
      fi
        )
  end

  desc 'View status of puma server'
  task status: :environment do
    queue! %(
      if [ -e '#{pumactl_socket}' ]; then
        cd #{deploy_to}/#{current_path} && #{pumactl_cmd} -F #{puma_conf} status
      else
        echo 'Puma is not running!';
      fi
        )
  end

  desc 'View information about puma server'
  task stats: :environment do
    queue! %(
      if [ -e '#{pumactl_socket}' ]; then
        cd #{deploy_to}/#{current_path} && #{pumactl_cmd} -F #{puma_conf} stats
      else
        echo 'Puma is not running!';
      fi
        )
  end

  namespace :jungle do
    desc 'Adds the application to the puma jungle (list of apps controlled by /etc/init.d/puma). Requires sudo_user option.'
    task :add do |task|
      system %(echo "")
      system %(echo "Adding application to puma jungle at /etc/puma.conf")
      system %(#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma add #{deploy_to} #{user} #{puma_conf} #{puma_log}')
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

namespace :git do
  desc 'Remove FETCH_HEAD file containing currently deployed git commit hash; this will force user to precompile on next deploy'
  task :remove_fetch_head do
    queue! %(
      echo '-----> Removing #{fetch_head}'
      rm #{fetch_head}
        )
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

  desc 'Stops puma server, rolls back to previous deploy, and starts puma server'
  task :custom_rollback do
    invoke :'puma:stop'
    invoke :'deploy:rollback'
    invoke :'puma:start'
    invoke :'deploy:assets:copy_current_to_tmp'
    invoke :'git:remove_fetch_head'
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
        deployed_commit = capture(%(cat #{fetch_head})).split(' ')[0]

        # If FETCH_HEAD file does not exist or deployed_commit doesn't look like a hash, ask user to force precompile
        if deployed_commit.nil? || deployed_commit.length != 40
          system %(echo "WARNING: Cannot determine the commit hash of the previous release on the server.")
          system %(echo "If this is your first deploy, deploy like this:")
          system %(echo "")
          system %(echo "mina #{stage} deploy first_deploy=true --verbose")
          system %(echo "")
          system %(echo "If not, you can force precompile like this:")
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
      if port.nil?
        system %(rsync #{rsync_verbose} --recursive --times ./#{precompiled_assets_dir}/. #{user}@#{domain}:#{deploy_to}/tmp/assets)
      else
        system %(rsync #{rsync_verbose} -e 'ssh -p #{port}' --recursive --times --delete ./#{precompiled_assets_dir}/. #{user}@#{domain}:#{deploy_to}/tmp/assets)
      end
    end

    task :copy_tmp_to_current do
      queue %(echo "-----> Copying assets from tmp/assets to current/#{precompiled_assets_dir}")
      queue %(cp -a #{deploy_to}/tmp/assets/. ./#{precompiled_assets_dir})
    end

    task :copy_current_to_tmp do
      queue %(echo "-----> Replacing tmp/assets with current/#{precompiled_assets_dir}")
      queue %(rm -r #{deploy_to}/tmp/assets)
      queue %(cp -a #{full_current_path}/#{precompiled_assets_dir}/. #{deploy_to}/tmp/assets)
    end
  end
end

desc 'Setup directories and .env file; should be run before first deploy.'
task setup: :environment do
  capture(%(ls #{full_shared_path}/.env)).split(' ')[0] == "#{shared_env_path}" ? env_exists = true : env_exists = false

  unless env_exists
    if port.nil?
      system %(scp .env.example #{user}@#{domain}:#{temp_env_example_path})
    else
      system %(scp -P #{port} .env.example #{user}@#{domain}:#{temp_env_example_path})
    end
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
    invoke :'deploy:assets:copy_tmp_to_current'
    invoke :'nginx:generate_conf'
    invoke :'puma:generate_conf'
    invoke :'rails:generate_robots'
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
        invoke :'puma:stop'
        invoke :'puma:start'
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
  command = "ssh #{get_sudo_user(task)}@#{domain} -t"
  command += " -p #{port}" if !port.nil?
  command
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
