express    = require('express')
http       = require('http')
form       = require('connect-form')
stylus      = require('stylus')
MongoStore = require('connect-mongo')
_          = require('underscore')

create_app = (settings, db) ->
    basedir = settings.app.root

    PUBLIC  = basedir + "/public"
    COFFEE  = basedir + "/client/coffee"
    STYLUS  = basedir + "/client/stylus"

    FORM_OPTIONS =
            keepExtensions : true
            uploadDir : basedir + "/tmp" #minimum global option (default is root tmp "/tmp")
            maxFieldsSize : 100 * 1024 * 1024
            encoding : "utf-8"

    app = express.createServer(form(FORM_OPTIONS))

    store = new MongoStore(db:db.cfg.dbname)

    app.configure ->
        app.use express.compiler
            src: COFFEE
            dest: PUBLIC + '/js'
            enable: ['coffeescript']

        app.use stylus.middleware {
            debug: true
            src: STYLUS
            dest: PUBLIC
        }

        app.use express.cookieParser()
        app.use express.bodyParser()
        app.use express.session {secret: "TODO", store:store}
        app.use express.static PUBLIC
        app.use express.static PUBLIC + '/js'

    app.configure "development", ->
        app.use express.logger()
        app.use express.errorHandler
            dumpExceptions: true
            showStack: true

    app.configure "staging", ->
        app.use express.logger()
        app.use express.errorHandler
            dumpExceptions: true
            showStack: true

    app.configure "production", ->
        app.use express.logger()
        app.use express.errorHandler()

    require('import-api').init_import_api settings, app, db


    #TODO: move to own module
    app.get "/crashreports/:id", (req, res) ->
        id = req.params.id
        crashreports = db.collection('crashreports')
        crashreports.find({"id":id}).run (err,arr) ->
            return res.send {"ok":"0","errors": err} if err?
            return res.send {"ok":"0","errors": "ERROR: Crashreport not found with id:#{id}"} if arr.length == 0
            if arr.length == 1
                return res.send {"ok":"1","crashdata": arr[0]}
            else
                return res.send {"ok":"0","errors": "ERROR: Found multiple crashlogs with id:#{id}"}


    app.get "/", (req, res) ->

        crashreports = db.collection('crashreports')
        crashreports.find().run (err,arr) ->
            return res.send {"ok":"0","errors": err} if err?

            body = "Crashreports index:<br>"
            _.each arr, (item) ->
                linkurl  = "#{settings.server.url}/crashreports/#{item.id}"
                linktext = "#{item.product} #{item.files['rich-core'].origname}"
                body    += "<a href=\"#{linkurl}\">#{linktext}</a><br>"

            res.writeHead 200,
              'Content-Length': body.length,
              'Content-Type': 'text/html'
            return res.end body

    return app

exports.create_app = create_app
