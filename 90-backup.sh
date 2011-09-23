#/usr/bin/env bash

# This script proceed to OpenDJ backup (config and LDIF) and some OpenAM files

# Bruno Bonfils, <bbonfils@opencsi.com>
# June 2011

basedir=$(readlink -f $(dirname $0))
common_dir=${basedir}/common
required_commands=(rsync)

# Include common functions
. ${common_dir}/functions.sh

check_requirements_cmd

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

if [[ -z $JAVA_HOME ]]; then
	echo "JAVA_HOME not defined, aborting"
	exit 1
fi

config_file=${basedir}/$config_file

. $config_file

# here it go

# Backup

today=$(date '+%Y%d%m%H%M')

BACKUP_DIR=$BACKUP_DIR/$today

mkdir -p $BACKUP_DIR

# Prepare directories
mkdir $BACKUP_DIR/{opendj,openam}
mkdir $BACKUP_DIR/opendj/ldif
mkdir $BACKUP_DIR/openam/{data,war,cfg}

OPENDJ_DIR=$OPENDJ_EXTRACT_DIR/OpenDJ-$OPENDJ_VERSION

run_cmd "Backuping OpenDJ in LDIF" $OPENDJ_DIR/bin/export-ldif -l $BACKUP_DIR/opendj/ldif/backup.ldif \
	-n userRoot \
	-b $OPENDJ_BASEDN \
	-h localhost \
	-p $OPENDJ_ADMIN_PORT \
	-w $OPENDJ_ROOT_PASSWORD

run_cmd "Backuping OpenDJ configuration" rsync -arv $OPENDJ_DIR/config $BACKUP_DIR/opendj

run_cmd "Backuping OpenAM data" rsync -arv $OPENAM_DATA_DIR/ $BACKUP_DIR/openam/data
run_cmd "Backuping OpenAM war" rsync -arv $J2EE_DEPLOY_DIR/opensso/ $BACKUP_DIR/openam/war
run_cmd "Backuping OpenAM configuration file" rsync -arv $HOME/.openssocfg/ $BACKUP_DIR/openam/cfg
