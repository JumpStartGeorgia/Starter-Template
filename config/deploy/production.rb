set :domain, 'alpha.jumpstart.ge'
set :user, 'prisoners'
set :application, 'Starter-Template-Production'
# easier to use https; if you use ssh then you have to create key on server
set :repository, 'https://github.com/JumpStartGeorgia/Starter-Template.git'
set :branch, 'master'
set :web_url, ENV['PRODUCTION_WEB_URL']
set :use_ssl, true
