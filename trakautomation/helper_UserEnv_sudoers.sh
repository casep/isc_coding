#!/bin/sh
# this acts as an editor for "visudo" to add/enable the required config for Silver Level Security

. ./functions.sh

echo editing $1
# comment targetpw
sed --in-place 's/^\(Defaults targetpw\)/# \1/' $1
sed --in-place 's/^\(ALL\( \|\t\)\)/# \1/' $1
# %wheel
sed --in-place 's/^# \(%wheel\( \|\t\)\+\ALL=(ALL)\( \|\t\)\+ALL\)/\1/' $1
# %trakcache

echo "here"
echo "processing="$1
grep -q ^%trakcache $1 || sed --in-place "/%wheel\\( \\|\\t\\)\\+ALL=(ALL)\\( \\|\\t\\)\\+NOPASSWD:\\( \\|\\t\\)\\+ALL/ a \\\\n# ISC TrakCare: sudo -u $CACHEUSR\\n%trakcache ALL=($CACHEUSR) ALL" $1



