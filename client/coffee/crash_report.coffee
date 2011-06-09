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


redirect_to_index = () ->
    window.location = "http://" + window.location.host #redirect to index

initialize_application = () ->
    frag = parse_fragment()
    if not frag?
        #TODO: redirect to search
        redirect_to_index()
    else
        #console.log "frag=#{frag}" #debug
        clear_crashreport()
        load_crashreport_data frag, (data) ->
            #TODO: add error handling
            if data?.crashdata
                render_crashreport(data.crashdata)
            else
                redirect_to_index()

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

render_crashreport = (crashreport) ->
    #Overview
    write_link '#overview_application', crashreport["rich-core"].cmdline.replace(/.*\//,''), "/"
    write_link '#overview_executable' , crashreport["rich-core"].cmdline, ""

    crashdate = new Date(crashreport["rich-core"].date)
    #$('#overview_date').text new Date(crashreport["rich-core"].date)
    $('#overview_date').text crashdate.toUTCString()
    $('#overview_upload_notes').text "-"
    $('#overview_core_notes').text "-"

    #Version
    $('#version_component').text "product #{crashreport.product} version: #{crashreport.release}"
    write_link '#version_build',crashreport.build,""
    write_link '#version_product',crashreport.product,""
    write_link '#version_week',"",""

    #Analysis
    $('#app_similar_crashes_num').text "-"
    $('#all_similar_crashes_num').text "-"

    #Download links
    host_url  = "http://#{window.location.host}/"
    core_url  = crashreport.files.core.path.replace(/^.*\/public\//,host_url)
    rcore_url = crashreport.files["rich-core"].path.replace(/^.*\/public\//,host_url)
    stack_url = crashreport.files["stack-trace"].path.replace(/^.*\/public\//,host_url)
    $('#download_core_btn').attr "href", core_url
    $('#download_rcore_btn').attr "href", rcore_url
    $('#download_stack_trace').attr "href", stack_url

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
