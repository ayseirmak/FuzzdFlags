#!/bin/bash
# Function to kill script and its child processes
kill_script() {
    local parent_pid=$1

    # Get all child processes of the parent PID
    child_pids=$(pgrep -P $parent_pid)

    # Kill the parent and all its children
    pkill -TERM -P $parent_pid

    # Wait for processes to be killed
    sleep 5

    # Forcefully kill any remaining processes
    pkill -KILL -P $parent_pid
}

input=$1
output=$2
round=$3
configuration=$4
target=$5 # clang or clang-options

# input folder, output folder, AFL can be fixed
./run_AFL_conf_$3.sh $input $output-$configuration-$round 0 $target > afl-$configuration-$round.txt 2>&1 &

# Capture the process ID of the background process
script_pid=$!

# Sleep for 24 hours
sleep 600

# Kill the script after 60 minutes
kill_script $script_pid
