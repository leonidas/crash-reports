fs    = require('fs')
lazy  = require("lazy")


parse_stack_trace_file = (filepath, cb) ->
    console.log "parsing stack trace:#{filepath}" #debug
    stack_trace =
        "registers"  : {}
        "crashstack" : []
        "threads"    : {}

    curr_thread  = {}
    parse_state  = "initial"

    lazy_parser  = new lazy(fs.createReadStream(filepath))

    lazy_parser.on 'end', () ->
        cb null, stack_trace

    lazy_parser.lines
               .forEach (line_obj) ->
                    line = line_obj.toString()

                    # states: initial -> crashstack -> next+ -> (stack+ -> next+)+ -> registers -> end
                    switch parse_state
                        when "initial"
                          stack_trace.crash_reason = line #assumes first line is crash reason
                          parse_state = "crashstack"
                        when "crashstack"
                            # end of stack?
                            if line.match /^\s*$/
                                parse_state = "next"
                            # stack items
                            else
                                stack_trace.crashstack.push line
                        when "next"
                            # registers?
                            if line.match /^Registers\:/
                                parse_state = "registers"
                            # stack trace?
                            else if line.match /^(Thread\s\d+)\s+\(\w+\s(\d+)\)/
                                curr_thread = stack_trace.threads[RegExp.$1] =
                                    "pid"   : RegExp.$2
                                    "stack" : []
                                parse_state = "stack"
                        when "stack"
                            # end of stack?
                            if line.match /^\s*$/
                                curr_thread = {}
                                parse_state = "next"
                            # stack items
                            else
                                curr_thread.stack.push line
                        when "registers"
                            # register value?
                            if line.match /^(\w+)\s+([0-9A-Fa-fx]+)\s+(\d+)$/ # e.g. "r7 0xa8 168"
                                stack_trace.registers[RegExp.$1] =
                                    "hex": RegExp.$2
                                    "dec": RegExp.$3
                            # end, ignore rest of the file
                            else
                                parse_state = "end"

exports.parse_stack_trace_file = parse_stack_trace_file
