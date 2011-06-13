require.paths.unshift './node_modules'
require.paths.push 'server'

monmon = require('monmon')
_      = require('underscore')
async  = require('async')
db     = monmon.monmon.use('crash-reports')
crashreports_db = db.collection('crashreports')

read_crashreports = (cb) ->
    crashreports_db.find().run (err,arr) ->
        return cb err,null if err?
        console.log "#{arr.length} crashreports read"
        cb null, arr

write_crashreports = (arr, cb) ->
    async.forEachSeries arr,
        (crashreport, cb_next) ->
            console.log "store crashreport id:#{crashreport.id} to db" #debug
            crashreports_db.find({'id':crashreport.id}).upsert().update(crashreport).run (err) ->
                cb_next err if err?
                cb_next null
        (err) ->
            cb err if err?
            cb null

modify_crashreports = (arr, cb) ->
    arr_modified = _(arr).map (crashreport) ->
        _(crashreport.files).each (properties,fileid) ->
            #console.log "before:#{properties.path}"
            properties.path = properties.path.replace /^.*\/public\//,''
            crashreport.files["fileid"] = properties
            #console.log "after:#{properties.path}"
        crashreport
    cb null, arr_modified

read_crashreports (err,arr) ->
    throw err if err?
    modify_crashreports arr, (err,arr) ->
        throw err if err?
        write_crashreports arr, (err) ->
            throw err if err?
            monmon.closeAll()
            console.log "done!"
