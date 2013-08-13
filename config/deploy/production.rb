# TODO: Change IP
server "127.0.0.1", :web, :app, :db, primary: true
set :rails_env, 'production'
set :whenever_environment, 'production'