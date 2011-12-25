
# Run a command, I use a function to make easy usage of sudo, for example
function run_cmd {
	message=$1
	shift
	echo -n "$message: "
	"$@" >> $basedir/log/stdout.log 2>> $basedir/log/stderr.log </dev/null
	if [[ $? > 0 ]] ; then
		echo
		echo "An error occured while executing: $*"
		echo "Aborting, please consult $basedir/log/*"
		exit 1
	else
		echo "done."
	fi
}

function run_cmd_in_path {
	message=$1
	shift
	workingdir=$1
	shift
	echo -n "$message: "
	(cd $workingdir ; $* >> $basedir/log/stdout.log 2>> $basedir/log/stderr.log </dev/null)
	if [[ $? > 0 ]] ; then
		echo
		echo "An error occured while executing: $*"
		echo "Aborting, please consult $basedir/log/*"
		exit 1
	else
		echo "done."
	fi
}


function check_requirements_cmd {
	for cmd in "${required_commands[@]}"
	do
		type -p $cmd >/dev/null 2>/dev/null
		if [[ $? > 0 ]] ; then 
			echo "Command $cmd is required, aborting"
			exit 1
		fi
	done
}

function wait_for_url {
	message=$1
	shift
	echo -n "$message: "
    curl -s --max-time 1 --connect-timeout 1 $1 > /dev/null;
    while [ $? -gt 0 ]; do
            echo -n "."
            sleep 1;
            curl -s --max-time 1 --connect-timeout 1 $1 >/dev/null;
    done
    echo "done."	
}

function wait_for_url_pattern {
	message=$1
	shift
	echo -n "$message: "
	curl -s -i --max-time 10 --connect-timeout 1 $1 | tr -d '\r' | grep -i $2 >/dev/null
    while [ $? -gt 0 ]; do
            echo -n "."
            sleep 1;
	    	curl -s -i --max-time 10 --connect-timeout 1 $1 | tr -d '\r' | grep -i $2 >/dev/null
    done
    echo "done."	
}
