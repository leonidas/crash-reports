set :app_name, "crash-reports"
set :server_host, "#{app_name}.leonidasoy.fi"
set :server_port, 3040

set :application, server_host
set :deploy_to, "/home/#{user}/#{application}"
set :node_env, "production"

ssh_options[:port] = 43398

server server_host, :app, :web, :db, :primary => true

after "deploy:symlink" do
  # Allow robots to index
  run "rm #{current_path}/public/robots.txt"
  run "touch #{current_path}/public/robots.txt"
end

namespace :db do
  desc "Dump and fetch production database"
  task :dump, :roles => :db, :only => {:primary => true} do
    # TODO: mongodump -> tar -> download -> extract
    #  run "cd #{current_path} && mongodump"
    #  get "#{current_path}/mongodbdump.tar", "./mongodbdump.tar"
    #  run "rm #{current_path}/mongodbdump.tar"
  end
end
