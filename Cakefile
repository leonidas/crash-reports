
{exec} = require 'child_process'

# Import production database to development environment
#TODO: uses staging data while production data not yet available!
task 'db:import', 'Import production database to development environment', ->
    console.log "getting database dump... this may take a while"
    exec "cap staging db:dump", (err,stdout,stderr) ->
    #exec "cap production db:dump", (err,stdout,stderr) ->
        console.log stderr if stderr?
        throw err if err
        console.log stdout if stdout?

        console.log "extracting and importing..."
        exec "tar -xzf crash-reports-staging.tar.gz && mongorestore --db crash-reports-development dump/crash-reports-staging && rm crash-reports-staging.tar.gz", (err,stdout,stderr) ->
        #exec "tar -xzf crash-reports-production.tar.gz && mongorestore --db crash-reports-development dump/crash-reports-production && rm crash-reports-production.tar.gz", (err,stdout,stderr) ->
            console.log stderr if stderr?
            throw err if err
            console.log stdout if stdout?
            console.log "done!"

