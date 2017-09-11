#!/usr/bin/bash
# Quick and dirty script to capture %GSIZE on TrakCare databases
# Parameters
#  instance, name of the instance
#  namespace, TrakCare namespace, if the result of "LocalDatabaseList" looks like
#  SDCQ-ANALYTICS::/trak/sdcq/PRD/db/analytics/:....
#  namespace must be "SDCQ"
#  output, output file
#  ccr_text, optional, to avoid invoking the class with empty path
# Must be executed (cron or shell) by a user with access to the instance
#  without password/credentials
# Tested on AIX and RedHat 5 for TC2011 instances
#
#Casep, casep@intersystems.com, 20130425, Initial release

instance=sdcq2011db
LocalDatabaseList="##class(%ResultSet).RunQuery(\"Config.Databases\",\"LocalDatabaseList\")"
namespace=SDCQ
output=/tmp/"$instance"_databases_`date +%Y%m%d`.txt
ccr_text="This is a LIVE environment"

echo "Sizes for $instance">$output
echo "on `date`">>$output

ccontrol session $instance -U"%SYS" $LocalDatabaseList | grep -v "$ccr_text" | grep $namespace \
| cut -d":" -f3 | while read db; do echo $db>>$output; \
ccontrol session $instance -U"%SYS" "##class(%ResultSet).RunQuery(\"%SYS.GlobalQuery\",\"Size\",\"$db\",\"\",\"*\")">>$output ; \
echo "">>$output; echo "">>$output; echo "">>$output; done

