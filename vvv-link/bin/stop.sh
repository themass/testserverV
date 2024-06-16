#!/bin/bash
# 版本号：v2.0

init_env() {
	SCRIPT_PATH=$(cd "$(dirname "$0")";pwd)
	echo "SCRIPT_PATH: $SCRIPT_PATH"

	PROJECT_NAME=$(basename $(dirname $(cd "$SCRIPT_PATH"; pwd)))
	echo "PROJECT_NAME: $PROJECT_NAME"

	if [ "$1" = "-f" ]; then
	  FORCE_KILL=true
	fi
}

kill_stop() {
	cd "$(dirname $SCRIPT_PATH)"
	pwd
	PID=$(ps -ef | grep java | grep "$PROJECT_NAME" | awk '{print $2}')
	if [ -z "$PID" ]; then
    echo "WARN: PID is empty return directly."
    exit 1
  fi

	echo -e "INFO: Stopping the $PROJECT_NAME ..."
	if [ "$FORCE_KILL" = true ]; then
	  echo "INFO: Start force kill service."
		echo "INFO: Kill -9 $PID"
		kill -9 $PID >/dev/null 2>&1
	else
		echo "INFO: Kill $PID"
		kill $PID >/dev/null 2>&1
	fi

  echo "INFO: Check stopping status for the $PROJECT_NAME"
	COUNT=0
	while [ $COUNT -lt 1 ]; do
	  echo -e ".\c"
		sleep 1
		COUNT=1
		PID_EXIST=$(ps -f -p $PID | grep java)
		if [ -n "$PID_EXIST" ]; then
		  echo -e "\nINFO: The $PROJECT_NAME service is stopped."
			COUNT=0
			break
		fi
		echo -e "."
	done

	echo "OK!"
	echo "PID: $PID"
}

systemctl_stop() {
  if ( systemctl list-units --full -all | grep -Fq "$PROJECT_NAME.service" ) ;then
    echo "WARN: $PROJECT_NAME.service not exists return directly."
    exit 1
  fi

  echo -e "INFO: Stopping the $PROJECT_NAME ..."
  systemctl --user stop $PROJECT_NAME

  echo "INFO: Check stopping status for the $PROJECT_NAME"
	COUNT=0
	while [ $COUNT -lt 1 ]; do
		echo -e ".\c"
		sleep 1
		COUNT=1
    if [ "$(systemctl --user is-active $PROJECT_NAME)" = "inactive" ]; then
      echo -e "\nINFO: The $PROJECT_NAME service is stopped."
      COUNT=0
      break
    fi
    echo -e "."
	done
	echo -e "OK!"
}

process_stop() {
    systemctl=$(command -v systemctl 2> /dev/null)
    if [ -z "${systemctl}" ] || [ ! -x "${systemctl}" ]; then
      echo "INFO: Use kill command to shutdown the service."
      kill_stop
    else
      if [ -n "$SYSTEMD_EXEC_PID" ] || [ -n "$INVOCATION_ID" ]; then
        # 避免脚本被systemctl调用，引起死循环问题
        echo "INFO: This script is being executed by systemctl, use kill command to shutdown the service."
        kill_stop
      else
        echo "INFO: Use systemctl command to shutdown the service."
        systemctl_stop
        sleep 5
        PID=$(ps -ef | grep java | grep "$PROJECT_NAME" | awk '{print $2}')
        if [ ! -z "$PID" ]; then
          echo "INFO: PID $PID is not empty use kill command to shutdown the service."
          kill_stop
        fi
      fi
    fi
}

init_env "$@"
process_stop
