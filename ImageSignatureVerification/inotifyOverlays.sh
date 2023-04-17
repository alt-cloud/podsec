#!/bin/bash

EVENTS="modify,move,create,delete"
TMP="/tmp/inotify_overlays.tmp"
LOGFILE="/var/log/inotify.log"
PATH_TO_OVERLAYS+=( $(find /home -regextype posix-egrep -regex \
    ".*/containers/.*" -type d -name 'diff' 2>/dev/null) )

INFO_LOG="YES"		#if you don't want to log "info" events, \
			#then change "YES" to "NO"

#create file with all rootless overlays
get_overlays () {
if [ "${#PATH_TO_OVERLAYS[@]}" -ne 0 ]; then
    rm -rf $TMP
    for overlay in "${PATH_TO_OVERLAYS[@]}"; do
        echo $overlay >> $TMP
    done
fi
}

#send event to syslog
run_logger () {
    local level
    #choise log level based on edge string in log file
    edge_log_string=$(tail -n1 $LOGFILE)
    if [[ "$edge_log_string" =~ "MODIFY" ]]; then
	level="CRITICAL"
    else
	level="INFO"
    fi
    
    #create event on journal
    if [ "$level" == "INFO" ] && [ "$INFO_LOG" == "YES" ]; then
        logger -t inotify-overlays "$level: $edge_log_string"
    elif [ "$level" == "CRITICAL" ]; then
        logger -t inotify-overlays "$level: $edge_log_string"
    fi
}

#main
get_overlays
if [ -s $TMP ]; then
    touch $LOGFILE
    while inotifywait -q -t 15 --recursive --event $EVENTS --fromfile $TMP \
            --format "File %f was %e in %w" --outfile $LOGFILE; do
        run_logger
    done
fi
