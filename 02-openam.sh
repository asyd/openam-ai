#/usr/bin/env bash

# This script proceed to extraction of OpenAM Zip archive, deploy the war, and configure openAM

# Bruno Bonfils, <bbonfils@opencsi.com>
# June 2011

basedir=$(readlink -f $(dirname $0))
common_dir=${basedir}/common
required_commands=(unzip curl java rsync)

# Include common functions
. ${common_dir}/functions.sh

check_requirements_cmd

config_file=$1
shift
backup_dir=$1
shift

if [[ -z $config_file ]] ; then
	echo "You must specify a configuration file, aborting."
	exit 1
fi

if [[ ! -r $config_file ]] ; then
	echo "$config_file is not readable, aborting."
	exit 1
fi

if [[ -z $JAVA_HOME ]]; then
	echo "JAVA_HOME not defined, aborting"
	exit 1
fi

if [[ -n $backup_dir ]] ; then
	backup_dir=$(readlink -f $backup_dir)
	if [[ ! -r $backup_dir/opendj/ldif/backup.ldif ]] ; then
		echo "$backup_dir doesn't contains opendj/ldif/backup.ldif"	
		exit 1
	fi
fi

config_file=${basedir}/$config_file

. $config_file

# Purge log files
mkdir $basedir/log 2>/dev/null
touch $basedir/log/stdout.log ; echo -n > $basedir/log/stdout.log
touch $basedir/log/stderr.log ; echo -n > $basedir/log/stderr.log

# Ok, let's go. First of all, extract the Zip archive
run_cmd "Extracting OpenAM archive" unzip -d $OPENAM_EXTRACT_DIR $OPENAM_ARCHIVE

# restore mode ?
if [[ -n $backup_dir ]] ; then
	echo "Restore mode"
	if [[ ! -r $HOME/.openssocfg ]]; then
		mkdir $HOME/.openssocfg
		run_cmd "Restoring .openssocfg" cp $backup_dir/openam/cfg/* $HOME/.openssocfg
	fi

	if [[ ! -r $OPENAM_DATA_DIR ]]; then
		mkdir $OPENAM_DATA_DIR
		run_cmd "Restoring OpenAM data" rsync -arv $backup_dir/openam/data/ $OPENAM_DATA_DIR
	fi

	if [[ ! -r $J2EE_DEPLOY_DIR/opensso ]]; then
		mkdir $J2EE_DEPLOY_DIR/opensso
		run_cmd "Restoring OpenAM WAR" rsync -arv $backup_dir/openam/war/ $J2EE_DEPLOY_DIR/opensso
	fi

else
	echo "Initial install mode"
	
	if [[ -d $OPENAM_DATA_DIR ]]; then
		echo "OpenAM data directory ($OPENAM_DATA_DIR) already exists, aborting."
		exit 1
	fi

	run_cmd "Creating OpenAM directory" mkdir -p $OPENAM_DATA_DIR

	# Some checks
	if [[ -r $HOME/.openssocfg ]]; then
		echo "OpenAM config director ($HOME/.openssocfg already exists), aborting"
		exit 1
	fi

	# Then, copy the WAR
	run_cmd "Copying the WAR" cp $OPENAM_EXTRACT_DIR/$OPENAM_WAR $J2EE_DEPLOY_DIR

fi

# Starting the J2EE_SERVER is needed
if [[ "$J2EE_NEED_TO_START" == "1" ]] ; then
	run_cmd "Starting the J2EE Server" $J2EE_START_CMD
fi

wait_for_url_pattern "Waiting for OpenAM deployed" "${J2EE_URL_START}/config/options.htm" "DemoConfiguration"

# Sleep again 10 seconds, just in case
echo -n "Sleeping 5 seconds: "
sleep 5
echo "done."

# Initial install mode
if [[ ! -n $backup_dir ]] ; then
	# Extract configurator tools
	run_cmd "Extracting configurator tools" unzip -d $OPENAM_CONFIG_TOOLS_DIR $OPENAM_EXTRACT_DIR/$OPENAM_CONFIG_TOOLS_ARCHIVE
	
	# Create configurator config file
	tmpfile=$(mktemp $HOME/.openam-XXXX)
	cat <<EOF > $tmpfile
SERVER_URL=$OPENAM_SERVER_URL
DEPLOYMENT_URI=$OPENAM_DEPLOYMENT_URI
BASE_DIR=$OPENAM_DATA_DIR
locale=en_US
PLATFORM_LOCALE=en_US
AM_ENC_KEY=
ADMIN_PWD=$OPENAM_ADMIN_PASSWORD
AMLDAPUSERPASSWD=$OPENAM_URLAGENT_PASSWORD
COOKIE_DOMAIN=$OPENAM_COOKIE_DOMAIN

DATA_STORE=dirServer
DIRECTORY_SSL=SIMPLE
DIRECTORY_SERVER=localhost
DIRECTORY_PORT=$OPENDJ_PORT
ROOT_SUFFIX=$OPENDJ_BASEDN
DS_DIRMGRDN=cn=Directory Manager
DS_DIRMGRPASSWD=$OPENDJ_ROOT_PASSWORD

LB_SITE_NAME=openam
LB_PRIMARY_URL=${OPENAM_SERVER_URL}${OPENAM_DEPLOYMENT_URI}

USERSTORE_TYPE=LDAPv3ForOpenDS
USERSTORE_HOST=localhost
USERSTORE_PORT=$OPENDJ_PORT
USERSTORE_SUFFIX=$OPENDJ_BASEDN
USERSTORE_MGRDN=cn=Directory Manager
USERSTORE_PASSWD=$OPENDJ_ROOT_PASSWORD
EOF
	# Proceed to OpenAM configuration
	run_cmd_in_path "Configuring OpenAM" $OPENAM_CONFIG_TOOLS_DIR java -jar $OPENAM_CONFIG_TOOLS_DIR/configurator.jar -f $tmpfile
	if [[ ! -r ${OPENAM_DATA_DIR}/bootstrap ]] ; then
		echo "Error while configuring OpenAM, try to run the following command by hand, and check J2EE logs:"
		echo "java -jar $OPENAM_CONFIG_TOOLS_DIR/configurator.jar -f $tmpfile"
		exit 1 
	fi
fi

run_cmd "Purge files" rm $tmpfile

# Extract admin tools
run_cmd "Extracting admin tools" unzip -d $OPENAM_ADMIN_TOOLS_DIR $OPENAM_EXTRACT_DIR/$OPENAM_ADMIN_TOOLS_ARCHIVE

# Setup admin tools
run_cmd_in_path "Setting up admin tools" $OPENAM_ADMIN_TOOLS_DIR ./setup -p $OPENAM_DATA_DIR

if [[ ! -n $backup_dir ]];  then
	echo "Restarting OpenAM:"
	run_cmd "  Shutting down J2EE server" $J2EE_STOP_CMD
	run_cmd "  Sleeping 10 seconds" sleep 10
	run_cmd "  Starting J2EE server" $J2EE_START_CMD
	echo "done."
fi
