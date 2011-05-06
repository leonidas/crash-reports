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

# Asynchronous Future Value

EventEmitter = require('events').EventEmitter
async = require('async')

class Future
    constructor: () ->
        @event = new EventEmitter()
        @callback = (error, value) =>
            throw "Future callback already called" if @error? or @value?
            @error = error
            @value = value
            @event.emit "ready"

    get: (callback) ->
        if @error? or @value?
            async.nextTick =>
               callback @error, @value 
            return

        @event.once "ready", =>
            callback @error, @value

call = (func) ->
    Array::unshift.call arguments, null
    callThis.apply null, arguments

callThis = (ths, func) ->
    args = Array::slice.call arguments, 2
    fut = new Future()
    args.push fut.callback
    func.apply(null, args)
    return fut

exports.Future   = Future
exports.call     = call
exports.callThis = callThis
    