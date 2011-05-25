
http  = require('http')
util  = require('util')
fs    = require('fs')
_     = require('underscore')
async = require('async')


CRASHREPORTS_FOLDER = "public/crashreport_files"

# import api definition
MANDATORY_FIELDS = ["auth-token","release","product","build","id"]
OPTIONAL_FIELDS  = ["profile","imei","mac"]
MANDATORY_FILES  = ["core","rich-core","stack-trace"]

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
            err.push "unknown format for core (expected .core)" if !property.name.match /\.core/
        when "rich-core"
            err.push "unknown format for core (expected .rcore)" if !property.name.match /\.rcore/
        when "stack-trace"
            err.push "unknown format for core (expected .txt)" if !property.name.match /\.txt/
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
                dest_fname = fileid + "_" + property.name.replace(/.*\//,"") #TODO: check how sometimes name has also path information
                dest_path  = dest_dir + "/" + dest_fname
                #console.log "moving file: " + property.path + " to: " + dest_path #debug

                # copy files
                src_stream = fs.createReadStream property.path
                dst_stream = fs.createWriteStream dest_path
                util.pump src_stream,dst_stream, (err) ->
                    return cb err if err?

                    # copy and parse file properties
                    property_tmp = _.clone property
                    stored_files[fileid] =
                        name: dest_fname
                        path: dest_path
                        type: property_tmp.type
                        origname: property_tmp.name.replace(/.*\//,"") #TODO: check how sometimes name has also path information
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

init_import_api = (settings, app, db) ->
    crashreports = db.collection('crashreports')
    app.post "/api/import", (req, res) ->

        # verify content type (multipart)
        contentType = req.headers['content-type']
        if not (contentType? && contentType.match(/multipart/i))
            return res.send {"ok":"0","errors":"bad content-type header, expected multipart"}

        # TODO: check if custom form options are needed e.g.
        # req.form.uploadDir = basedir + "/tmp"

        req.form.complete (err, fields, files) ->
            return res.send {"ok":"0","errors":err} if err? #form parsing/upload error

            #validate data (TODO: make async when needed, currently no IO operations)
            err = []
            err = err.concat validate_crashreport_fields(fields)
            err = err.concat validate_crashreport_files(files)
            if not _.isEmpty(err)
                res.send {"ok":"0","errors":err.join()}
                return remove_files files #cleanup after error

            #make crashreport file storage folder
            storage_dir = "#{settings.app.root}/#{CRASHREPORTS_FOLDER}/#{fields.id}"
            fs.mkdir storage_dir, 0755, (err) ->
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
                    crashreport.files = stored_files
                    # TODO: put attachment files into an array

                    #console.log "Crashreport: " + util.inspect(crashreport) #debug

                    # store to mongodb
                    q = crashreports.find({'id':crashreport.id}).upsert().update(crashreport)
                    q.run (err) ->
                        if err?
                            res.send {"ok":"0","errors":err}
                            # TODO: cleanup?
                            return
                        res.send {"ok":"1","url":"#{settings.server.url}/crashreports/" + crashreport.id}

exports.init_import_api = init_import_api

