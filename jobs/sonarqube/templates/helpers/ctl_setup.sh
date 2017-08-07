#!/usr/bin/env bash

# Setup env vars and folders for the ctl script
# This helps keep the ctl script as readable
# as possible

# Usage options:
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh JOB_NAME OUTPUT_LABEL
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh foobar
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh foobar foobar
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh foobar nginx

set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables

JOB_NAME=$1
output_label=${2:-${JOB_NAME}}

export JOB_DIR=/var/vcap/jobs/$JOB_NAME
chmod 755 $JOB_DIR # to access file via symlink

# Load some bosh deployment properties into env vars
# Try to put all ERb into data/properties.sh.erb
# incl $NAME, $JOB_INDEX, $WEBAPP_DIR
source $JOB_DIR/data/properties.sh

source $JOB_DIR/helpers/ctl_utils.sh
redirect_output ${output_label}

export HOME=${HOME:-/home/vcap}

# Setup the PATH and LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-''} # default to empty
for package_dir in $(ls -d /var/vcap/packages/*)
do
  has_busybox=0
  # Add all packages' /bin & /sbin into $PATH
  for package_bin_dir in $(ls -d ${package_dir}/*bin)
  do
    # Do not add any packages that use busybox, as impacts builtin commands and
    # is often used for different architecture (via containers)
    if [ -f ${package_bin_dir}/busybox ]
    then
      has_busybox=1
    else
      export PATH=${package_bin_dir}:$PATH
    fi
  done
  if [ "$has_busybox" == "0" ] && [ -d ${package_dir}/lib ]
  then
    export LD_LIBRARY_PATH=${package_dir}/lib:$LD_LIBRARY_PATH
  fi
done

# Setup log, run and tmp folders

export RUN_DIR=/var/vcap/sys/run/$JOB_NAME
export LOG_DIR=/var/vcap/sys/log/$JOB_NAME
export TMP_DIR=/var/vcap/sys/tmp/$JOB_NAME
export STORE_DIR=/var/vcap/store/$JOB_NAME
for dir in $RUN_DIR $LOG_DIR $TMP_DIR $STORE_DIR
do
  mkdir -p ${dir}
  chown vcap:vcap ${dir}
  chmod 775 ${dir}
done
export TMPDIR=$TMP_DIR

export C_INCLUDE_PATH=/var/vcap/packages/mysqlclient/include/mysql:/var/vcap/packages/sqlite/include:/var/vcap/packages/libpq/include
export LIBRARY_PATH=/var/vcap/packages/mysqlclient/lib/mysql:/var/vcap/packages/sqlite/lib:/var/vcap/packages/libpq/lib

# consistent place for vendoring python libraries within package
if [[ -d ${WEBAPP_DIR:-/xxxx} ]]
then
  export PYTHONPATH=$WEBAPP_DIR/vendor/lib/python
fi

if [[ -d /var/vcap/packages/java ]]
then
  export JAVA_HOME="/var/vcap/packages/java"
fi

# setup CLASSPATH for all jars/ folders within packages
export CLASSPATH=${CLASSPATH:-''} # default to empty
for java_jar in $(ls -d /var/vcap/packages/*/*/*.jar)
do
  export CLASSPATH=${java_jar}:$CLASSPATH
done

# RUNUSER: The user to run Bitbucket Server as.
RUNUSER=vcap

# BITBUCKET_HOME: Path to the Bitbucket home directory
SONAR_INSTALLDIR=/var/vcap/packages/sonarqube

file=$SONAR_INSTALLDIR/conf/sonar.properties
if [ -d "$file" ]; then
	rm -rf $file
    echo "directory $file already exist so will be deleted"	
fi

PIDFILE=$RUN_DIR/SonarQube.pid

cp -rf /var/vcap/jobs/sonarqube/config/sonar.properties $SONAR_INSTALLDIR/conf/sonar.properties
cp -rf /var/vcap/jobs/sonarqube/config/sonar.sh $SONAR_INSTALLDIR/bin/linux-x86-64/sonar.sh
cp -rf /var/vcap/jobs/sonarqube/config/wrapper.conf $SONAR_INSTALLDIR/conf/wrapper.conf
cp -rf /var/vcap/packages/plugins/* $SONAR_INSTALLDIR/extensions/plugins/

chown -R $RUNUSER:$RUNUSER $SONAR_INSTALLDIR 
run_with_home() {
        echo "export JAVA_HOME=${JAVA_HOME};export JRE_HOME=${JAVA_HOME};${SONAR_INSTALLDIR}/bin/linux-x86-64/sonar.sh $1"
        su - "$RUNUSER" -c "${SONAR_INSTALLDIR}/bin/linux-x86-64/sonar.sh $1"
}

#
# Function that starts the daemon/service
#
do_start()
{
    ${SONAR_INSTALLDIR}/bin/linux-x86-64/sonar.sh start
}

#
# Function that stops the daemon/service
#
do_stop()
{
      ${SONAR_INSTALLDIR}/bin/linux-x86-64/sonar.sh stop 
      kill_and_wait ${PIDFILE}
}



echo '$PATH' $PATH
