
lazy = require('lazy')
temp = require('temp')
fs   = require('fs')
exec = require('child_process').exec


extract_rich_core = (filepath, cb) ->
    fn = temp.path(suffix: '.rcore')
    cmd = "lzop -d #{filepath} -o#{fn}"
    exec cmd, (err, stdout, stderr) ->
        cb?(err, fn)

parse_rich_core = (filepath, cb) ->
    console.log "parsing rich core: #{filepath}"

    if /\.lzo$/.test(filepath)
        extract_rich_core filepath, (err, tempfilepath) ->
            return cb? err if err?
            parse_rich_core tempfilepath, (err, rcore) ->
               fs.unlink(tempfilepath)
               cb?(err, rcore)
        return

    lines = new lazy(fs.createReadStream filepath)

    groups = group_lines(lines)

    rcore = null

    groups.forEach (g) ->
        if not rcore?
            rcore =
                cmdline: g.lines[0]
        else
            switch g.name
                when 'date'     then rcore.date = parse_core_date g.lines[0]
                when 'ls_proc'  then rcore.ls_proc = g.lines
                when 'fd'       then rcore.fd = g.lines
                when 'df'       then rcore.df = g.lines
                when 'ifconfig' then rcore.ifconfig = g.lines

    groups.on 'end', () ->
        cb? null, rcore


date_regexp = /(\w+)\s+(\w+)\s+(\d+)\s+([0-9:]+)\s+([A-Z]+)\s+(\d+)/
parse_core_date = (d) ->
    match = date_regexp.exec(d)
    [_, weekday, month, day, time, timezone, year] = match
    return new Date("#{weekday} #{month} #{day} #{year} #{time} (#{timezone})")


group_lines = (lz) ->
    parser = new lazy()

    group = null

    header = /\[---rich-core\: (.*)---\]/

    lz.lines.forEach (x) ->
        x = x.toString().trim()
        match = header.exec(x)
        if match?
            name = match[1]
            if group?
                parser.emit('data', group)
            group =
                name: name
                lines: []
        else
            group.lines.push(x) if group?

    lz.on 'end', () ->
        parser.end()

    return parser

exports.parse_rich_core = parse_rich_core