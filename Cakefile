{spawn} = require 'child_process'

run_cmd = (cmd, args, cb) ->
    console.log "#{cmd} #{args.join(' ')}"
    cmd_process = spawn cmd, args

    cmd_process.stdout.on 'data', (data) -> console.log data.toString()
    cmd_process.stderr.on 'data', (data) -> console.log data.toString()

    cmd_process.on 'exit', (code) ->
        return cb? "ERROR: #{cmd} process exited with code: #{code}" if code != 0
        cb? null

# Import production database to development environment
#TODO: uses staging data while production data not yet available!
task 'db:import', 'Import production database to development environment', ->

    # Get database dump
    console.log "\x1b[33mGetting database dump... (this may take a while)\x1b[0m"
    run_cmd 'cap', ['staging','db:dump'], (err) ->
        throw err if err?

        #Extract dump
        console.log "\x1b[33mExtracting...\x1b[0m"
        run_cmd 'tar',['-xzf','crash-reports-staging.tar.gz'], (err) ->
            throw err if err?

            #Import dump to database
            console.log "\x1b[33mImporting...\x1b[0m"
            run_cmd 'mongorestore',['--db','crash-reports-development','dump/crash-reports-staging'], (err) ->
                throw err if err?

                #Cleanup
                console.log "\x1b[33mCleanup...\x1b[0m"
                run_cmd 'rm',['crash-reports-staging.tar.gz'], (err) ->
                    throw err if err?
                    console.log "\x1b[33mDone!\x1b[0m"
