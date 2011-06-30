http        = require('http')

# module globals
DB_CRASHREPORTS  = "" #crashreport collection in db, set by init function
SETTINGS         = {} #global settings

STACK_SIMILARITY_LINES = 6

crash_similarity = (crashreport) ->

    stack_similarity_value = (stackframes) ->
        similarity = []
        for i in [0..(STACK_SIMILARITY_LINES-1)]
            if stackframes[i]?
                similarity.push stackframes[i].func #function name
                similarity.push stackframes[i].location.replace /\:\d+$/, '' #sourcefile without linenum
        return similarity.join ' '

    parse_stacktrace = (stacktrace) ->
        stackframes = []
        stack_regexp = /^#(\d+)\s+((0x[\da-fA-F]+)\s+in)?\s+(([^ \(]+)(\([^\)]*\))?)\s+(\([^\)]*\))(\s+(at|from)\s+([^ ]+).*)?$/
        #                 ^^^^^    ^^^^^^^^^^^^^^^           ^^^^^^^^^^^^^^^^^^^^^     ^^^^^^^^^^^^    ^^^^^^^^^   ^^^^^^^
        #                 frame    address                   func     args             context         isLib       location

        for line in crashreport["stack-trace"].crashstack
            match = stack_regexp.exec(line)
            if match
                [_, frameNr, _, address, _, func, args, context, _, isLib, location] = match
                stackframe =
                    "frameNr"  : frameNr
                    "address"  : if address then address else ""
                    "func"     : func
                    "args"     : if args then args else ""
                    "context"  : context
                    "location" : if location then location else ""

                stackframes[frameNr] = stackframe
                #break if frameNr >= STACK_SIMILARITY_LINES #break if enought frames for similarity check
        #console.log stackframes #debug
        return stackframes

    similarity_value =  crashreport["stack-trace"].crash_reason
    similarity_value += " " + stack_similarity_value(parse_stacktrace(crashreport["stack-trace"].crashstack))

    return similarity_value


get_crashreports = (cb) ->
    DB_CRASHREPORTS.find().run (err,arr) ->
        return if err? then cb err, null else cb null, arr

get_crashreport_by_id = (id, cb) ->
    DB_CRASHREPORTS.find({"id":id}).one().run (err,crashreport) ->
        return cb err,null if err?
        return cb "ERROR: Crashreport not found with id:#{id}", null if not crashreport?
        return cb null, crashreport

get_crashreports_by_crashreason = (crashreason, cb) ->
    DB_CRASHREPORTS.find({"stack-trace.crash_reason":crashreason}).run (err,arr) ->
        return if err? then cb err, null else cb null, arr

get_crash_similarity_by_id = (id, cb) ->
    get_crashreport_by_id id, (err, crashreport) ->
        return if err? then cb err, null else cb null, crash_similarity(crashreport)

get_similar_crashes_by_id = (id, cb) ->
    get_crashreport_by_id id, (err, crashreport) ->
        return cb err, null if err?
        # TODO: when similarity value is stored in db, this pre-filtering with crash reason will become obsolete
        get_crashreports_by_crashreason crashreport["stack-trace"].crash_reason, (err, arr) ->
            return cb err, null if err?
            similarity = crash_similarity(crashreport)
            ids_of_similar_crashes = []
            for report in arr
                if similarity == crash_similarity(report)
                    ids_of_similar_crashes.push report.id
            cb null, ids_of_similar_crashes

get_crashreports_by_appname = (appname, cb) ->
    ids_of_crashes = []
    get_crashreports (err, arr) ->
        return cb err, null if err?
        for report in arr
            #TODO: appname now parsed in both server and client side, store appname in db or make query for appname in server side
            if appname == report["rich-core"].cmdline.replace(/\s+.*$/,'').replace(/^.*\//,'')
                ids_of_crashes.push report.id
        cb null, ids_of_crashes


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

    app.get "/similarcrashes/:id", (req, res) ->
        id = req.params.id
        get_similar_crashes_by_id id, (err,data) ->
            if err?
                res.send {"ok":"0","errors": err} if err?
            else
                res.send {"ok":"1","data": data}

    app.get "/crashesforapp/:appname", (req, res) ->
        appname = req.params.appname
        get_crashreports_by_appname appname, (err, data) ->
            if err?
                res.send {"ok":"0","errors": err} if err?
            else
                res.send {"ok":"1","data": data}


exports.init_query_api        = init_query_api
exports.get_crashreport_by_id = get_crashreport_by_id
