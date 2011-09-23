#/usr/bin/env bash

# This script proceed to extraction of OpenAM Zip archive, deploy the war, and configure openAM

# Bruno Bonfils, <bbonfils@opencsi.com>
# June 2011

basedir=$(readlink -f $(dirname $0))
common_dir=${basedir}/common
required_commands=(unzip curl java rsync)

# Include common functions
. ${common_dir}/functions.sh

config_file=$1
shift

if [[ -z $config_file ]] ; then
	echo "You must specify a configuration file, aborting."
	exit 1
fi

check_requirements_cmd

if [[ ! -r $config_file ]] ; then
	echo "$config_file is not readable, aborting."
	exit 1
fi

if [[ -z $JAVA_HOME ]]; then
	echo "JAVA_HOME not defined, aborting"
	exit 1
fi

config_file=${basedir}/$config_file

. $config_file

cd $OPENAM_ADMIN_TOOLS_DIR
./opensso/bin/ssoadm add-svc-realm -u amadmin -f ~/.openssocfg/amadmin -e '/' -s iPlanetAMSessionService
./opensso/bin/ssoadm set-realm-svc-attrs -u amadmin -f ~/.openssocfg/amadmin -e '/' -s iPlanetAMSessionService -a iplanet-am-session-max-idle-time=240
./opensso/bin/ssoadm set-realm-svc-attrs -u amadmin -f ~/.openssocfg/amadmin -e '/' -s iPlanetAMSessionService -a iplanet-am-session-max-session-time=480
