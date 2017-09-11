#!/bin/sh -e
# sets the FOP configuration (Java Options) in /etc/fop.conf TODO untested
# Glen Pitt-Pladdy (ISC)
. ./functions.sh



depends_SLES() {
echo depends
	# need Java for HotJVM etc.
	installdepends /usr/bin/java java-1_8_0-ibm
}
depends_RHEL() {
	installdepends /usr/bin/expect expect
	# need Java for HotJVM etc.
	installdepends /usr/bin/java java-1.8.0-openjdk
}



check_Unix() {
	CONF=/etc/fop.conf
	if [ -f $CONF ]; then return 0; fi
	return 1
}

config_Unix() {
	echo "#JVM tuning options - refer to Implementing Zen Reports with TrakCare documentation for configuration details" >$CONF
	echo "# -Xmx = maximum heap size (should matched by extra HugePages)" >>$CONF
	echo "JAVA_OPTS=\"-Xmx$JavaMaxHeap\"" >>$CONF
	echo "# -Xms = initial heap size (will be taken from HugePages on start)" >>$CONF
	echo "JAVA_OPTS=\"\$JAVA_OPTS -Xms$JavaInitHeap\"" >>$CONF
	echo "# -Xss = size of the stack for each thread" >>$CONF
	echo "JAVA_OPTS=\"\$JAVA_OPTS -Xss2m\"" >>$CONF
#	echo "# -Xmn = size of the heap for the young generation???" >>$CONF
#	echo "JAVA_OPTS=\"\$JAVA_OPTS -Xmn1024m\"" >>$CONF
	echo "# -XX:NewRatio = ratio between Max Heap and young generation" >>$CONF
	# making this ~5% based on discussions with LucaP
	echo "JAVA_OPTS=\"\$JAVA_OPTS -XX:NewRatio=20\"" >>$CONF
	echo "# These settings are optional tuning parameters for 64bit production systems only" >>$CONF
	echo "# HugePages Paramaters" >>$CONF
	echo "JAVA_OPTS=\"\$JAVA_OPTS -XX:+UseLargePages\"" >>$CONF
	echo "JAVA_OPTS=\"\$JAVA_OPTS -XX:LargePageSizeInBytes=2m\"" >>$CONF
	echo >>$CONF
	echo "JAVA_OPTS=\"\$JAVA_OPTS -XX:+UseConcMarkSweepGC\"" >>$CONF
	echo "JAVA_OPTS=\"\$JAVA_OPTS -XX:+UseParNewGC\"" >>$CONF
	echo "JAVA_OPTS=\"\$JAVA_OPTS -XX:SurvivorRatio=8\"" >>$CONF
	echo "JAVA_OPTS=\"\$JAVA_OPTS -XX:TargetSurvivorRatio=90\"" >>$CONF
	echo "JAVA_OPTS=\"\$JAVA_OPTS -XX:MaxTenuringThreshold=15\"" >>$CONF
	echo "JAVA_OPTS=\"\$JAVA_OPTS -XX:+UseCompressedOops\"" >>$CONF
	echo "#eof" >>$CONF
	./expect/FOPConf.expect $INST
}



echo "########################################"
# check for args
if [ $# -ne 5 ]; then
	echo "Usage: $0 <Site Code> <Environment> <Type>[Version] <JavaMaxHeap> <JavaInitialHeap>" >&2
	exit 1
fi
SITE=$1
ENV=$2
TYPE=$3
INST=`instname $SITE $ENV $TYPE`
JavaMaxHeap=$4
JavaInitHeap=$5
# get it going
if osspecific check; then
	echo "FOP/HotJVM Configuration Exists"
	exit 0
else
	echo "FOP/HotJVM Configuration for $SITE : $ENV ($INST)"
	# get cache password if needed
	if [ -z "$CACHEPASS" -a $TYPE != 'CSP' ]; then
		getpass "Caché Password" CACHEPASS
	fi
	osspecific depends
	osspecific config $@
fi


