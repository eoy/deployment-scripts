set_default(:postgresql_host, "localhost")
set_default(:postgresql_pid) { "/var/run/postgresql/9.1-main.pid" }
set_default(:postgresql_user) { application }
set_default(:postgresql_password) { Capistrano::CLI.password_prompt "PostgreSQL Password: " }
set_default(:postgresql_database) { "#{application}_production" }

namespace :php do
  desc "Install PHP5"
  task :install, roles: :db, only: {primary: true} do
    run "#{sudo} apt-get -y update"
    run "#{sudo} apt-get -y install php5 libapache2-mod-php5 php5-mcrypt"
  end
  after "deploy:install", "php:install"
end
