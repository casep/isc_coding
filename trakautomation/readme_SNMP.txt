This is an automatic install/configure for net-snmp.

What this does is:
* Check for the config file (on Linux /etc/snmp.conf) with .original appended - if this is found then we assume we have already run and we don't do anything
* Installs net-snmp
* Copies the config file with .original appended
* Adds configuration (see below) to the config
* Enables snmpd
* Starts snmpd


Config that is appended:

# ISC Config
rocommunity public $net
master agentx
agentXSocket tcp:localhost:705


.... where $net is the local subnet address - line repeated for each one

After running this script you still need to enable SNMP in Caché:
* Go to [Home] > [Security Management] > [Services]
* Select Monitor and make sure it's enabled
* Go to [Home] > [Configuration] > [Monitor Settings]
* Set Start Patrol at System Startup: Yes
