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

fetch_all_similar_crashes = (id, cb) ->
    $.getJSON "/similarcrashes/#{id}", (result) ->
        cb? result

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

parse_ls_list = (ls_list) ->
    ls_list = _(ls_list).map (line) ->
        return line if !line.match /^[dlrwx-]{10}\s/
        arr = line.split /\s/
        arr[arr.length-1] = "<strong>#{arr[arr.length-1]}</strong>"
        arr.join ' '
    return ls_list.join('\n')

render_process_state = (crashreport) ->

    if crashreport["rich-core"]["cmdline"]
        cmdline = crashreport["rich-core"]["cmdline"]
        $('#cmdline_content pre').html cmdline
    if crashreport["rich-core"].ls_proc?
        ls_proc = parse_ls_list crashreport["rich-core"].ls_proc
        $('#ls_proc_content pre').html ls_proc
        #console.log ls_proc
    if crashreport["rich-core"].fd?
        fd = parse_ls_list crashreport["rich-core"].fd
        $('#fd_content pre').html fd

parse_ifconfig_list = (ifconfig_list) ->
    network_re = /^([^ ]+\s+).*$/
    next_is_network = true
    indent = ""
    ifconfig_list = _.map ifconfig_list, (line) ->
        if line.length == 0
            next_is_network = true
        else
            if next_is_network
                next_is_network = false
                match = network_re.exec(line)
                if match
                    indent = match[1].replace /./g, ' '
            else
                return indent + line
        return line
    return ifconfig_list.join('\n')

render_system_state = (crashreport) ->

    if crashreport["rich-core"].df?
        df = crashreport["rich-core"].df.join('\n')
        $('#df_content pre').html df

    if crashreport["rich-core"].ifconfig?
        ifconfig = parse_ifconfig_list crashreport["rich-core"].ifconfig
        $('#ifconfig_content pre').html ifconfig

    if crashreport["rich-core"].packagelist?
        packagelist = crashreport["rich-core"].packagelist.join('\n')
        $('#packagelist_content pre').html packagelist

render_registers = (crashreport) ->
    table = $('#register_table')
    row_template = table.find('tr:last')
    row_template.detach()
    i = 0
    for name, values of crashreport["stack-trace"]["registers"]
        hex = values["hex"]
        dec = values["dec"]
        row = row_template.clone()
        table.append row
        row.find('.register_name').text name
        row.find('.register_hex').text hex
        row.find('.register_dec').text dec
        row.addClass if ++i % 2 == 0 then "even" else "odd"

render_stacktrace = (stack_name, pid, crash_reason, stack_data) ->

    regexp = /^#(\d+)\s+((0x[\da-fA-F]+)\s+in)?\s+(([^ \(]+)(\([^\)]*\))?)\s+(\([^\)]*\))(\s+(at|from)\s+([^ ]+).*)?$/
    #           ^^^^^    ^^^^^^^^^^^^^^^           ^^^^^^^^^^^^^^^^^^^^^     ^^^^^^^^^^^^    ^^^^^^^^^   ^^^^^^^
    #           frame    address                   func     args             context         isLib       location

    stack = $('.stack_trace:first').clone()
    $('#stack_traces').append(stack)

    stack.find('.stack_name').text stack_name
    if pid
        stack.find('.stack_pid_content').text pid
    else
        stack.find('.stack_pid').detach()
    if crash_reason
        stack.find('.crash_reason_content').text crash_reason
    else
        stack.find('.crash_reason').detach()

    table = stack.find('.stack_trace_table')
    header = table.find('tr:first')
    row_template = table.find('.stack_trace_row')
    info_row_template = table.find('.stack_trace_info_row')
    table.empty()
    table.append header
    i = 0
    for line in stack_data
        match = regexp.exec(line)
        if not match
            row = info_row_template.clone()
            row.find('.stack_trace_info').text line
        else
            [_, frameNr, _, address, _, func, args, context, _, isLib, location] = match

            row = row_template.clone()
            row.find('.stack_trace_frame').text("#" + frameNr)
            row.find('.stack_trace_address').text if address then address else "<unknown>"
            row.find('.stack_trace_function').text func + " " + if args then args else ""
            row.find('.stack_trace_context').text context
            row.find('.stack_trace_location').text if location then location else ""
            row.addClass if ++i % 2 == 0 then "even" else "odd"
        table.append(row)

render_crashreport = (crashreport) ->
    #Overview
    application = crashreport["rich-core"].cmdline.replace(/\s+.*$/,'').replace(/^.*\//,'')
    write_link '#overview_application', application, window.location.href
    write_link '#overview_executable' , crashreport["rich-core"].cmdline, window.location.href

    crashdate = new Date(crashreport["rich-core"].date)
    #$('#overview_date').text new Date(crashreport["rich-core"].date)
    $('#overview_date').text crashdate.toUTCString()
    $('#overview_upload_notes').text "-"
    $('#overview_core_notes').text "-"

    #Version
    $('#version_component').text "product #{crashreport.product} version: #{crashreport.release}"
    write_link '#version_build',crashreport.build, window.location.href
    write_link '#version_product',crashreport.product, window.location.href
    write_link '#version_week',"", window.location.href

    #Analysis
    $('#app_similar_crashes_num').text "-"
    $('#all_similar_crashes_num').text "-"
    fetch_all_similar_crashes crashreport.id, (result) ->
        console.log result
        console.log result.data.length
        if result?.data
            $('#all_similar_crashes_num').text result.data.length

    # Related Bugs
    $('#related_bugs .tab1').empty()
    $('#related_bugs .tab1').text '-'

    # Related Test Cases
    $('#related_test_cases ul').empty()
    $('#related_test_cases ul').text '-'

    # Related Crashes
    $('#related_crashes .tab1').empty()
    $('#related_crashes .tab1').text '-'

    #Download links
    host_url  = "http://#{window.location.host}/"
    core_url  = crashreport.files.core.path.replace(/^.*\/public\//,host_url)
    rcore_url = crashreport.files["rich-core"].path.replace(/^.*\/public\//,host_url)
    stack_url = crashreport.files["stack-trace"].path.replace(/^.*\/public\//,host_url)
    $('#download_core_btn').attr "href", core_url
    $('#download_rcore_btn').attr "href", rcore_url
    $('#download_stack_trace').attr "href", stack_url

    #Stack
    render_registers crashreport
    render_stacktrace "Crash Stack", null, crashreport["stack-trace"]["crash_reason"], crashreport["stack-trace"]["crashstack"]
    for name, thread of crashreport["stack-trace"]["threads"]
        render_stacktrace name, thread["pid"], null, thread["stack"]
    $('.stack_trace:first').detach()

    #Process state
    render_process_state crashreport

    #System state
    render_system_state crashreport

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
