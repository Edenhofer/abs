#!/bin/bash

_game="ArmA3"
_user="arma"
_server_root="/srv/steamcmd/${_game,,}"

source /etc/conf.d/"${_game,,}d.conf" || echo "Could not source /etc/conf.d/${_game,,}d.conf"

# General rule for the variable-naming-schema:
# Variables in capital letters may be passed through the command line others not.

# You may use this script for any server configuration of your choice, just alter the config file
SERVER_ROOT="${SERVER_ROOT:-${_server_root}}"
BACKUP_DEST="${BACKUP_DEST:-${_server_root}/backup}"
LOGPATH="${LOGPATH:-${_server_root}/logs}"
BACKUP_PATHS="${BACKUP_PATHS:-./}"
KEEP_BACKUPS="${KEEP_BACKUPS:-10}"
GAME_USER="${GAME_USER:-${_user}}"
MAIN_EXECUTABLE="${MAIN_EXECUTABLE:-${_game,,}server}"
SESSION_NAME="${SESSION_NAME:-${_game,,}}"

# Specify system parameters for the game server
SERVER_PARMS="${SERVER_PARMS:-""}"

# The actual program name
declare -r myname="${_game,,}d"

# Check whether sudo is needed at all
if [[ $(whoami) == ${GAME_USER} ]]; then
	SUDO_CMD=""
else
	SUDO_CMD="sudo -u ${GAME_USER}"
fi

# Check for sudo rigths
if [[ $(${SUDO_CMD} whoami) != ${GAME_USER} ]]; then
	echo -e "You have \e[39;1mno permission\e[0m to run commands as ${GAME_USER} user."
	exit 1
fi

# Pipe any given argument to the game server console
game_command() {
	${SUDO_CMD} screen -S "${SESSION_NAME}" -X stuff "`printf \"$*\r\"`"
}

# Start the server if it is not already running
server_start() {
	${SUDO_CMD} screen -S "${SESSION_NAME}" -Q select . > /dev/null
	if [[ $? -eq 0 ]]; then
		echo "A screen ${SESSION_NAME} session is already running. Please close it first."
	else
		echo -en "Starting server... "
		${SUDO_CMD} screen -dmS "${SESSION_NAME}" /bin/bash -c "cd '${SERVER_ROOT}'; ${MAIN_EXECUTABLE} ${SERVER_PARMS}"
		echo -e "\e[39;1m done\e[0m"
	fi
}

# Stop the server gracefully by saving everything prior and warning the users
server_stop() {
	${SUDO_CMD} screen -S "${SESSION_NAME}" -Q select . > /dev/null
	if [[ $? -eq 0 ]]; then
		echo -en "Server is going down... "
		game_command shutdown
		echo -e "\e[39;1m done\e[0m"
	else
		echo "The corresponding screen session for ${SESSION_NAME} was already dead."
	fi
}

# Print whether the server is running and if so give some information about memory usage and threads
server_status() {
	${SUDO_CMD} screen -S "${SESSION_NAME}" -Q select . > /dev/null
	if [[ $? -eq 0 ]]; then
		echo -e "Status:\e[39;1m running\e[0m"

		# Calculating memory usage
		for p in $(${SUDO_CMD} pgrep -f "${MAIN_EXECUTABLE}"); do
			ps -p${p} -O rss | tail -n1;
		done | gawk '{ count ++; sum += $2 }; END {count --; print "Number of processes =", count, "(screen, bash,", count-2, "x server-threads)"; print "Total memory usage =", sum/1024, "MB" ;};'
	else
		echo -e "Status:\e[39;1m stopped\e[0m"
	fi
}

# Restart the complete server by shutting it down and starting it again
server_restart() {
	${SUDO_CMD} screen -S "${SESSION_NAME}" -Q select . > /dev/null
	if [[ $? -eq 0 ]]; then
		server_stop
		sleep 0.1
		server_start
	else
		server_start
	fi
}

# Backup the directories specified in $BACKUP_PATHS
backup_files() {
	# Check for the availability of the tar binaries
	which tar &> /dev/null
	if [[ $? -ne 0 ]]; then
		echo "The tar binaries are needed for a backup."
		exit 2
	fi

	echo "Starting backup..."
	FILE="$(date +%Y_%m_%d_%H.%M.%S).tar.gz"
	${SUDO_CMD} mkdir -p "${BACKUP_DEST}"
	${SUDO_CMD} screen -S "${SESSION_NAME}" -Q select . > /dev/null
	if [[ $? -eq 0 ]]; then
		sync && wait
		${SUDO_CMD} tar -C "${SERVER_ROOT}" -czf "${BACKUP_DEST}/${FILE}" --totals ${BACKUP_PATHS} 2>&1 | grep -v "tar: Removing leading "
	else
		${SUDO_CMD} tar -C "${SERVER_ROOT}" -czf "${BACKUP_DEST}/${FILE}" --totals ${BACKUP_PATHS} 2>&1 | grep -v "tar: Removing leading "
	fi
	echo -e "\e[39;1mbackup completed\e[0m\n"

	echo -n "Only keeping the last ${KEEP_BACKUPS} backups and removing the other ones..."
	BACKUP_COUNT=$(for f in "${BACKUP_DEST}"/[0-9_.]*; do echo ${f}; done | wc -l)
	if [[ $(expr ${BACKUP_COUNT} - ${KEEP_BACKUPS}) -gt 0 ]]; then
		${SUDO_CMD} rm $(for f in "${BACKUP_DEST}"/[0-9_.]*; do echo ${f}; done | head -n$(expr ${BACKUP_COUNT} - ${KEEP_BACKUPS}))
		echo -e "\e[39;1m done\e[0m ($(expr ${BACKUP_COUNT} - ${KEEP_BACKUPS}) backup(s) pruned)"
	else
		echo -e "\e[39;1m done\e[0m (no backups pruned)"
	fi
}

# Restore backup
backup_restore() {
	# Check for the availability of the tar binaries
	which tar &> /dev/null
	if [[ $? -ne 0 ]]; then
		echo "The tar binaries are needed for a backup."
		exit 2
	fi

	# Only allow the user to restore a backup if the server is down
	${SUDO_CMD} screen -S "${SESSION_NAME}" -Q select . > /dev/null
	if [[ $? -eq 0 ]]; then
		echo -e "The \e[39;1mserver should be down\e[0m in order to restore the world data."
		exit 3
	fi

	# Either let the user choose a backup or expect one as an argument
	if [[ $# -lt 1 ]]; then
		echo "Please enter the corresponding number for the backup to be restored: "
		i=1
		for f in "${BACKUP_DEST}"/[0-9_.]*; do
			echo -e "    \e[39;1m$i)\e[0m\t$f"
			i=$((i+1))
		done
		echo -en "Restore backup number: "

		# Read in user input
		read user_choice

		# Interpeting the input
		if [[ $user_choice =~ ^-?[0-9]+$ ]]; then
			n=1
			for f in "${BACKUP_DEST}"/[0-9_.]*; do
				[[ ${n} -eq $user_choice ]] && FILE="$f"
				n=$((n+1))
			done
			if [[ -z $FILE ]]; then
				echo -e "\e[39;1mFailed\e[0m to interpret your input. Please enter a digit of the presented options."
				exit 5
			fi
		else
			echo -e "\e[39;1mFailed\e[0m to interpret your input. Please enter a valid digit for one of the presented options."
			exit 6
		fi
	elif [[ $# -eq 1 ]]; then
		# Check for the existance of the specified file
		if [[ -f "$1" ]]; then
			FILE="$1"
		else
			if [[ -f "${BACKUP_DEST}"/"$1" ]]; then
				FILE="${BACKUP_DEST}"/"$1"
			else
				echo -e "Sorry, but '$1', is \e[39;1mnot a valid file\e[0m, neither in your current directory nor in the backup folder."
				exit 4
			fi
		fi
	elif [[ $# -gt 1 ]]; then
		echo -e "\e[39;1mToo many arguments.\e[0m Please pass only the filename for the world data as an argument."
		echo "Or alternatively no arguments at all to chose from a list of available backups."
		exit 1
	fi

	echo "Restoring backup..."
	${SUDO_CMD} tar -xf "${FILE}" -C "${SERVER_ROOT}" 2>&1
	if [[ $? -eq 0 ]]; then
		echo -e "\e[39;1mRestoration completed\e[0m"
	else
		echo -e "\e[39;1mFailed to restore backup.\e[0m"
	fi
}

# Run the given comman at the game server console
server_command() {
	if [[ $# -lt 1 ]]; then
		echo "No server command specified."
		exit 1
	fi

	${SUDO_CMD} screen -S "${SESSION_NAME}" -Q select . > /dev/null
	if [[ $? -eq 0 ]]; then
		sleep 0.1s &
		sleep_pid=$!
		game_command "$@" &
		tail -f --pid=${sleep_pid} -n 0 "${LOGPATH}/latest.log"
	else
		echo "There is no ${SESSION_NAME} session to connect to."
	fi
}

# Enter the screen session
server_console() {
	${SUDO_CMD} screen -S "${SESSION_NAME}" -Q select . > /dev/null
	if [[ $? -eq 0 ]]; then
		${SUDO_CMD} screen -S "${SESSION_NAME}" -rx
	else
		echo "There is no ${SESSION_NAME} session to connect to."
	fi
}

# Help function, no arguments required
help() {
	cat <<-EOF
	This script was design to easily control ${_game} game servers. Quite every parameter for a given
	${_game} server derivative can be altered by editing the variables in the configuration file.

	Usage: $myname {start|stop|status|backup|restore|command <command>|console}
	    start                Start the ${_game} server
	    stop                 Stop the ${_game} server
	    restart              Restart the ${_game} server
	    status               Print some status information
	    backup               Backup the world data
	    restore [filename]   Restore the world data from a backup
	    command <command>    Run the given comman at the ${_game,,} server console
	    console              Enter the server console through a screen session

	Copyright (c) Gordian Edenhofer <gordian.edenhofer@gmail.com>
	EOF
}

case "$1" in
	start)
	server_start
	;;

	stop)
	server_stop
	;;

	status)
	server_status
	;;

	restart)
	server_restart
	;;

	console)
	server_console
	;;

	command)
	server_command "${@:2}"
	;;

	backup)
	backup_files
	;;

	restore)
	backup_restore "${@:2}"
	;;

	*|-h|--help)
	help
esac

exit 0
