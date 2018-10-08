#!/bin/bash
input="example-tunnels.csv"

# Setup global vars
headerPrinted=false
foundTunnel=false

# Make sure the script exits cleanly in failure
set -e

# Prints out how to use the tool
function usage {
	echo 'Usage: [command] [name]'
	echo '    1: The command to perform on the tunnel (eg. start/stop/restart/status)'
	echo '    2: (Optional) The name of the tunnel (eg. tunnel-name) or leave empty for all'
	exit 0
}

# Parse options for help (-h)
while getopts ':h' opt; do
	case ${opt} in
		h)
			usage
			;;
		\?)
			echo "Invalid Option: -$OPTARG" 1>&2
			exit 1
			;;
  esac
done

# Check the subcommand is valid
subcommand=$1
case "$subcommand" in
	start)
		command='start'
		;;
	stop)
		command='stop'
		;;
	restart)
		command='restart'
		;;
	status)
		command='status'
		;;
	*)
		echo 'Command not found: $subcommand'
		usage
		exit 1
esac

# Checks if a tunnel is currently running
function isTunnelRunning {
	local processCount="$(ps -ef | grep ${1}:${2}:${3} | grep -v grep | awk '{print $2}' | wc -l)"
	if [ "$processCount" -gt 1 ]; then
		echo 'true'
	else
		echo 'false'
	fi
}

# Prints the table header
function printHeader {
	headerPrinted=true
	printf "%-25s \e[95m|\e[39m %-30s \e[95m|\e[39m %-15s \e[95m|\e[39m %-15s \e[95m|\e[39m %-15s \e[95m|\e[39m %-25s \e[95m|\e[39m %-7s" 'Tunnel Name' 'Tags' 'IP' 'Local Port' 'Remote Port' 'Bastion' 'Status'
	printf "\n\e[95m--------------------------+--------------------------------+-----------------+-----------------+-----------------+---------------------------+----------\e[39m\n"
}

# Pretty prints a row in the table
function prettyPrint {
	# Print table header if it's not there
	if [ "$headerPrinted" = 'false' ]; then
		printHeader
	fi

	# Check the status of the tunnel and colour the status text accordingly
	if [ $7 = "Up" ]; then
		printf "%-25s \e[95m|\e[39m %-30s \e[95m|\e[39m %-15s \e[95m|\e[39m %-15s \e[95m|\e[39m %-15s \e[95m|\e[39m %-25s \e[95m|\e[39m \e[92m%-7s\e[39m" "$1" "$2" "$3" "$4" "$5" "$6" "$7"
	elif [ $7 = "Down" ]; then
		printf "%-25s \e[95m|\e[39m %-30s \e[95m|\e[39m %-15s \e[95m|\e[39m %-15s \e[95m|\e[39m %-15s \e[95m|\e[39m %-25s \e[95m|\e[39m \e[91m%-7s\e[39m" "$1" "$2" "$3" "$4" "$5" "$6" "$7"
	elif [ $7 = "Starting" ] || [ $7 = "Restarting" ] || [ $7 = "Stopping" ]; then
		printf "%-25s \e[95m|\e[39m %-30s \e[95m|\e[39m %-15s \e[95m|\e[39m %-15s \e[95m|\e[39m %-15s \e[95m|\e[39m %-25s \e[95m|\e[39m \e[93m%-7s\e[39m" "$1" "$2" "$3" "$4" "$5" "$6" "$7"
	else
		printf "%-25s \e[95m|\e[39m %-30s \e[95m|\e[39m %-15s \e[95m|\e[39m %-15s \e[95m|\e[39m %-15s \e[95m|\e[39m %-25s \e[95m|\e[39m \e[93m%-7s\e[39m" "$1" "$2" "$3" "$4" "$5" "$6" "$7"
	fi
	printf "\n"
}

# Gets the status of a given tunnel
function getStatus {
	# Check if any processes are running for this tunnel
	local isRunning=$(isTunnelRunning "$4" "$3" "$5")

	if [ $isRunning = "true" ]; then
		prettyPrint "$1" "$2" "$3" "$4" "$5" "$6" 'Up'
	else
		prettyPrint "$1" "$2" "$3" "$4" "$5" "$6" 'Down'
	fi
}

# Starts a tunnel if it's not currently running
function startTunnel {
	# Find if any processes are running for this tunnel already
	local isRunning=$(isTunnelRunning "$4" "$3" "$5")

	if [ "$isRunning" = "true" ]; then
		# Tunnel is already up, so don't start it
		prettyPrint "$1" "$2" "$3" "$4" "$5" "$6" 'Up'
	else
		# Tunnel is down so start it up
		prettyPrint "$1" "$2" "$3" "$4" "$5" "$6" 'Starting'
		# Kill current tunnel
		killTunnelProcesses "$4" "$3" "$5"
		# Start the tunnel in the background
		startTunnelProcess "$4" "$3" "$5" "$6"
	fi
}

# Stops a tunnel if it's currently running
function stopTunnel {
	# Find if any processes are running
	local isRunning=$(isTunnelRunning "$4" "$3" "$5")

	if [ "$isRunning" = "false" ]; then
		prettyPrint "$1" "$2" "$3" "$4" "$5" "$6" 'Down'
	else
		prettyPrint "$1" "$2" "$3" "$4" "$5" "$6" 'Stopping'
		# Kill current tunnel
		killTunnelProcesses "$4" "$3" "$5"
	fi
}

# Restarts a tunnel only if it's currently running
function restartTunnel {
	# Find if any processes are running
	local isRunning=$(isTunnelRunning "$4" "$3" "$5")

	if [ $isRunning = "false" ]; then
		prettyPrint "$1" "$2" "$3" "$4" "$5" "$6" 'Down'
	else
		prettyPrint "$1" "$2" "$3" "$4" "$5" "$6" 'Restarting'
		# Kill current tunnel
		killTunnelProcesses "$4" "$3" "$5"
		# Start the tunnel in the background
		startTunnelProcess "$4" "$3" "$5" "$6"
	fi
}

# Starts autossh process for a tunnel
function startTunnelProcess {
	autossh -f -M 0 -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -NL ${1}:${2}:${3} "$4"
}

# Kills any processes currently running for a tunnel
function killTunnelProcesses {
	ps -ef | grep ${1}:${2}:${3} | grep -v grep | awk '{print $2}' | while read pid ; do kill -9 $pid ; done
}

# Searches and extracts matching tunnels from spreadsheet
function findTunnelsFromSpreadsheet {
	# Check if the user has specified all
	if [ "$1" = '' ]; then
		# If all then result is every record except the spreadsheet header
		tail -n+2 $input
	else
		# Otherwise look for records that contain name or tag matching params
		local tunnelCount=0
		local awkString=''
		for tag in "$@"
		do
			if [ "$tunnelCount" = 0 ]; then
				awkString="/(${tag} | ${tag}|,${tag},|^${tag},)/"
			else
				awkString="${awkString} && /(${tag} | ${tag}|,${tag},|^${tag},)/"
			fi
			((tunnelCount++))
		done
		cat $input | awk "${awkString}"
	fi
}

# Main script controller

tunnels=$(findTunnelsFromSpreadsheet ${@:2})

# If no tunnel was found then let the user know
if [ ${#tunnels} = 0 ]; then
	echo "No tunnel found with tags: ${@:2}"
else
	# Loop over each row in spreadsheet
	echo -e "$tunnels" | while IFS=',' read -r f1 f2 f3 f4 f5 f6
	do
		if [ $command = "start" ]; then
			startTunnel "$f1" "$f2" "$f3" "$f4" "$f5" "$f6"
		elif [ $command = "stop" ]; then
			stopTunnel "$f1" "$f2" "$f3" "$f4" "$f5" "$f6"
		elif [ $command = "restart" ]; then
			restartTunnel "$f1" "$f2" "$f3" "$f4" "$f5" "$f6"
		elif [ $command = "status" ]; then
			getStatus "$f1" "$f2" "$f3" "$f4" "$f5" "$f6"
		fi
	done
fi

exit 0
