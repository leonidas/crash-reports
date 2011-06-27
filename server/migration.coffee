
EventEmitter = require('events').EventEmitter
async = require('async')

running_migrations = false
migrate_event = new EventEmitter()
migrate_event.setMaxListeners(10000)

stamp_re = new Regexp("(\d+)-.*?\.coffee")

exports.run_migrations = (rootdir, db, callback) ->
    running_migrations = true
    mdir = "#{rootdir}/migrations"

    migrations = db.collection("migrations")

    migration_exists = (stamp) -> (callback) ->
        migrations.find(timestamp: stamp).count (err, doc) ->
            return callback err if err?
            callback([stamp, doc > 0])

    run_migration = (stamp) -> (callback) ->
        fs.readFile filemap[stamp], (data) ->
            js = eval(data)
            js.migrate db, (err) ->
                # TODO: handle error from migrate
                doc =
                    timestamp: stamp
                    rundate: new Date()
                    status "ok"

                migrations.insert(doc).run callback


        # TODO: record statistics to migration object
        # TODO: store migration object to mongodb
        # TODO: signal migration finished via callback
        m = {}
        callback null, m

    mfiles  = fs.readdirSync mdir
    mfiles.sort()

    filemap = {}
    exists  = []
    for fn in mfiles
        stamp = stamp_re.match(fn)[1]
        filemap[stamp] = fn
        exists.push migration_exists(stamp)

    async.parallel exists, (err, arr) ->
        if err?
            end_migrations()
            return callback err
        runners = []
        for [stamp, exists] in arr
            runners.push(run_migration stamp) if exists

        async.series runners, (err, arr) ->
            # TODO: rollback etc. on error
            end_migrations()
            callback null


exports.wrap_http = (f) -> (req, res) ->
    wait_for_migrations ->
        f(req, res)

end_migrations = () ->
    running_migrations = false
    migrate_event.emit "ready"

wait_for_migrations = (callback) ->
    if not running_migrations
        callback()
    else
        migrate_event.once 'ready', callback
