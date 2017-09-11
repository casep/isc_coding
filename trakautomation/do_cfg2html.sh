#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh


depends_SLES() {
	echo >/dev/null
}
depends_RHEL() {
	[ -x /usr/bin/unzip ] || yum -y install unzip
	[ -x /sbin/lspci ] || yum -y install pciutils
	[ -x /sbin/hdparm ] || yum -y install hdparm
}

install_SLES () {
	rpm -ivh cfg2html-linux-*.noarch.rpm
}
install_RHEL() {
	yum localinstall -y cfg2html-linux-*.noarch.rpm
}



echo "########################################"
# check args
echo "Install cfg2html"
# find installer
checked=''
installer=`for dir in \`pwd\` \`pwd\`/archives /tmp ~ ../installers ../InstallKit; do
		for file in $dir/cfg2html-linux-*_all.zip; do
			[ -f $file ] && readlink -f $file
		done
	done | sort -r | tail -n 1`
echo $installer
# install dependancies
osspecific depends
# check it's already installed
if which cfg2html >/dev/null 2>/dev/null; then
	echo "Already exists - skipping"
	exit 0
fi
# check we are root
if [ `whoami` != 'root' ]; then
	echo "Being run as user `whoami` - should be run as root"
	exit 1
fi

# install E2010
olddir=`pwd`
mkdir /tmp/cfg2htmlextract
cd /tmp/cfg2htmlextract
unzip $installer
osspecific install
cd $olddir
rm -r /tmp/cfg2htmlextract


