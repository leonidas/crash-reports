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

# Asynchroniously promised value

EventEmitter = require('events').EventEmitter
async = require('async')

class Promise
    constructor: ->
        @event = new EventEmitter()

    get: (callback) ->
        if @err? or @value?
            process.nextTick =>
                callback @err, @value
            return

        @event.once "fulfil", =>
            callback null, @value

        @event.once "error", =>
            callback @err, null

    fulfil: (value) ->
        throw "promise value already set" if @err? or @value?

        @value = value
        @event.emit "fulfil"

    error: (msg) ->
        throw "promise value already set" if @err? or @value?

        @err = msg
        @event.emit "error"

exports.Promise = Promise
