
EventEmitter = require('events').EventEmitter

running_migrations = false
migrate_event = new EventEmitter()

exports.run_migrations = (db, callback) ->
    migrations = db.collection("migrations")

exports.wrap_http = (f) -> (req, res) ->
    wait_for_migrations ->
        f(req, res)

wait_for_migrations = (callback) ->
    if not running_migrations
        callback()
    else
        migrate_event.once 'ready', callback
