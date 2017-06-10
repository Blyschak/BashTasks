#!/bin/bash

file_counter=0;
PROGRESS_SYMBOL=$'*'
sun_frame=0
sun_counter=0
SUN=('|' '/' '-' '\')
SLEEPTIME=.05
WHAT="$1"
WHERE="$2"
# PID of cp process
CP_PID=


# kill cp process on exit
trap 'kill $(jobs -p)' EXIT

Usage() {

	echo "Usage: $0 SRC DEST"
}

if [[ $# < 2 ]]; then
	Usage
	exit 1
fi

# this function prints directory size

get_dir_size() {

	DIR=$1

	DU_OUTPUT=$(du -scb $DIR 2> /dev/null)
	[ $? -eq 0 ] || { echo "Error during calculating size; check permissions" >&2 ; exit 1; } 
	SIZE=$(echo $DU_OUTPUT | tail -n 1 | awk '{print $1;}')

	echo $SIZE

}

# function that draws a progress line

progress() {

    clear
    
    counter=$1
    all=$2

    ((sun_counter++))
    
    # draw a progress bar at the end of the screen
    tput cup $(tput lines) 0;
    
    # increase file_counter by 1
    # make sun animation; change current frame variable
    sun_frame=$(( $sun_counter/${#SUN[@]} % ${#SUN[@]} ))
    
    complited=$(( ($counter)*$(( $(tput cols) - 25 ))/$all ))
    printf "Copied : %s [" ${SUN[$sun_frame]}
    printf "$PROGRESS_SYMBOL%.0s" $(seq 1 $complited)
    printf " %.0s" $(seq 1 $(( $(tput cols) - 25 - $complited )))
    printf "]"
    
    # print out how much percents are copied
    printf "%3d.%1d%%" $(( $counter*100/$all )) $(( $counter*1000/$all % 10 ))
    
}

if ! [ -d $WHAT ] || ! [ -d $WHERE ]; then
    Usage
    exit 1
fi

echo "Get $WHERE size"
SIZE_0=$(get_dir_size $WHERE) || exit $?
echo "Get $WHAT size"
SIZE_2_CPY=$(get_dir_size $WHAT) || exit $?

if [ -d "$WHERE/$(basename $WHAT)" ]; then
    echo "$(basename $WHAT) exists; Do you want to rewrite it?[y/n]"
    read

    case "$REPLY" in
        "y")
			echo "Deleting $(basename $WHAT)"
			rm -rf "$WHERE/$(basename $WHAT)"
            cp -r $WHAT $WHERE > /dev/null 2>&1 &

            # update size
            SIZE_0=$(get_dir_size $WHERE)

            ;;
        "n"|*) 
			cp -r -u $WHAT $WHERE > /dev/null 2>&1 &
            ;;
    esac
else
	cp -r $WHAT $WHERE > /dev/null 2>&1 &
fi

CP_PID=$!


clear

while kill -0 "$CP_PID" > /dev/null 2>&1; do
    CURR_SIZE=$(get_dir_size $WHERE) || exit $?
    progress $(( $CURR_SIZE-$SIZE_0 )) $SIZE_2_CPY
    sleep $SLEEPTIME
done

# wait for cp to finish its job
wait "$CP_PID"
# the exit code now would be the exit code of cp

if [[ $? == 0 ]]; then
    # if cp return 0 then copying was successfull
    # becouse of unused space for inodes in directories
    # and sparse files, the SRC and DEST almost always
    # will differ by size
    # so we just print 100 % completed assuming that everything
    # was copied becouse cp returned 0
    progress $SIZE_2_CPY $SIZE_2_CPY
    echo
    echo "Copied $(( $(get_dir_size $WHERE) - $SIZE_0)) bytes"
else
	echo
    # if not then print error message to stderr
    >&2 echo "Error occured in cp: exit code - $?"
fi