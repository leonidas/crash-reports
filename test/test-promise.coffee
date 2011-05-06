# Unit Tests for Promises

require.paths.unshift __dirname + '/../node_modules'
require.paths.push(__dirname + "/../server")

testCase = require('nodeunit').testCase

exports["promise module can be imported"] = (test) ->
    test.expect(2)

    promise = require('promise')
    test.ok promise?, "module was undefined or null"

    Promise = promise.Promise
    test.ok Promise?, "Promise class was not found in module"

    test.done()

exports["get promised value"] = (test) ->
    test.expect(2)

    Promise = require('promise').Promise

    p = new Promise()

    p.get (error, value) ->
        test.equal error, null
        test.strictEqual value, "promised value"
        test.done()

    setTimeout (-> p.fulfil "promised value" ), 0

exports["signal error instead of promised value"] = (test) ->
    test.expect(1)

    Promise = require('promise').Promise

    p = new Promise()

    p.get (error, value) ->
        test.strictEqual error, "some error"
        test.done()

    setTimeout (-> p.error "some error" ), 0
