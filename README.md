## Eoy's Deployment Scripts

Requires Ruby 1.9.2 or higher.

# - Steps -

```
1. ssh root@176.58.100.160
2. adduser deployer --ingroup admin
3. exit
4. Edit deploy.rb (IP & app name)
5. Edit unicorn_init.sh (app name)
6. Edit unicorn.rb (2x app name)
7. cap deploy:install (installs latest nginx, unicorn, node.js, postgresql, rbenv, ruby 1.9.3-p125) 
8. cap deploy:setup (symlinks application, creates database for application, creates startup scripts for unicorn)
9. cap deploy:cold
```
