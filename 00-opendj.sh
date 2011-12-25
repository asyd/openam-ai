#/usr/bin/env bash

# This script proceed to extraction of OpenDJ Zip archive and its configuration

# Bruno Bonfils, <bbonfils@opencsi.com>
# June 2011

basedir=$(readlink -f $(dirname $0))
common_dir=${basedir}/common
required_commands=(unzip curl java ldapmodify)

# Include common functions
. ${common_dir}/functions.sh

check_requirements_cmd

config_file=$1
backup_dir=$2

if [[ -n $backup_dir ]] ; then
	backup_dir=$(readlink -f $backup_dir)
	if [[ ! -r $backup_dir/opendj/ldif/backup.ldif ]] ; then
		echo "backup dir seem not a backup directory! $backup_dir/opendj/ldif/backup.ldif doesn't exit"
		exit 1
	fi
fi

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

# Extract OpenDJ
run_cmd "Extracting OpenDJ" unzip -d $OPENDJ_EXTRACT_DIR $OPENDJ_ARCHIVE


if [[ -n $backup_dir ]] ; then
	run_cmd_in_path "Setting up OpenDJ" $OPENDJ_EXTRACT_DIR/OpenDJ-$OPENDJ_VERSION \
	./setup -n -b $OPENDJ_BASEDN -p $OPENDJ_PORT \
	--adminConnectorPort $OPENDJ_ADMIN_PORT -x $OPENDJ_JMX_PORT \
	-w $OPENDJ_ROOT_PASSWORD 

	run_cmd "Allowing multiple structural objectClass in OpenDJ" ldapmodify -xh localhost -p $OPENDJ_PORT \
		-D 'cn=Directory Manager ' -w $OPENDJ_ROOT_PASSWORD -f $tmpfile

	run_cmd_in_path "Stopping OpenDJ" $OPENDJ_EXTRACT_DIR/OpenDJ-$OPENDJ_VERSION ./bin/stop-ds

	run_cmd "Copying OpenAM schema from backup" \
	cp $backup_dir/opendj/config/schema/99-user.ldif $OPENDJ_EXTRACT_DIR/OpenDJ-$OPENDJ_VERSION/config/schema

	run_cmd_in_path "Importing LDIF" $OPENDJ_EXTRACT_DIR/OpenDJ-$OPENDJ_VERSION \
	./bin/import-ldif -F -b $OPENDJ_BASEDN -n userRoot \
	-l $backup_dir/opendj/ldif/backup.ldif

	run_cmd_in_path "Starting OpenDJ" $OPENDJ_EXTRACT_DIR/OpenDJ-$OPENDJ_VERSION ./bin/start-ds
else
	tmpfile=$(mktemp $HOME/.opendj-XXXX)

	cat > $tmpfile <<EOF
dn: cn=config
changetype: modify
replace: ds-cfg-single-structural-objectclass-behavior
ds-cfg-single-structural-objectclass-behavior: accept
EOF

	run_cmd_in_path "Setting up OpenDJ" $OPENDJ_EXTRACT_DIR/OpenDJ-$OPENDJ_VERSION \
	./setup -n -b $OPENDJ_BASEDN -a -p $OPENDJ_PORT \
	--adminConnectorPort $OPENDJ_ADMIN_PORT -x $OPENDJ_JMX_PORT \
	-w $OPENDJ_ROOT_PASSWORD
	run_cmd "Allowing multiple structural objectClass in OpenDJ" ldapmodify -xh localhost -p $OPENDJ_PORT \
		-D 'cn=Directory Manager ' -w $OPENDJ_ROOT_PASSWORD -f $tmpfile

	run_cmd "Removing files" rm $tmpfile
fi


