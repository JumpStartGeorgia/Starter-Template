set :domain, 'alpha.jumpstart.ge'
set :user, 'prisoners-staging'
set :application, 'Starter-Template-Staging'
# easier to use https; if you use ssh then you have to create key on server
set :repository, 'https://github.com/JumpStartGeorgia/Starter-Template.git'
set :branch, 'master'
set :web_url, ENV['STAGING_WEB_URL']
set :visible_to_robots, false
set :use_ssl, true
