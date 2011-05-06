
require.paths.unshift __dirname + '/../node_modules'
require.paths.push(__dirname + "/../server")

async = require('async')
_     = require('underscore')

testCase = require('nodeunit').testCase

test_server = require('testutil').test_server

exports["http tests"] = test_server "test-http"
    "index page works": (test) ->
        test.expect(1)

        @get "/", (res) ->
            test.equal res.statusCode, 200
            test.done()
