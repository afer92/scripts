#!/bin/bash

PORT=22
USER=""
LOGIN=""

CONNECT=0

## # Wait only 50msec for response:
## MAX_TIME_MS=50

FILT_MAX_TIME_MS=2000
DEF_MAX_TIME_MS=500

MAX_TIME_MS=$DEF_MAX_TIME_MS
MAX_TIME="--initial-rtt-timeout ${MAX_TIME_MS}ms"

SLEEP=10

################################################################################
## Functions:

die() {
    echo "$0: die - $*" >&2
    exit 253
}

setLOGIN() {
    LOGIN=$HOST
    [ ! -z "$USER" ] && LOGIN=${USER}@${HOST}
}

get_port_status() {
    #echo nmap $MAX_TIME $HOST -p $PORT -Pn >&2

    if [ -d /cygdrive ]; then
        # Running under Windows/Cygwin:
        which nc >/dev/null 2>&1 || die "No nc in PATH"
        CMD="nc -w 1 $HOST $PORT"
        #echo $CMD >&2
        $CMD 2>/dev/null
        [ $? -eq 0 ] && echo "open"
    else
        which nmap >/dev/null 2>&1 || die "No nmap in PATH"
        nmap $MAX_TIME $HOST -p $PORT -Pn | grep "^${PORT}/tcp " | awk '{print $2;}'
    fi
}

################################################################################
## TIMER Functions:

start_timer() {
    START_S=`date +%s`
}

stop_timer() {
    END_S=`date +%s`
    let TOOK=END_S-START_S

    hhmmss $TOOK
    echo "Took $LOOP loops/$TOOK secs [${HRS}h${MINS}m${SECS}]"

}

hhmmss() {
    _REM_SECS=$1; shift

    let SECS=_REM_SECS%60

    let _REM_SECS=_REM_SECS-SECS

    let MINS=_REM_SECS/60%60

    let _REM_SECS=_REM_SECS-60*MINS

    let HRS=_REM_SECS/3600

    [ $SECS -lt 10 ] && SECS="0$SECS"
    [ $MINS -lt 10 ] && MINS="0$MINS"
}


################################################################################
## Args:
LOOPS=0

HOST=""
COMMAND=""

while [ ! -z "$1" ]; do
    case "$1" in
        -1) LOOPS=1;;
        -L) shift; LOOPS=$1;;

        -l) shift; USER=$1; setLOGIN;;
        -ssh) CONNECT=1;;

        -x) set -x;;
        +x) set +x;;

        -s) shift; SLEEP="$1";;

        -p) shift; PORT="$1";;

        *)
            if [ -z "$HOST" ];then
                HOST=$1
                setLOGIN
            else
                COMMAND=$*
                CONNECT=1
                set --
            fi
            # die "Unknown option <$1>: $0 -h <\$HOST> [-p <\$PORT>] - missing argument";;
    esac
    shift
done

################################################################################
## Main:

[ -z "$HOST" ] && die "No host specified"

#HOST=${HOST# *}
echo "Checking <$LOGIN:$PORT> every $SLEEP secs"

start_timer

let LOOP=0

while true; do
    let LOOP=LOOP+1

    #LABEL="${LOOP}: $(date +%y-%b-%d_%Hh%Mm%Ss)"
    LABEL="${LOOP}: $(date +%Hh%Mm%Ss)"

    for HOST in $HOST; do
        #nmap $HOST -p $PORT | grep "^${PORT}/tcp *open"

	port_status=$( get_port_status 2>&1 )
        [ $? -eq 253 ] && die "Died"
	#echo $port_status
	case "$port_status" in
            SSH*|open)
                echo "$LABEL <$LOGIN:$PORT> open"
                stop_timer
                setLOGIN
                [ $CONNECT -ne 0 ] && exec ssh -p $PORT $LOGIN $COMMAND
                exit 0;;
            closed)
                echo "$LABEL <$LOGIN:$PORT> closed";;
	    filtered)
		echo "$LABEL <$LOGIN:$PORT> filtered (try increasing ...  \$MAX_TIME_MS)";
                MAX_TIME_MS=$FILT_MAX_TIME_MS
		;;
            *)
                echo "$LABEL <$LOGIN:$PORT> unrecognized state <$port_status>";
                MAX_TIME_MS=$FILT_MAX_TIME_MS
		;;
        esac
	 
    done

    echo "sleep $SLEEP"
    sleep $SLEEP

    [ $LOOP -eq $LOOPS ] && exit
done


stop_timer


