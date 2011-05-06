appname  = <<<application name>>>
hostname = "#{appname}.qa.leonidasoy.fi"

set :application, hostname
set :deploy_to, "/home/#{user}/#{application}"
set :node_env, "staging"

ssh_options[:port] = 31915

server hostname, :app, :web, :db, :primary => true

namespace :db do
  desc "Import production database to staging"
  task :import, :roles => :db, :only => {:primary => true} do
    # TODO: upload -> unpack -> mongoimport
    #  upload "./qadash_dbdump.tar", "#{current_path}/qadash_dbdump.tar"
    #  run "cd #{current_path} && mongoimport
  end
end
