#/usr/bin/env bash

# This script proceed to OpenDJ backup (config and LDIF) and some OpenAM files

# Bruno Bonfils, <bbonfils@opencsi.com>
# June 2011

basedir=$(readlink -f $(dirname $0))
common_dir=${basedir}/common
required_commands=(rm)

# Include common functions
. ${common_dir}/functions.sh

check_requirements_cmd

read -p "Are you sure to purge every thing (including data) y/n? "

if [[ $REPLY != "y" ]] ; then
	exit 1
fi

config_file=$1
shift

if [[ -z $config_file ]] ; then
	echo "You must specify a configuration file, aborting."
	exit 1
fi

if [[ ! -r $config_file ]] ; then
	echo "$config_file is not readable, aborting."
	exit 1
fi

config_file=${basedir}/$config_file

. $config_file

run_cmd "Shuting down J2EE container" ${J2EE_STOP_CMD}
run_cmd "Purge files" rm -fr $HOME/.openssocfg ${OPENAM_EXTRACT_DIR}/opensso ${OPENAM_ADMIN_TOOLS_DIR} ${OPENAM_CONFIG_TOOLS_DIR} ${OPENAM_DATA_DIR} $J2EE_DEPLOY_DIR/opensso.war $J2EE_DEPLOY_DIR/opensso

read -p "Do you want purge OpenDJ y/n? "

if [[ $REPLY == "y" ]] ; then
	run_cmd "Shuting down OpenDJ" ${OPENDJ_EXTRACT_DIR}/OpenDJ-${OPENDJ_VERSION}/bin/stop-ds
    run_cmd "Purge OpenDJ files" rm -fr ${OPENDJ_EXTRACT_DIR}/OpenDJ-${OPENDJ_VERSION} 
fi

