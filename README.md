# Starter-Template

This Rails Starter Template is meant as a foundation upon which Rails applications can be built quickly and sustainably. It uses the following technologies:

- Deploy: Mina
- HTML Server: Nginx
- Rails Server: Puma

## Usage

1. Add the Starter Template to your Rails project as a remote repository called "template": `git remote add template git@github.com:JumpStartGeorgia/Starter-Template.git`
2. Disable push connection to template repository: `git remote set-url template no_push --push`
3. Run `git fetch template` to update local copy of template repository.
4. Run `git merge template/master` to merge in changes from the template repository into your current branch. If you have committed changes to your project since the last time you merged in the template repository (or if this is your first time merging in the repository), you may have to resolve merge conflicts in your code.
5. Repeat steps #3 and #4 every so often in order to incorporate changes in the template repository.