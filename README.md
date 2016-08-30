# Rails 5 Starter Template

This Rails 5 Starter Template is meant as a foundation upon which Rails applications can be built quickly and sustainably. It uses the following technologies:

- Ruby: 2.3
- Rails: ~> 5.0.0
- Authentication: Devise 3.5.6
- Authorization: CanCanCan 1.10.1
- Model/Data Translations: Globalize 5.0
- Responsive Design: Twitter Bootstrap Rails 3.2.0
- Error Emails: Exception Notification 4.1
- Database: Postgres
- Deploy: Mina 0.3.8
- Rails Server: Puma 3.4.0
- HTML Server: Nginx


## Getting Started

### With Docker
1. Setup .env file
  1. `cp .env.example .env`
  2. Add Secrets (use `rake secret` to generate values)
  3. Use `postgres` as the value for `DB_USER` and `TEST_DB_USER`
  4. Set database names for `DB_NAME` and `TEST_DB_NAME`, such as starter_template_dev and starter_template_test
2. Install [docker](https://www.docker.com/products/overview)
3. `docker-compose build`
4. `docker-compose up`
5. `docker-compose run web rake db:create db:migrate`
6. `docker-compose run web rake db:seed` (See db/seeds.rb for more seeding options)

### Requirements
The following software/apps should be installed in order to use the template:
* git
* rbenv
* Ruby 2.x
* nginx - for staging/production server

### Copying the Template
You can use this template in one of two ways:
* clone and erase git history to start with clean git log
* clone and keep remote reference to repo so you can pull in template updates

#### Clone and Erase Git History
Using the terminal, go to the directory you want the template to be added to. Copy and run in terminal (or see below for command explanations):

```
git clone git@github.com:JumpStartGeorgia/Bootstrap-Starter.git .
rm -rf .git
git init
```

#### Clone and Setup Remote Reference
Copy and run in terminal (or see below for command explanations):

```
git remote add template git@github.com:JumpStartGeorgia/Starter-Template.git
git remote set-url template no_push --push
git fetch template
git merge template/master
```

1. Add the Starter Template to your Rails project as a remote repository called "template": `git remote add template git@github.com:JumpStartGeorgia/Starter-Template.git`
2. Disable push connection to template repository: `git remote set-url template no_push --push`
3. Run `git fetch template` to update local copy of template repository.
4. Run `git merge template/master` to merge in changes from the template repository into your current branch. If you have committed changes to your project since the last time you merged in the template repository (or if this is your first time merging in the repository), you may have to resolve merge conflicts in your code.
5. Repeat steps #3 and #4 every so often in order to incorporate changes in the template repository.


### Initialize Settings
The template uses the dotenv-rails gem which allows you to save enviornment variables in an .env at the root of the project instead of setting them at the computer level in /etc/environment. There is a .env.example template file that you should copy and rename to .env. The following variables should be set in the .env file:
* SECRET_KEY_BASE - A secret key for the app that can be created by running 'rake secret' at the command line.
* DEVISE_SECRET_KEY - A secret key for the app that can be created by running 'rake secret' at the command line.
* DB_NAME - name of the database
* DB_USER - database user
* DB_PASSWORD - database user password
* TEST_DB_NAME - name of test database (optional)
* TEST_DB_USER - database user (optional)
* TEST_DB_PASSWORD - database user password (optional)

The template uses the exception_notification gem which sends emails when errors occur. In order to send these emails, the following variables need to be defined:
* APPLICATION_ERROR_FROM_EMAIL - the email address to send the email from
* APPLICATION_FEEDBACK_TO_EMAIL - the email address to send the email to
* APPLICATION_FEEDBACK_FROM_EMAIL - the email address to send feedback emails (notifications) from
* APPLICATION_FEEDBACK_FROM_PWD - the password of the email address to send feedback emails (notifications) from


NOTE - after you deploy the app you will have to set these values on the servers.

### Setup Database
After the above settings have been set, run 'rake db:create' from the command line to create the database and run the migrations and seed file. This will create the users and roles table, create default roles, and create the page contents table.


## Guidelines

### Authentication / Authorization
The template uses devise to authenticate and cancancan to authorize. The template does not use oauth login (i.e., facebook), so if you want that you will have to add it.

By default the template comes with three roles: super_admin, site_admin, and content_manager. You can look at the ability.rb file in app/models to see what these roles have access to. You can change these roles as you see fit. If you add/remove roles, make sure to update the admin controllers and views to use these new roles.

The User model contains a method called is? that takes in a role and sees if the user has the role provided. The input can also be an array of roles to see if the user has any of the provided roles.

### Translations
Site interface translations are located in the config/locales folder in yml files. The files are organized into folders to try and make it easier to maintain the translations. You can use the i18n-tasks gem to find translations that are missing (i.e., in English but not in Georgian) along with other helpful methods.

Content translations are done through the globalize gem. You can see an example of this at the top of the PageContent model with the 'translates' setting. There is a translated_inputs partial in views/shared/form that allows you to build nice forms with a tab for each language. You can view the page content form at views/admin/page_contents/_form.html.erb for an example of this in action.


## Helpers

### Annotate
Annotate is gem that will add the table column names to the top of the models. Run the following command after you run a `rake db:migrate` that changes the database structure:
  `bundle exec annotate --exclude fixtures`

### Adding Missing Translations
If you are using translations and are using scopes with `with_translations(I18n.locale)`, content for this locale must exist in order for that scope to return records. To ensure this works, there is a model base class called `AddMissingTranslation` that you can use that has methods to make sure required fields are populated for all locales before saving. You can refer to the PageContent model to see this in action. To use this base class, do the following:
* Update your model definition to inherit from the `AddMissingClass` class:
```ruby
  class PageContent < AddMissingTranslation
```
* Add two private methods at the bottom of the model:
```ruby
  private

  def has_required_translations?(trans)
    trans.title.present?
  end

  def add_missing_translations(default_trans)
    self.title = default_trans.title if self["title_#{Globalize.locale}"].blank?
  end
```
  * has_required_translations? - In this method include a test to make sure the fields that are required have content. If there are more than one required field, simply use an && to combine them all together.
  * add_missing_translations - For each required field listed in the method above, write a statement that sets the value. Simply copy the example and change `title` with whatever the field name is.



## How to Deploy Using Mina

### Setup

Add your stage-specific deploy variables to the files in config/deploy.

### Deploy

1. Run `mina setup`
  - The default stage is set to `staging`, so this command is equivalent to the command `mina staging setup`
2. Run `mina rails:edit_env` and add your project secrets
3. Run `mina deploy first_deploy=true --verbose`
  - If you get the error “Host key verification failed” when mina tries to clone the git repository, you may have to add your repository’s host to known_hosts on your server. You can run one of these two commands on the server to fix that (works for github):
    - `ssh-keyscan -H github.com >> ~/.ssh/known_hosts`
      - Adds github to user’s known hosts
    - `ssh-keyscan -H github.com >> etc/ssh/ssh_known_hosts`
      - Adds github to known hosts for all users
4. Run `mina post_setup sudo_user=<username>`, where `<username>` is a user with sudo permissions on your server. You will need to enter the user’s password a number of times to execute the sudo commands.
5. Deploy further changes with `mina deploy` or `mina deploy --verbose`
6. Repeat these steps for your other stages, simply by inserting the stage name into the command after `mina`. Examples:
  - `mina setup` --> `mina production setup`
  - `mina deploy precompile=true --verbose` --> `mina production deploy precompile=true --verbose`

#### Options (mina deploy <options>)

[precompile=true]  forces precompile assets
[verbose=true]            outputs more information (default is quieter and prettier)

### Commands

Run `mina -T` for a list of mina's commands.

### Precompile Assets Method

Unlike in the standard Mina deploy, assets are precompiled locally and rsynced up to the server in this starter-template. The method is as follows:

1. Determine whether to precompile the assets
   a. If the flag 'precompile=true' is set, then precompile assets
   b. Use git to view difference in the assets files between the commit on the server
      and the commit on the local machine. If there is a difference, precompile assets
   c. If cannot determine the commit on the server, show error and ask user to run deploy with 'precompile=true'
   d. If git diff gives an error, precompile assets
2. If not precompiling assets, skip to step 3. Otherwise...
   a. precompile assets locally
   b. sync tmp/assets on server with local precompiled assets
3. During deploy, copy assets from tmp/assets to current/public/assets

### Puma Jungle (Controlling Multiple Puma Apps)

Setting up the Puma Jungle on the server allows you to run commands such as start, stop, status, etc. for multiple puma apps at one time. You can also configure it to restart all apps whenever the server reboots.

In order to setup the jungle, follow [these steps](https://github.com/puma/puma/tree/master/tools/jungle/init.d). You may have to modify the default scripts to work on your server; if things don't work out of the box, try consulting [this guide](http://dev.mensfeld.pl/2014/02/puma-jungle-script-fully-working-with-rvm-and-pumactl/).

If your primary puma jungle script is stored at the default location `/etc/init.d/puma`, here are some commands you can use (you may have to run with sudo):
 - `/etc/init.d/puma start`
 - `/etc/init.d/puma stop`
 - `/etc/init.d/puma status`
 - `/etc/init.d/puma restart`

This starter template provides access to the puma jungle through mina commands, such as `mina puma:jungle:start`. Run `mina -T puma:jungle` to see all these commands.
