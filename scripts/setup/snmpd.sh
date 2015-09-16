#!/bin/bash
# Konfiguracja usług związanych z monitoringiem serwera w Cacti

. /opt/farm/scripts/init
. /opt/farm/scripts/functions.custom
. /opt/farm/scripts/functions.install



pass="/var/lib/snmp.community"
if [ ! -f $pass ]; then
	echo -n "enter snmp v2 community or hit enter to disable snmpd monitoring: "
	stty -echo
	read community
	stty echo
	echo ""  # force a carriage return to be output
	echo -n "$community" >$pass
	chmod 0600 $pass
fi


if [ ! -s $pass ]; then
	echo "skipping snmpd configuration (no community configured)"
elif [ ! -f $base/snmpd.tpl ]; then
	echo "skipping snmpd configuration (no template available for $OSVER)"
else
	bash /opt/farm/scripts/setup/role.sh snmpd

	echo "setting up snmpd configuration"
	community="`cat $pass`"
	cat $base/snmpd.tpl |sed -e "s/%%community%%/$community/g" -e "s/%%domain%%/`external_domain`/g" >/etc/snmp/snmpd.conf

	if [ -f $base/snmpd.default ]; then
		install_link $base/snmpd.default /etc/default/snmpd
	fi

	service snmpd restart

	if [ "$SYSLOG" = "true" ]; then
		echo "setting up snmpd debug message ignoring rules for logcheck"
		install_copy $common/logcheck/snmpd.tpl /etc/logcheck/ignore.d.server/local-snmpd
	fi
fi
