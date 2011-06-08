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

initialize_application = () ->
    frag = parse_fragment()
    if not frag?
        window.location = "http://" + window.location.host #redirect to index
        #TODO: redirect to search
    else
        #console.log "frag=#{frag}" #debug
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

write_link = (dom, text, link) ->
    $dom = $(dom).find('a')
    #TODO: add link tag if not exist
    $dom.text text
    $dom.attr "href", link

render_crashreport = (data) ->
    #Overview
    write_link '#overview_application', "NA", ""
    write_link '#overview_executable' , "NA", ""
    write_link '#overview_application', "NA", ""

    $('#overview_date').text "NA"
    $('#overview_upload_notes').text "-"
    $('#overview_core_notes').text "-"

    #Version
    write_link '#version_build'  ,data.build  ,""
    write_link '#version_product',data.product,""
    write_link '#version_week'   ,""          ,""


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
