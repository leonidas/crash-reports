require.paths.unshift './node_modules'
require.paths.push 'server'

monmon = require('monmon').monmon
_      = require('underscore')

db  = monmon.use('crash-reports')
crashreports_db = db.collection('crashreports')

read_crashreports = (cb) ->
    crashreports_db.find().run (err,arr) ->
        return cb err,null if err?
        console.log "#{arr.length} crashreports read"
        cb null, arr

write_crashreports = (arr, cb) ->
    console.log "#{arr.length} crashreports to write"
    #crashreports_db.find({'id':crashreport.id}).upsert().update(crashreport).run
        # if err?
        #     cb err
        # else
        #     cb null
    cb null, null

modify_crashreports = (arr, cb) ->
    arr_modified = _(arr).map (crashreport) ->
        _(crashreport.files).each (properties,fileid) ->
            console.log "before:#{properties.path}"
            properties.path = properties.path.replace /^.*\/public\//,''
            crashreport.files["fileid"] = properties
            console.log "after:#{properties.path}"
        crashreport
    cb null, arr_modified

read_crashreports (err,arr) ->
    throw err if err?
#    console.log arr[0] #debug
    modify_crashreports arr, (err,arr) ->
        throw err if err?
        console.log arr[3] #debug
        console.log "done!"


