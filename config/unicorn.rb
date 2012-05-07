# TODO: Add app name
root = "/home/deployer/apps/example/current"
working_directory root
pid "#{root}/tmp/pids/unicorn.pid"
stderr_path "#{root}/log/unicorn.log"
stdout_path "#{root}/log/unicorn.log"

# TODO: Add app name
listen "/tmp/unicorn.example.sock"
worker_processes 2
timeout 30
