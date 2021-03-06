#!/bin/sh -e
# Install extra fonts used for reports (Print & Preview)
# Glen Pitt-Pladdy (ISC)
# Casep, 20180809, adding Free to the deployment
. ./functions.sh


check_LINUX() {
        BASEPATH=/usr/share/fonts
        if [ -d $BASEPATH/PMSFonts ] || [ -d $BASEPATH/Free3of9 ] ; then return 0; fi
        return 1
}

install_LINUX() {
	if [ ! -d $BASEPATH/ ]; then
		mkdir -p $BASEPATH
	fi
	tar xzf archives/PMSFonts.tar.gz -C $BASEPATH/
	tar xzf archives/free3of9.tar.gz -C $BASEPATH/
	/usr/bin/fc-cache -f $BASEPATH
}


echo "########################################"
echo "Install PMSFonts"
if osspecific check; then
	echo "Fonts Directory Exists"
	exit 0
else
	osspecific install
fi


