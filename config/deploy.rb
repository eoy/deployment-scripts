require "bundler/capistrano"

load "config/recipes/base"
load "config/recipes/nginx"
load "config/recipes/unicorn"
load "config/recipes/postgresql"
load "config/recipes/nodejs"
load "config/recipes/rbenv"
load "config/recipes/check"
# load "config/recipes/monit"

set :stages, %w(production staging)
set :default_stage, 'production'
require 'capistrano/ext/multistage'

set :user, "deployer"

# TODO: Add application name
set :application, "example"

set :deploy_to, "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false

set :scm, "git"
set :repository, "git@github.com:eoy/#{application}.git"
set :branch, "master"

# set :whenever_command, "RAILS_ENV=#{rails_env} bundle exec whenever --update-crontab #{application}"
# require 'whenever/capistrano'

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after "deploy", "deploy:uploads:symlink" # keep only the last 5 releases
after "deploy:uploads:symlink", "deploy:cleanup"
# after "whenever:update_crontab", "deploy:manual_crontab"

namespace :deploy do
  # Unicorn commands
  %w[start stop upgrade].each do |command|
    desc "#{command} unicorn server"
    task command, roles: :app, except: {no_release: true} do
      run "/etc/init.d/unicorn_#{application} #{command}"
    end
  end

  # Update crontab manually
  desc "Update the crontab file"
  task :manual_crontab, :roles => :app, :except => { :no_release => true } do
    run "cd #{release_path} && RAILS_ENV=#{rails_env} bundle exec whenever --update-crontab #{application}"
  end

  desc "Zero-downtime restart of Unicorn"
  task :restart, :except => { :no_release => true } do
    run "kill -s USR2 `cat /tmp/unicorn.#{application}.pid`"
  end

  desc "Remote console"
  task :console, :roles => :app do
    env = "#{rails_env}"
    server = find_servers(:roles => [:app]).first
    run_with_tty server, %W( ./script/rails console #{env} )
  end

  task :setup_config, roles: :app do
    sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
    sudo "ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn_#{application}"
    run "mkdir -p #{shared_path}/config"
    put File.read("config/database.example.yml"), "#{shared_path}/config/database.yml"
    puts "Creating uploads folder.."
    run "mkdir -p #{shared_path}/uploads"
    puts "Done."
    puts "Now edit the config files in #{shared_path}."
  end
  after "deploy:setup", "deploy:setup_config"

  def run_with_tty(server, cmd)
    # looks like total pizdets
    command = []
    command += %W( ssh -t #{gateway} -l #{self[:gateway_user] || self[:user]} ) if     self[:gateway]
    command += %W( ssh -t )
    command += %W( -p #{server.port}) if server.port
    command += %W( -l #{user} #{server.host} )
    command += %W( cd #{current_path} )
    # have to escape this once if running via double ssh
    command += [self[:gateway] ? '\&\&' : '&&']
    command += Array(cmd)
    system *command
  end

  # Symlink config
  task :symlink_config, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "deploy:symlink_config"

  task :symlink_unicorn, roles: :app do
    run "ln -nfs #{release_path}/config/unicorn_#{rails_env}.rb #{release_path}/config/unicorn.rb"
  end
  after "deploy:finalize_update", "deploy:symlink_unicorn"

  # Symlink Uploads
  namespace :uploads do
    desc "Link uploads from shared to current"
    task :symlink do
      run "cd #{current_path}/public; rm -rf uploads; ln -s #{shared_path}/uploads ."
      run "cd #{current_path}/public; rm -rf images; ln -s #{shared_path}/images ."
    end
  end

  # PostgreSQL
  namespace :pg do
    %w[migrate rollback drop create prepare seed].each do |command|
      desc "#{command} PostgreSQL database"
      task command, roles: :app do
        run "cd #{current_path}; RAILS_ENV=#{rails_env} bundle exec rake db:#{command}"
      end
    end
  end

  # PostgreSQL
  namespace :db do
    %w[migrate rollback drop create prepare seed].each do |command|
      desc "#{command} PostgreSQL database"
      task command, roles: :app do
        run "cd #{current_path}; RAILS_ENV=#{rails_env} bundle exec rake db:#{command}"
      end
    end
  end

  namespace :ts do
    %w[index start stop restart reindex rebuild].each do |command|
      desc "#{command} Thinking Sphinx server"
      task command do
        run "cd #{current_path}; RAILS_ENV=#{rails_env} bundle exec rake ts:#{command}"
      end
    end
  end

  # Delayed Job commands
  namespace :dj do
    %w[start stop].each do |command|
      desc "#{command} Delayed_job worker"
      task command, roles: :app do
        run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job #{command}"
      end
    end
  end

  namespace :assets do
    task :precompile, :roles => :web, :except => { :no_release => true } do
      from = source.next_revision(current_revision)
      if capture("cd #{latest_release} && #{source.local.log(from)} vendor/assets/ app/assets/ | wc -l").to_i > 0
        run %Q{cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} #{asset_env} assets:precompile}
      else
        logger.info "Skipping asset pre-compilation because there were no asset changes"
      end
    end
  end

  before "deploy", "deploy:check_revision"
  # before "deploy", "deploy:ts:stop"
  # after "deploy", "deploy:ts:rebuild"
end

namespace :log do
  desc "A pinch of tail"
  task :tail, :roles => :app do
    run "tail -n 10000 -f #{shared_path}/log/#{rails_env}.log" do |channel, stream, data|
      puts "#{data}"
      break if stream == :err
    end
  end
end
