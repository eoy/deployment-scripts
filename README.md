## Eoy's Deployment Scripts

* Requires Ruby 1.9.2 or higher.
* Requires ´```gem 'pg' # PostgreSQL```´ in Gemfile

# Steps

Replace `127.0.0.1` with the ip of the server
```
1. ssh root@127.0.0.1
2. adduser deployer --ingroup admin
3. exit
4. cat ~/.ssh/id_rsa.pub | ssh deployer@127.0.0.1 -p 22 'cat >> ~/.ssh/authorized_keys'
5. Edit deploy.rb (IP & app name)
6. Edit unicorn_init.sh (app name)
7. Edit unicorn_prodution.rb (2x app name)
8. Edit config/recipes/templates/nginx_unicorn.erb (domain)
9. Uncomment load 'deploy/assets' in your capfile
10. cap deploy:install (installs latest nginx, unicorn, node.js, postgresql, rbenv, ruby 1.9.3-p125) 
11. cap deploy:setup (symlinks application, creates database for application, creates startup scripts for unicorn)
12. cap deploy:cold
```
