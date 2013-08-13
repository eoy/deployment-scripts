#!/usr/bin/env puma
appname = "example"
root = "/home/deployer/apps/#{appname}/current"

rails_env = ENV['RAILS_ENV'] || 'development'

threads 4,4

bind  "unix:///tmp/puma.#{appname}.sock"
pidfile "/tmp/puma.#{appname}.pid"
state_path "/tmp/puma.#{appname}.state"

activate_control_app