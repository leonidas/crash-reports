#
# This file is part of Meego-QA-Dashboard
#
# Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# version 2.1 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA
#

# Utilities for testing

app      = require('app')
testCase = require('nodeunit').testCase
http     = require('http')
monmon   = require('monmon').monmon

serverdir = __dirname + "/.."

TEST_PORT = 3133

read_all = (res, callback) ->
    data = ""

    res.on "data", (chunk) ->
        data += chunk

    res.on "end", ->
        res.body = data
        callback? res

test_server = (env, tests) ->
    orig_setUp    = tests.setUp
    orig_tearDown = tests.tearDown

    dir = serverdir
    dbm = monmon.env(env)

    get = (url, callback) ->
        opts =
            host: 'localhost'
            port: TEST_PORT
            path: url
            method: 'GET'

        http.get opts, (res) ->
            read_all res, callback

    createApp = (callback) ->
        tests.app = app.create_app dir, dbm
        tests.app.listen TEST_PORT, callback

    closeApp = ->
        tests.app.close()

    tests.setUp = (callback) ->
        @get = get
        createApp (err) ->
            if orig_setUp?
                orig_setUp callback
            else
                callback()

    tests.tearDown = (callback) ->
        closeApp()
        if orig_tearDown?
            orig_tearDown callback
        else
            callback()

    return testCase tests

exports.test_server = test_server
