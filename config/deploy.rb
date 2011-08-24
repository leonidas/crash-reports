# Must be set before requiring multistage
set :default_stage, "staging"
require 'capistrano/ext/multistage'
require 'json'

set :user, "www-data"
set :use_sudo, false
set :copy_compression, :zip

set :scm, :git
set :repository, "git://gitorious.org/meego-quality-assurance/crash-reports.git"
set :deploy_via, :remote_cache

set :public_children, %w(img css js)
set :start_script, "./run-server.sh"
set :settings_file, "settings.json"

ssh_options[:forward_agent] = true
ssh_options[:user] = "www-data"

after "deploy:finalize_update", "deploy:install_node_packages"

after "deploy:setup" do
  run "mkdir -p #{shared_path}/crashreport_files"
  #TODO: create shared tmp upload folder
  deploy.settings.setup
end

after "deploy:symlink" do
  run "rm -rf #{current_path}/public/crashreport_files"
  run "ln -nfs #{shared_path}/crashreport_files #{current_path}/public/crashreport_files"
  #TODO: symlink to shared tmp upload folder
  deploy.settings.symlink
end

namespace :deploy do
  desc "Restart the app server"
  task :restart, :roles => :app do
    run "cd #{current_path} && NODE_ENV=#{node_env} #{start_script} --forever stop && sleep 3 && NODE_ENV=#{node_env} #{start_script} --forever start"
  end

  desc "Start the app server"
  task :start, :roles => :app do
    run "cd #{current_path} && NODE_ENV=#{node_env} #{start_script} --forever start"
  end

  desc "Stop the app server"
  task :stop, :roles => :app do
    run "cd #{current_path} && NODE_ENV=#{node_env} #{start_script} --forever stop"
  end

  desc "Install node packages"
  task :install_node_packages, roles => :app do
    run "cd #{release_path} && npm install --mongodb:native"
  end

  namespace :settings do

    desc "Setup settings file and upload to shared folder"
    task :setup do
      settings = JSON.parse File.read("./#{settings_file}")
      settings["app"]["name"]    = app_name
      settings["server"]["host"] = server_host
      settings["server"]["port"] = server_port
      settings["server"]["url"]  = "http://" + server_host
      put JSON.pretty_generate(settings), "#{shared_path}/#{settings_file}"
    end

    desc "Symlink settings from shared folder"
    task :symlink do
      run "rm -f #{current_path}/#{settings_file} && ln -nfs #{shared_path}/#{settings_file} #{current_path}/#{settings_file}"
    end

    desc "Update settings file"
    task :update do
      deploy.settings.setup
      deploy.settings.symlink
      deploy.restart
    end
  end
end
