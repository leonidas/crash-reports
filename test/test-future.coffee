# Unit Tests for Future

require.paths.unshift __dirname + '/../node_modules'
require.paths.push(__dirname + "/../server")

async = require('async')

testCase = require('nodeunit').testCase

exports["future module can be imported"] = (test) ->
    test.expect(2)

    future = require('future')
    test.ok future?, "module was undefined or null"

    Future = future.Future
    test.ok Future?, "Future class was not found in module"

    test.done()


exports["value is propagated from future"] = (test) ->
    test.expect(2)
    Future = require('future').Future

    fu = new Future()
    async_func = (callback) ->
        callback null, "foobar"

    setTimeout (-> async_func fu.callback), 0

    fu.get (err,value) ->
        test.strictEqual value, "foobar"
        test.equal err, null
        test.done()

exports["error is propagated from future"] = (test) ->
    test.expect(2)
    Future = require('future').Future

    fu = new Future()
    async_func = (callback) ->
        callback "error", null

    setTimeout (-> async_func fu.callback), 0

    fu.get (err, value) ->
        test.equal value, null
        test.strictEqual err, "error"
        test.done()

exports["value can be requested several times"] = (test) ->
    test.expect(4)
    Future = require('future').Future

    fu = new Future()
    async_func = (callback) ->
        callback null, "foobar"

    setTimeout (-> async_func fu.callback), 0

    async.parallel [
        ((cb) -> fu.get (err,value) ->
            test.strictEqual value, "foobar"
            test.equal err, null
            cb() ),

        ((cb) -> fu.get (err,value) ->
            test.strictEqual value, "foobar"
            test.equal err, null
            cb() )
    ], (-> test.done())
    
exports["throws exception if callback is called multiple times"] = (test) ->
    test.expect(1)
    Future = require('future').Future

    fu = new Future()

    async_func = (callback) ->
        callback null, "foobar"

    setTimeout (-> async_func fu.callback), 0
    setTimeout (-> async_func fu.callback), 0

    process.once 'uncaughtException', (err) ->
        test.strictEqual err, "Future callback already called"
        test.done()

exports["call shortcut"] = (test) ->
    test.expect(1)
    future = require('future')

    async_func = (a, b, callback) ->
        process.nextTick(-> callback null, a+b)

    fu = future.call(async_func, 1, 2)
    fu.get (err,value) ->
        test.strictEqual value, 3
        test.done()
