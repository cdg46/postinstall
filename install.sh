#!/bin/bash

##########################################################################
# (c) 2017 Yann BOGDANOVIC <ianbogda@gmail.com>
# All rights reserved
#
# This program is free software : you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# The GNU General Public License can be found at
# http://www.gnu.org/copyleft/gpl.html.
#
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
########################################################################## 
PWd=`pwd`
# Check for dependencies
function checkDependency() {
	if ! hash $1 2>&-;
	then
		echo "Failed!"
		echo "This script requires '$1' but it can not be found. Aborting."
		exit 1
	fi
}

date

echo -n "Checking dependencies..."
checkDependency "fail2ban-client"
checkDependency "ipset"
checkDependency "shorewall"
echo "Succeeded."

# update submodules
sudo git submodule update --recursive --remote
# fail2ban nicolargo
# https://github.com/nicolargo/fail2banarena
sudo cp $PWD/fail2banarena/action.d/iptables-tarpit.conf /etc/fail2ban/action.d/iptables-tarpit.conf
sudo cp $PWD/fail2banarena/filter.d/ban.conf /etc/fail2ban/filter.d/ban.conf
sudo cp $PWD/fail2banarena/filter.d/multiban.conf /etc/fail2ban/filter.d/multiban.conf
sudo cp $PWD/fail2banarena/jail.conf /etc/fail2ban/jail.local

# fail2ban + shorewall
# https://www.sysnove.fr/blog/2016/10/connecter-fail2ban-shorewall.html
sudo cp $PWD/shorewall-wrapper/fail2ban/action.d/shorewall-wrapper.conf /etc/fail2ban/action.d/shorewall-wrapper.conf
sudo cp $PWD/shorewall-wrapper/shorewall-drop-wrapper.sh /usr/local/sbin/shorewall-drop-wrapper.sh

# ipset-blacklist
# https://github.com/trick77/ipset-blacklist
sudo mkdir /etc/ipset-blacklist
sudo cp $PWD/ipset-blacklist/ipset-blacklist.conf /etc/ipset-blacklist/ipset-blacklist.conf
sudo cp $PWD/ipset-blacklist/update-blacklist.sh /usr/local/sbin/update-blacklist.sh
sudo /usr/local/sbin/update-blacklist.sh /etc/ipset-blacklist/ipset-blacklist.conf
sudo ipset restore < /etc/ipset-blacklist/ip-blacklist.restore
sudo iptables -I INPUT 1 -m set --match-set blacklist src -j DROP

sudo echo "33 23 * * *      root /usr/local/sbin/update-blacklist.sh /etc/ipset-blacklist/ipset-blacklist.conf" > /etc/cron.d/update-blacklist

# fail2ban TYPO3 8+
sudo cp $PWD/typo3-8/filter.d/apache-typo3.conf /etc/fail2ban/filter.d/apache-typo3.conf
sudo cat $PWD/typo3-8/jail.local >> /etc/fail2ban/jail.local

# reload fail2ban
sudo service fail2ban reload
