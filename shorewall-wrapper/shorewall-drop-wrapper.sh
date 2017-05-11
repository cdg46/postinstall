#!/bin/bash

#
# Guillaume Subiron, Sysnove, 2016
#
# Description :
#
# This script uses shorewall drop and shorewall allow to manage a blacklist.
#
# Instead of allowing an IP everytime we call shorewall allow. This script
# counts the number of times you call :
# "shorewall-drop-wrapper.sh drop 192.168.1.42"
# so you will have to call :
# "shorewall-drop-wrapper.sh allow 192.168.1.42"
# the same number of times before the IP is really allowed.
# This is usefull with fail2ban.
#
# Copyright 2016 Guillaume Subiron <guillaume@sysnove.fr>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the http://www.wtfpl.net/ file for more details.
#

counter=/var/tmp/fail2ban-$2

if [ -z $counter ]; then
    echo "0" > $counter
fi

case $1 in
    drop)
        shorewall drop $2
        echo $(($(<$counter)+1)) > $counter
    ;;
    allow)
        echo $(($(<$counter)-1)) > $counter
        if [ "$(<$counter)" -le "0" ]; then
            echo "0" > $counter
            shorewall allow $2
        fi
    ;;
    *)
    ;;
esac
