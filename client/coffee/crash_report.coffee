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


## Module Globals
$p = {}

deepcopy = (obj) ->
    return obj if (typeof obj) != 'object'

    cp = {}
    for k,v of obj
        cp[k] = deepcopy v
    return cp

initialize_application = () ->
    frag = parse_fragment()
    if not frag?
        window.location = "http://" + window.location.host #redirect to index
        #TODO: redirect to search
    else
        console.log "frag=#{frag}" #debug
        clear_crashreport()
        load_crashreport_data frag, (data) ->
            #TODO: add error handling
            if data?.crashdata
                render_crashreport(data.crashdata)

parse_fragment = () ->
    frag = window.location.hash
    if frag?
        frag = frag.substring(1)
        return null if frag == ""
        decodeURIComponent frag

load_crashreport_data = (id, callback) ->
     $.getJSON "/crashreports/#{id}", (data) ->
         callback? data

clear_crashreport = () ->
    #TODO: clear crashreport data from layout

render_crashreport = (data) ->
    #TODO: write crashreport data to layout

$ () ->
    CFInstall?.check()

    $p.overview           = $('#crash_overview')
    $p.version            = $('#crash_version')
    $p.analysis           = $('#analysis')

    $p.related_bugs       = $('#related_bugs')
    $p.related_test_cases = $('#related_test_cases')
    $p.related_crashes    = $('#related_crashes')


    $p.stack_trace        = $('#stack_trace')
    $p.process_state      = $('#process_state')
    $p.system_state       = $('#system_state')

    initialize_application()
