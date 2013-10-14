set_default(:mysql_host, "localhost")
set_default(:mysql_pid) { "/var/run/postgresql/9.1-main.pid" }
set_default(:mysql_user) { application }
set_default(:mysql_password) { Capistrano::CLI.password_prompt "MySQL Password: " }
set_default(:mysql_database) { "#{application}_production" }

namespace :mysql do
  desc "Install the latest stable release of MySQL."
  task :install, roles: :db, only: {primary: true} do
    run "#{sudo} apt-get -y update"
    run "#{sudo} apt-get -y install mysql-server libapache2-mod-auth-mysql php5-mysql", :pty => true do |ch, stream, data|
      ch.send_data("#{mysql_password}\n\r") if data =~ /password/
    end

    run "#{sudo} mysql_install_db"
  end
  after "deploy:install", "mysql:install"

  # desc "Create a database for this application."
  # task :create_database, roles: :db, only: {primary: true} do
  #   run %Q{#{sudo} -u postgres psql -c "create user #{postgresql_user} with password '#{postgresql_password}';"}
  #   run %Q{#{sudo} -u postgres psql -c "create database #{postgresql_database} owner #{postgresql_user};"}
  # end
  # after "deploy:setup", "mysql:create_database"

  # desc "Generate the database.yml configuration file."
  # task :setup, roles: :app do
  #   run "mkdir -p #{shared_path}/config"
  #   template "postgresql.yml.erb", "#{shared_path}/config/database.yml"
  # end
  # after "deploy:setup", "postgresql:setup"

  # desc "Symlink the database.yml file into latest release"
  # task :symlink, roles: :app do
  #   run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  # end
  # after "deploy:finalize_update", "postgresql:symlink"
end
