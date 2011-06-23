
http        = require('http')
util        = require('util')
fs          = require('fs')
_           = require('underscore')
async       = require('async')
rcoreparser = require('richcore')
stackparser = require('stack-trace')
query_api   = require('query-api')

# module globals

CRASHREPORTS_FOLDER = "crashreport_files"

DB_CRASHREPORTS  = "" #crashreport collection in db (set by init function)
PUBLIC           = "" #absolute path for public folder (set by init function)

# import api definition
MANDATORY_FIELDS = ["auth-token","release","product","build","id"]
OPTIONAL_FIELDS  = ["profile","imei","mac"]
MANDATORY_FILES  = ["core","rich-core","stack-trace"]

update_crashreport = (crashreport_new, cb) ->
    # get old crashreport from db
    query_api.get_crashreport_by_id crashreport_new.id, (err, crashreport) ->
        return cb err if err?

        #copy fields from new crashreport replacing the old ones (does not deep copy!)
        _(crashreport_new).each (v,k) -> crashreport[k] = v

        # TODO: ignore server-side added fields in validation
        #validate the crashreport
        #err = []
        #err = err.concat validate_crashreport_fields(crashreport)
        #err = err.concat validate_crashreport_files(crashreport.files)
        #return cb err.join() if not _.isEmpty(err)

        #parse stack-trace
        stackparser.parse_stack_trace_file "#{PUBLIC}/#{crashreport.files["stack-trace"].path}", (err, stackdata) ->
            return cb err if err?
            crashreport["stack-trace"] = stackdata

            #parse rcore
            rcoreparser.parse_rich_core "#{PUBLIC}/#{crashreport.files["rich-core"].path}", (err, rcoredata) ->
                return cb err if err?
                crashreport["rich-core"] = rcoredata

                # save to db
                save_crashreport crashreport, (err) ->
                    return cb err if err?
                    console.log "debug: Updated crashreport id:#{crashreport.id}" #debug
                    cb null, crashreport


save_crashreport = (crashreport, cb) ->
    console.log "savecrashreport"
    console.log crashreport.files.attachments
    q = DB_CRASHREPORTS.find({'id':crashreport.id}).upsert().update(crashreport)
    q.run (err) ->
        if err?
            cb err
        else
            cb null

validate_crashreport_fields = (fields) ->
    err = []
    data = _.clone(fields) # validation consumes the data object

    # check mandatory fields
    _(MANDATORY_FIELDS).each (f) ->
        if data[f]?
            delete data[f]
        else
            err.push "missing attribute " + f

    # check optional fields
    _(OPTIONAL_FIELDS).each (f) -> delete data[f] if data[f]?

    # check for unknown fields
    _(data).each (value,fieldname) -> err.push "unknown attribute " + fieldname

    err

# file specific validations
validate_file = (property, fileid) ->
    err = []
    switch fileid
        when "core"
            err.push "unknown format for core (expected .core)" unless property.name.match /\.core$/
        when "rich-core"
            err.push "unknown format for rich-core (expected .rcore)" unless property.name.match /(\.rcore$)|(\.lzo$)/
        when "stack-trace"
            err.push "unknown format for stack-trace (expected .txt)" unless property.name.match /\.txt$/
    return err


validate_crashreport_files = (files) ->
    err = []
    data = _.clone(files) # validation consumes the data object

    # check that all files have path, data & type (TODO: is this needed?)
    _(data).each (property,fileid) ->
        if not (property.name? && property.path? && property.type?)
            err.push "invalid file " + fileid + ": missing one of mandatory fields (name,path,type)"
            delete data[fileid]

    # check mandatory files
    _(MANDATORY_FILES).each (f) ->
        if data[f]?
            err = err.concat validate_file data[f], f
            delete data[f]
        else
            err.push "missing attribute " + f

    # check optional files (attachments)
    _(data).each (property,fileid) -> delete data[fileid] if fileid.match /attachment\.\d+/i

    # check for unknown files
    _(data).each (property,fileid) -> err.push "unknown attribute " + fileid

    err

# move files to crashreport specific storage
move_files = (files, dest_dir, move_files_cb) ->

    stored_files = {}
    movefiles_func_arr = []

    # create array of functions for file moving
    _(files).each (property, fileid) ->
        movefiles_func_arr.push (cb) ->
            if property.path?

                #create destination filename and path
                dest_fname = fileid + "_" + property.name.replace(/.*\//,"") #sometimes name has also path information
                dest_path  = "#{dest_dir}/#{dest_fname}"
                #console.log "moving file: " + property.path + " to: " + dest_path #debug

                # copy files
                src_stream = fs.createReadStream property.path
                dst_stream = fs.createWriteStream "#{PUBLIC}/#{dest_path}" #absolute path (assumes files are stored under public folder)
                util.pump src_stream,dst_stream, (err) ->
                    return cb err if err?

                    # copy and parse file properties
                    property_tmp = _.clone property
                    stored_files[fileid] =
                        name: dest_fname
                        path: dest_path
                        type: property_tmp.type
                        origname: property_tmp.name.replace(/.*\//,"") #sometimes name has also path information
                    cb null

    # run file move operations
    async.series movefiles_func_arr, (err) ->
        return move_files_cb? err, null if err?

        # remove temporary files
        remove_files files
        move_files_cb? null, stored_files


#cleanup function for deleting (temporary) files
remove_files = (files) ->
    async.forEach _.pluck(files,"path"),
        (path,cb) ->
            if path?
                #console.log "deleting -> " + path
                fs.unlink path, (e) ->
                    console.log "Error: " + e if e? #debug
                    cb null
        (err) ->
            if err?
                console.log "remove_files error:"
                console.log err

parse_attachments = (files) ->
    attachments_arr = []
    _(files).each (property, fileid) ->
        if fileid.match /attachment\.\d+/i
            attachments_arr.push(property)
            delete files[fileid]
    files["attachments"] = attachments_arr if attachments_arr.length > 0
    return files

init_import_api = (settings, app, db) ->

    DB_CRASHREPORTS = db.collection('crashreports')
    PUBLIC          = "#{settings.app.root}/public"

    app.post "/api/import", (req, res) ->

        # verify content type (multipart)
        contentType = req.headers['content-type']
        if not (contentType? && contentType.match(/multipart/i))
            return res.send {"ok":"0","errors":"bad content-type header, expected multipart"}

        # TODO: check if custom form options are needed e.g.
        # req.form.uploadDir = basedir + "/tmp"

        req.form.complete (err, fields, files) ->
            return res.send {"ok":"0","errors":err} if err? #form parsing/upload error

            #TODO: refactor validation & parsing stages into functions and run with async

            #validate data (TODO: wrap validation into one function)
            err = []
            err = err.concat validate_crashreport_fields(fields)
            err = err.concat validate_crashreport_files(files)
            if not _.isEmpty(err)
                res.send {"ok":"0","errors":err.join()}
                return remove_files files #cleanup after error


            #parse stack-trace file
            stackparser.parse_stack_trace_file files["stack-trace"].path, (err, stackdata) ->
                if err?
                    res.send {"ok":"0","errors":err}
                    return remove_files files #cleanup
                fields["stack-trace"] = stackdata

                #parse rich-core
                rcoreparser.parse_rich_core files["rich-core"].path, (err, rcoredata) ->
                    if err?
                        res.send {"ok":"0","errors":err}
                        return remove_files files #cleanup
                    fields["rich-core"] = rcoredata

                    #make crashreport file storage folder
                    storage_dir = "#{CRASHREPORTS_FOLDER}/#{fields.id}" #dirname from crash id
                    fs.mkdir "#{PUBLIC}/#{storage_dir}", 0755, (err) ->
                        if err? && err.code != "EEXIST"
                            res.send {"ok":"0","errors":err}
                            return remove_files files #cleanup after error

                        # move files to storage folder
                        move_files files, storage_dir, (err, stored_files) ->
                            if err?
                                res.send {"ok":"0","errors":err}
                                return remove_files files #cleanup after error

                            # create crashreport collection
                            crashreport = {}
                            _(fields).each (v,k) -> crashreport[k] = v

                            # parse attachments
                            crashreport.files = parse_attachments(stored_files)

                            # TODO: put attachment files into an array and replace /\./,'_'

                            #console.log "Crashreport: " + util.inspect(crashreport) #debug

                            # store to mongodb
                            save_crashreport crashreport, (err) ->
                                if err?
                                    return res.send {"ok":"0","errors":err} #TODO: cleanup?
                                res.send {"ok":"1","url":"#{settings.server.url}/crashreports/" + crashreport.id}


exports.init_import_api = init_import_api
exports.update_crashreport = update_crashreport
