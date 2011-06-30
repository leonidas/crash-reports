set :app_name, "crash-reports"
set :server_host, "#{app_name}.qa.leonidasoy.fi"
set :server_port, 3040

set :application, server_host
set :deploy_to, "/home/#{user}/#{application}"
set :node_env, "staging"
set :keep_releases, 5

ssh_options[:port] = 31915

server server_host, :app, :web, :db, :primary => true

namespace :db do
  desc "Import production database to staging"
  task :import, :roles => :db, :only => {:primary => true} do
    # TODO: (upload -> unpack -> import)
  end

  #TODO: temporary while production data not available
  desc "Dump and fetch staging database"
  task :dump, :roles => :db, :only => {:primary => true} do
    db_name    = "#{app_name}-#{node_env}" #assuming db naming follows app name and node env!
    crashfiles = "./public/crashreport_files/*"
    run "cd #{current_path} && mongodump --db #{db_name} && tar -czf #{db_name}.tar.gz ./dump/#{db_name} #{crashfiles}"
    get "#{current_path}/#{db_name}.tar.gz", "./#{db_name}.tar.gz"
    run "rm #{current_path}/#{db_name}.tar.gz"
  end
end
