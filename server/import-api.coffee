
http  = require('http')
util  = require('util')
fs    = require('fs')
_     = require('underscore')
async = require('async')

CRASHREPORTS_FOLDER = "public/crashreports/"

# import api definition
MANDATORY_FIELDS = ["auth-token","release","product","build","id"]
OPTIONAL_FIELDS  = ["profile","imei","mac"]

MANDATORY_FILES  = ["core","rich-core","stack-trace"]

validate_crashreport_fields = (fields,err) ->   
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

validate_crashreport_files = (files,err) ->
    data = _.clone(files) # validation consumes the data object

    # file specific validations
    validate_file = (property, fileid) ->
        switch fileid
            when "core"
                err.push "unknown format for core (expected .core)" if !property.name.match /\.core/
            when "rich-core"
                err.push "unknown format for core (expected .rcore)" if !property.name.match /\.rcore/
            when "stack-trace"
                err.push "unknown format for core (expected .txt)" if !property.name.match /\.txt/
        return

    # check that all files have path, data & type (TODO: is this needed?)
    _(data).each (property,fileid) ->
        if not (property.name? && property.path? && property.type?)
            err.push "invalid file " + fileid + ": missing mandatory fields (name,path,type)"
            delete data[fileid]

    # check mandatory files        
    _(MANDATORY_FILES).each (f) ->
        if data[f]?
            validate_file data[f], f
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
                dest_fname = fileid + "_" + property.filename
                dest_path  = dest_dir + "/" + dest_fname
                #console.log "moving file: " + property.path + " to: " + dest_path #debug

                # copy files
                src_stream = fs.createReadStream property.path
                dst_stream = fs.createWriteStream dest_path
                util.pump src_stream,dst_stream, (err) ->
                    if err?
                        cb err
                    else
                        # copy and parse file properties 
                        property_tmp = _.clone property 
                        stored_files[fileid] =
                            name: dest_fname
                            path: dest_path
                            type: property_tmp.type
                        cb null

    # run file move operations 
    async.series movefiles_func_arr, (err) ->
        if err?
            move_files_cb err, null
        else
            remove_files files #remove temporary files
            move_files_cb null, stored_files


#cleanup function for deleting (temporary) files
remove_files = (files) ->
    async.forEach _.pluck(files,"path"),
        (path,cb) ->
            if path?
                #console.log "deleting -> " + path
                fs.unlink path, (e) ->
                    #console.log "Error: " + e #debug
                    cb null
        (err) ->
            #intentionally empty

init_import_api = (basedir, app, db) ->
    crashreports = db.collection('crashreports')

    app.post "/api/import", (req, res) ->

        # verify content type (multipart)
        contentType = req.headers['content-type']
        if not (contentType? && contentType.match(/multipart/i))
            return res.send {"ok":"0","errors":"bad content-type header, expected multipart"}   

        # TODO: check if custom form options are needed e.g.
        # req.form.uploadDir = basedir + "/tmp"

        req.form.complete (err, fields, files) ->
            if err
                # form parsing/upload error
                return res.send {"ok":"0","errors":err}             
            else
                
                #validate data (TODO: make async when needed, currently no IO operations)
                err = []
                validate_crashreport_fields(fields,err)
                validate_crashreport_files(files,err)
                if not _.isEmpty(err)
                    res.send {"ok":"0","errors":err.join()} 
                    return remove_files files #cleanup after error
                else

                    #make crashreport file storage folder
                    storage_dir = basedir + "/" + CRASHREPORTS_FOLDER + fields.id
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
                            _(fields).each        (v,k) -> crashreport[k] = v
                            _(stored_files).each  (v,k) -> crashreport[k] = v
                            #console.log "Crashreport: " + util.inspect(crashreport) #debug

                            # store to mongodb
                            q = crashreports.find({'id':crashreport.id}).upsert().update(crashreport)
                            q.run (err) ->
                                if err?
                                    res.send {"ok":"0","errors":err}
                                    # TODO: cleanup?
                                    return
                                else
                                    res.send {"ok":"1","url":"http://crash-reports.meego.com/id/" + crashreport.id}
                            
exports.init_import_api = init_import_api

