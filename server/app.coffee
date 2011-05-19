
express    = require('express')
http       = require('http')
form       = require('connect-form')
MongoStore = require('connect-mongo')

create_app = (basedir, db) ->

    PUBLIC = basedir + "/public"
    COFFEE = basedir + "/client"

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
            dest: PUBLIC
            enable: ['coffeescript']

        app.use express.cookieParser()
        app.use express.bodyParser()
        app.use express.session {secret: "TODO", store:store}
        app.use express.static PUBLIC

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

    require('import-api').init_import_api basedir, app, db

    app.get "/crashreports/:id", (req, res) ->
        crashreports = db.collection('crashreports')
        crashreports.find({"id":req.params.id}).run (err,arr) ->
            return res.send {"ok":"0","errors": err} if err?
            crashobjs = {}
            for item in arr
                crashobjs[item.id] = item
            return res.send {"ok":"1","crashdata": JSON.stringify(crashobjs)}

    return app

exports.create_app = create_app
