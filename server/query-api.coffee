http        = require('http')

# module globals
DB_CRASHREPORTS  = "" #crashreport collection in db, set by init function
SETTINGS         = {} #global settings

get_crashreport_by_id = (id, cb) ->
        DB_CRASHREPORTS.find({"id":id}).run (err,arr) ->
            return cb err,null if err?
            return cb "ERROR: Crashreport not found with id:#{id}", null if arr.length == 0
            if arr.length == 1
                cb null, arr[0]
            else
                cb "ERROR: Multiple crashlogs found with id:#{id}", null

init_query_api = (settings, app, db) ->
    DB_CRASHREPORTS = db.collection('crashreports')
    SETTINGS        = settings

    app.get "/crashreports/:id", (req, res) ->
        id = req.params.id
        get_crashreport_by_id id, (err,crashdata) ->
            if err?
                res.send {"ok":"0","errors": err} if err?
            else
                res.send {"ok":"1","crashdata": crashdata}


exports.init_query_api        = init_query_api
exports.get_crashreport_by_id = get_crashreport_by_id
