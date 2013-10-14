namespace :apache do
  desc "Install latest stable release of apache"
  task :install, roles: :web do
    run "#{sudo} apt-get -y update"
    run "#{sudo} apt-get -y install apache2"
  end
  after "deploy:install", "apache:install"

  # desc "Setup nginx configuration for this application"
  # task :setup, roles: :web do
  #   template "nginx_unicorn.erb", "/tmp/nginx_conf"
  #   run "#{sudo} mv /tmp/nginx_conf /etc/nginx/sites-enabled/#{application}"
  #   run "#{sudo} rm -f /etc/nginx/sites-enabled/default"
  #   restart
  # end
  # after "deploy:setup", "nginx:setup"

  %w[start stop restart].each do |command|
    desc "#{command} apache"
    task command, roles: :web do
      run "#{sudo} service apache #{command}"
    end
  end
end
