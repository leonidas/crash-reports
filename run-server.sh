#!/bin/sh
coffee="node_modules/coffee-script/bin/coffee"
supervisor="node_modules/supervisor/lib/cli-wrapper.js"
forever="node_modules/forever/bin/forever"
app="server.coffee"

run_cmd=$supervisor" -w server.coffee,server -x "$coffee" "$app

usage=$0" <options>\n
Default:\n
\tRun server with node-supervisor (development mode)\n
Options:\n
\t--forever start\tRun continuously and automatically restart (daemonize).\n
\t--forever stop\tStop daemonized process\n"

if [ $# -eq 0 ]; then
	$run_cmd
elif [ $# -eq 2 ] && [ "$1" = "--forever" ]; then
	run_cmd=$forever" "$2" "$coffee" "$app
	$run_cmd
else
	echo $usage
fi
