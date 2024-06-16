#!/bin/bash
# 版本号：v2.0

init_env() {
	SCRIPT_PATH=$(cd "$(dirname "$0")";pwd)
	echo "SCRIPT_PATH: $SCRIPT_PATH"

	PROJECT_PATH=$(dirname $(cd "$SCRIPT_PATH"; pwd))
  echo "PROJECT_PATH: $PROJECT_PATH"

  PROJECT_NAME=$(basename "$PROJECT_PATH")
  echo "PROJECT_NAME: $PROJECT_NAME"

	# 泳道配置信息
	echo "LANE: ${LANE:-default}"
	L_LANE=${LANE:-default}

	L_SERVER_ENV=${1:-$SERVER_ENV} #来自参数
	if [ -z "$L_SERVER_ENV" ]; then
		echo "WARN: SERVER_ENV arg not set!"
		L_SERVER_ENV=$SERVER_ENV # 来自环境变量
	fi

	if [ -z "$L_SERVER_ENV" ]; then
		echo "ERROR: The SERVER_ENV not config!"
		exit 1
	fi
	echo "L_SERVER_ENV: $L_SERVER_ENV"

	# 业务单位配置信息
	ACTIVE_PROFILES=$L_SERVER_ENV
	BIZ_UNIT=$BIZ_UNIT
	echo "BIZ_UNIT: $BIZ_UNIT"
	if [ ! -z "$BIZ_UNIT" ] && [ "$BIZ_UNIT" != "null" ]; then
		ACTIVE_PROFILES="$BIZ_UNIT"-"$L_SERVER_ENV"
	fi
	echo "ACTIVE_PROFILES:" "$ACTIVE_PROFILES"

	L_SERVER_PORT1=${2:-$SERVER_PORT1} #来自参数
	if [ -z "$L_SERVER_PORT1" ]; then
		echo "WARN: SERVER_PORT1 arg not set!"
		L_SERVER_PORT1=$SERVER_PORT1 # 来自环境变量
	fi

	if [ -z "$L_SERVER_PORT1" ]; then
		echo "ERROR: The SERVER_PORT1 not config!"
		exit 1
	fi
	SERVER_PORT1=$L_SERVER_PORT1
	echo "SERVER_PORT1:" "$SERVER_PORT1"
}

# java参数设置
set_basic_opts() {
  echo "JAVA_HOME:" "$JAVA_HOME"
  if [ -n "$JAVA_HOME" ]; then
    JAVA_CMD="$JAVA_HOME/bin/java"
  else
    JAVA_CMD="java"
  fi
  echo "JAVA_CMD:" "$JAVA_CMD"

	JAVA_OPTS=" -Dspring.profiles.active=${ACTIVE_PROFILES} -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8 "
  # jvm gc参数配置
  JAVA_GC_OPTS=""
	# 内存参数配置
	JAVA_MEM_OPTS=""

  JAVA_VERSION=$("$JAVA_CMD" -version 2>&1 | sed -n -E 's/.* version "([^."-]*).*/\1/p')
  if [ "$JAVA_VERSION" != "" ] && [ "$JAVA_VERSION" = "21" ]
  then
    JAVA_MEM_OPTS=" -server -Xmx${JVM_XMX:-2g} -Xms${JVM_XMS:-2g} -Xmn${JVM_XMN:-768m} -Xss${JVM_XSS:-256k} -XX:+UseZGC -XX:+ZGenerational "
    JAVA_GC_OPTS=" -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$PROJECT_PATH/logs/java.hprof -Xlog:gc*,gc+age=trace,safepoint:file=$PROJECT_PATH/logs/gc.log:utctime,pid,tags:filecount=${JVM_GC_LOG_NUM:-7},filesize=${JVM_GC_LOG_SIZE:-2m} "
  else
    BITS=`"$JAVA_CMD" -version 2>&1 | grep -i 64-bit`
    if [ -n "$BITS" ]; then
        JAVA_MEM_OPTS=" -server -Xmx${JVM_XMX:-2g} -Xms${JVM_XMS:-2g} -Xmn${JVM_XMN:-768m} -Xss${JVM_XSS:-256k} -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:LargePageSizeInBytes=128m -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70 "
    else
        JAVA_MEM_OPTS=" -server -Xms${JVM_XMX:-1g} -Xmx${JVM_XMS:-1g} -XX:SurvivorRatio=2 -XX:+UseParallelGC "
    fi
    JAVA_GC_OPTS=" -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$PROJECT_PATH/logs/java.hprof -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintTenuringDistribution -XX:+PrintHeapAtGC -XX:+PrintReferenceGC -XX:+PrintGCApplicationStoppedTime -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=${JVM_GC_LOG_NUM:-7} -XX:GCLogFileSize=${JVM_GC_LOG_SIZE:-2m} -Xloggc:$PROJECT_PATH/logs/gc.log "
  fi
}

# nacos参数设置
set_nacos_opts() {
  NACOS_OPTS=" -DJM.LOG.PATH=$PROJECT_PATH/logs/ -DJM.SNAPSHOT.PATH=$PROJECT_PATH "
}

# jvm debug jmx参数配置
set_debug_jmx_opts() {
	# 启动模式信息
	echo "START_MODE: $START_MODE"
	JAVA_DEBUG_OPTS=""
	JAVA_JMX_OPTS=""
	if [ ! -z "$START_MODE" ] && [ "$START_MODE" != "null" ]; then
		if [ "$START_MODE" = "debug" ] && [ "$L_SERVER_ENV" != "prod" ]; then
			JAVA_DEBUG_OPTS=" -Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=${JVM_DEBUG_PORT:-5000},server=y,suspend=n "
		fi
		if [ "$START_MODE" = "jmx" ] && [ "$L_SERVER_ENV" != "prod" ]; then
			JAVA_JMX_OPTS=" -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=${JVM_JMX_PORT:-1099} -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false "
		fi
	fi
}

set_opts() {
	set_basic_opts
	set_nacos_opts
	set_debug_jmx_opts
}

start_java() {
  SEARCH_PATH="$PROJECT_PATH"
	JAR_PATH=$(realpath $SEARCH_PATH/${PROJECT_NAME/-${L_LANE}/}*.jar)
	if [ -z "$JAR_PATH" ]; then
	  SEARCH_PATH="$SEARCH_PATH/target"
	  echo "INFO: Searching in another path $SEARCH_PATH"
    JAR_PATH=$(realpath $SEARCH_PATH/${PROJECT_NAME/-${L_LANE}/}*.jar)
  fi

  echo "JAR_PATH: $JAR_PATH"
  if [ -z "$JAR_PATH" ]; then
    echo "ERROR: The JAR_PATH is empty, please check it!"
    exit 1
  fi

  echo -e "INFO: Starting the $PROJECT_NAME ..."
	"$JAVA_CMD" $JAVA_OPTS $NACOS_OPTS $JAVA_MEM_OPTS $JAVA_GC_OPTS $JAVA_DEBUG_OPTS $JAVA_JMX_OPTS -jar $JAR_PATH
}

init_env "$@"
set_opts
start_java