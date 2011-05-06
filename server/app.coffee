
express = require('express')
http    = require('http')

MongoStore = require('connect-mongo')

create_app = (basedir, db) ->

    PUBLIC = basedir + "/public"
    COFFEE = basedir + "/client"

    app = express.createServer()

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

    return app

exports.create_app = create_app
