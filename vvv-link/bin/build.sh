#!/bin/bash
# 版本号：v2.0

init_env() {
  SCRIPT_PATH=$(cd "$(dirname "$0")";pwd)
	echo "SCRIPT_PATH: $SCRIPT_PATH"

	PARENT_PROJECT_NAME=$(basename "$(dirname "$SCRIPT_PATH/../")")
	echo "PARENT_PROJECT_NAME: $PARENT_PROJECT_NAME"

	PROJECT_NAME=$(basename "$(dirname "$SCRIPT_PATH")")
	echo "PROJECT_NAME: $PROJECT_NAME"

	BUILD_PATH=$(dirname $(cd "$SCRIPT_PATH/../"; pwd))
	echo "BUILD_PATH: $BUILD_PATH"

	# 环境配置信息
	SERVER_ENV="${1:-$SERVER_ENV}" #来自参数或环境变量
	if [ -z "$SERVER_ENV" ]; then
		echo "ERROR: The SERVER_ENV not config!"
		exit 1
	fi

	BUILD_PROFILE=$SERVER_ENV
	# 业务单位配置信息
	BIZ_UNIT=${BIZ_UNIT:-null}
	echo "BIZ_UNIT: $BIZ_UNIT"
	if [ "$BIZ_UNIT" != "null" ]; then
		BUILD_PROFILE="$BIZ_UNIT-$BUILD_PROFILE"
	fi

	echo "BUILD_PROFILE: $BUILD_PROFILE"
}

mvn_package() {
	cd "$BUILD_PATH"
	pwd

	# 检查是否存在mvn命令
	if ! command -v mvn &>/dev/null; then
		echo "WARN: mvn not found. Adding it to PATH..."

		# 添加mvn到PATH环境变量
		export PATH="/opt/maven/apache-maven-3.9.2/bin:$PATH"
	fi
	#打包
	rm -rf "$BUILD_PATH/$PROJECT_NAME"/target
  if mvn -X clean package -Dmaven.test.skip=true -U -am -pl "$PROJECT_NAME" -P "$BUILD_PROFILE"; then
          echo "mvn package success"
  else
          echo "ERROR: mvn package failed"
          exit 1
  fi
  md5sum "$BUILD_PATH/$PROJECT_NAME"/target/"$PROJECT_NAME"-*.jar
}

cp_materials() {
	cd "$BUILD_PATH/$PROJECT_NAME"
	pwd

	#创建打包目录
	rm -rf ./output
	mkdir -p ./output

	#拷贝相关文件到打包目录
	cp -r ./bin ./output
	cp ./target/"$PROJECT_NAME"-*.jar ./output/
}

init_env "$@"
mvn_package
cp_materials