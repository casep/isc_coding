#!/bin/sh -e
# Install extra fonts used for reports (Print & Preview)
# Glen Pitt-Pladdy (ISC)
. ./functions.sh


check_LINUX() {
        BASEPATH=/usr/share/fonts
        if [ -d $BASEPATH/PMSFonts/ ]; then return 0; fi
        return 1
}

install_LINUX() {
	if [ ! -d $BASEPATH/ ]; then
		mkdir -p $BASEPATH
	fi
	tar jxvf archives/PMSFonts.tar.bz2 -C $BASEPATH/
}


echo "########################################"
echo "Install PMSFonts"
if osspecific check; then
	echo "Fonts Directory Exists"
	exit 0
else
	osspecific install
fi

