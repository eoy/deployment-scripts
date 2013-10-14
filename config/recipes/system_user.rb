set_default(:deployer_password) { Capistrano::CLI.password_prompt "UNIX password for user #{deploy_user}: " }
set_default(:dont_create, "false") # flag

namespace :system_user do

  desc "Creates user for deployment: #{user}"
  task :create_user do
    close_sessions
    set :deploy_user, user  # saves the content of user variable, so it can be restored later
    set :user, root_user    # sets user to root for first login

    run "sed -n /#{deploy_user}/{p} /etc/passwd" do |channel, stream, data|
      if data.match("#{deploy_user}")   # checks if deploy_user already exists (for multiple recipe invocation)
        set :dont_create, "true"
      end
    end

    puts "Skip user creation is: #{dont_create}"

    if dont_create == "false"
      run "#{sudo} adduser #{deploy_user} --ingroup admin" do |channel, stream, data|
        channel.send_data("#{deployer_password}\n") if data =~ /UNIX password/
        # setting UNIX prompt data to default
        channel.send_data("\n") if data =~ /(Full Name|Room Number|Work Phone|Home Phone|Other|information correct)/
      end
      puts "User #{deploy_user} created!"
    end
  end
  before "deploy:install", "system_user:create_user" # just reference: already set in base.rb

  # desc "Adds ssh public keys for deployment user."
  # task :copy_ssh_keys do
  #   # user is still root
  #   if dont_create == "false"
  #     run "#{sudo} mkdir -p /home/#{deploy_user}/.ssh"
  #     put File.read(ssh_public_key), "/tmp/authorized_keys"
  #     run "#{sudo} mv /tmp/authorized_keys /home/#{deploy_user}/.ssh/"
  #     run "#{sudo} chown -R #{deploy_user} /home/#{deploy_user}/.ssh"
  #     run "#{sudo} chgrp -R admin /home/#{deploy_user}/.ssh"
  #     run "#{sudo} chmod 600 /home/#{deploy_user}/.ssh/authorized_keys"
  #     puts "SSH keys added for #{deploy_user}!"
  #   end
  #   close_sessions
  #   set :user, deploy_user
  # end
  # after "system_user:create_user", "system_user:copy_ssh_keys"

end
