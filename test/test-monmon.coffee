# Test monmon API

require.paths.unshift __dirname + '/../node_modules'
require.paths.push(__dirname + "/../server")

async = require('async')
_     = require('underscore')

testCase = require('nodeunit').testCase

mm = require('monmon').monmon

exports["environments are separate"] = (test) ->
    test.expect(7)

    db1 = mm.env("test1").use("test-monmon").collection("test")
    db2 = mm.env("test2").use("test-monmon").collection("test")

    db1.dropDatabase().run (err) ->
        db2.dropDatabase().run (err) ->
            db1.insert({foo:"bar"}).run (err) ->
                test1 = (cb) ->
                    q = db1.find({foo:"bar"}).do (err, arr) ->
                            test.equal err, null
                            if arr?
                                test.strictEqual arr.length, 1
                                test.strictEqual arr[0].foo, "bar"
                    q.run (err) ->
                        test.equal err, null
                        cb()        

                test2 = (cb) ->
                    q = db2.find({foo:"bar"}).do (err, arr) ->
                            test.equal err, null
                            if arr?
                                test.strictEqual arr.length, 0
                    q.run (err) ->
                        test.equal err, null
                        cb()        

                async.parallel [test1, test2], ->
                    test.done()

exports["multiple queued commands work correctly"] = (test) ->
    test.expect(3)

    db = mm.env("test").use("test-monmon").collection("test")
    
    q = db.dropDatabase()
          .insert({foo:"bar"})
          .insert({foo:"asdf"})
          .find().do (err, arr) ->
              test.equal err, null
              test.equal arr.length, 2

    q.run (err, arr) ->
        test.equal err, null
        test.done()

exports["run callback can catch the result of last action"] = (test) ->
    test.expect(2)

    db = mm.env("test").use("test-monmon").collection("test")
    
    q = db.dropDatabase()
          .insert({foo:"bar"})
          .insert({foo:"asdf"})
          .find()

    q.run (err, arr) ->
        test.equal err, null
        test.equal arr.length, 2
        test.done()

TEST_DOCS = [
    {city: "Tampere",  population: 213344, region:"Pirkanmaa",   area:689.59},
    {city: "Nokia",    population: 31658,  region:"Pirkanmaa",   area:347.78},
    {city: "Orivesi",  population: 9618,   region:"Pirkanmaa",   area:960.08},
    {city: "Helsinki", population: 588941, region:"Uusimaa",     area:715.49},
    {city: "Vantaa",   population: 200410, region:"Uusimaa",     area:240.34},
    {city: "Kotka",    population: 54845,  region:"Kymenlaakso", area:949.74}
]

exports["basic features"] = testCase
    setUp: (callback) ->
        @db = mm.env("test").use("test-monmon").collection("test")
        @db.dropDatabase().insertAll(TEST_DOCS).run(callback)

    "test count all": (test) ->
        test.expect(2)
        q = @db.count()
        q.run (err, num) ->
            test.equal err, null
            test.equal num, 6
            test.done()

    "test count with query": (test) ->
        test.expect(2)
        q = @db.find({region:"Pirkanmaa"}).count()
        q.run (err, num) ->
            test.equal err, null
            test.equal num, 3
            test.done()

    "test distinct": (test) ->
        test.expect(5)
        q = @db.distinct "region"
        q.run (err, arr) ->
            test.equal err, null
            arr = _(arr)
            test.ok arr.include "Pirkanmaa"
            test.ok arr.include "Uusimaa"
            test.ok arr.include "Kymenlaakso"
            test.equal arr.size(), 3
            test.done()

    "test distinct with query": (test) ->
        test.expect(4)
        q = @db.find({population: {$gt: 100000}}).distinct "region"
        q.run (err, arr) ->
            test.equal err, null
            arr = _(arr)
            test.ok arr.include "Pirkanmaa"
            test.ok arr.include "Uusimaa"
            test.equal arr.size(), 2
            test.done()

    "test update": (test) ->
        test.expect(4)
        new_doc = 
            city: "Tampere"
            population: 250000
            region:"Pirkanmaa"
            area:689.59

        db = @db
        q = db.find({city:"Tampere"}).safe().update new_doc
        q.run (err) ->
            test.equal err, null

            q = db.find({city:"Tampere"}).run (err, arr) ->
                test.equal err, null
                test.equal arr.length, 1
                test.equal arr[0].population, 250000
                test.done()

    "test upsert update": (test) ->
        test.expect(4)
        new_doc = 
            city: "Tampere"
            population: 250000
            region:"Pirkanmaa"
            area:689.59

        db = @db
        q = db.find({city:"Tampere"}).upsert().update new_doc
        q.run (err) ->
            test.equal err, null

            q = db.find({city:"Tampere"}).run (err, arr) ->
                test.equal err, null
                test.equal arr.length, 1
                test.equal arr[0].population, 250000
                test.done()

    "test upsert insert": (test) ->
        test.expect(4)
        new_doc = 
            city: "Ikaalinen"
            population: 7422
            region:"Pirkanmaa"
            area:843.46

        db = @db
        q = db.find({city:"Ikaalinen"}).upsert().update new_doc
        q.run (err) ->
            test.equal err, null

            q = db.find({city:"Ikaalinen"}).run (err, arr) ->
                test.equal err, null
                test.equal arr.length, 1
                test.equal arr[0].population, 7422
                test.done()

    "test remove": (test) ->
        test.expect(2)
        db = @db
        q = db.find({area:{$lt:400}}).remove()
        q.run (err) ->
            test.equal err, null
            q = db.count().run (err, num) ->
                test.equal num, 4
                test.done()
