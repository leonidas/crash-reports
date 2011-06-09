
lazy = require('lazy')
temp = require('temp')
fs   = require('fs')
exec = require('child_process').exec


extract_rich_core = (rcorefile, cb) ->
    fn = temp.path(suffix: '.core')
    cmd = "lzop -d #{rcorefile.path} -o#{fn}"
    exec cmd, (err, stdout, stderr) ->
        cb?(err, {path: fn})

parse_rich_core = (rcorefile, cb) ->
    console.log "parsing rich core: #{rcorefile.path}"
    path = rcorefile.path

    if /\.lzo$/.test(path)
        extract_rich_core rcorefile, (err, corefile) ->
            return cb? err if err?
            parse_rich_core corefile, (err, core) ->
               fs.unlink(corefile.path)
               cb?(err, core)
        return

    lines = new lazy(fs.createReadStream path)

    groups = group_lines(lines)

    core = null

    groups.forEach (g) ->
        if not core?
            core =
                cmdline: g.lines[0]
        else
            switch g.name
                when 'date'     then core.date = parse_core_date g.lines[0]
                when 'ls_proc'  then core.ls_proc = g.lines
                when 'fd'       then core.fd = g.lines
                when 'df'       then core.df = g.lines
                when 'ifconfig' then core.ifconfig = g.lines

    groups.on 'end', () ->
        cb? null, core


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