
EventEmitter = require('events').EventEmitter
async = require('async')

running_migrations = false
migrate_event = new EventEmitter()
migrate_event.setMaxListeners(10000)

stamp_re = new Regexp("(\d+)-.*?\.coffee")

exports.run_migrations = (rootdir, db, callback) ->
    running_migrations = true
    mdir = "#{rootdir}/migrations"

    # TODO: load migration files
    # TODO: read migrations from mongo collection
    # TODO: execute missing migrations in order

    migrations = db.collection("migrations")

    migration_exists = (stamp) -> (callback) ->
        migrations.find(timestamp: stamp).count (err, doc) ->
            return callback err if err?
            callback([stamp, doc > 0])

    mfiles  = fs.readdirSync mdir
    filemap = {}
    exists  = []
    for fn in mfiles
        stamp = stamp_re.match(fn)[1]
        filemap[stamp] = fn
        exists.push migration_exists(stamp)

    # TODO


exports.wrap_http = (f) -> (req, res) ->
    wait_for_migrations ->
        f(req, res)

end_migrations = () ->
    migrate_event.emit "ready"

wait_for_migrations = (callback) ->
    if not running_migrations
        callback()
    else
        migrate_event.once 'ready', callback
