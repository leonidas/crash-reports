# Must be set before requiring multistage
set :default_stage, "staging"
require 'capistrano/ext/multistage'
require 'yaml'

set :user, "www-data"
set :use_sudo, false
set :copy_compression, :zip

set :scm, :git
set :repository, "git://gitorious.org/meego-quality-assurance/crash-reports.git"
set :deploy_via, :remote_cache

set :public_children, %w(img css js)
set :start_script, "./run-server.sh"


ssh_options[:forward_agent] = true
ssh_options[:user] = "www-data"

after "deploy:finalize_update", "deploy:install_node_packages"

after "deploy:setup" do
  run "mkdir -p #{shared_path}/crashreport_files"
  #TODO: create shared tmp upload folder

after "deploy:symlink" do
  run "rm -rf #{current_path}/public/crashreport_files"
  run "ln -nfs #{shared_path}/crashreport_files #{current_path}/public/crashreport_files"
  #TODO: symlink to shared tmp upload folder

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
    run "cd #{release_path} && npm install --unsafe"
  end

end
