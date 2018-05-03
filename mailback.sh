#!/bin/sh -x
# 
# bin/mailback.sh, DESCRIPTION
# 
# Copyright (C) 2002 Jonathan J. Miner
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# $Id:$
# Jonathan J. Miner <miner@doit.wisc.edu>

cd ~/mail/

DEFCOMPTIME=30

for dir in 'backup' 'spam' 'dups/msgid'; do

    if test -d "$dir"; then
        box="$dir/curr"
    else
        box=$dir
    fi

    if test ! -e $box; then
        echo "$box not found!  Skipping rotation!"
        break
    fi

    if lockfile -! $box.lock; then
        echo "Error rotating mailbox $box!"
        break
    fi

    DATE=`date +%Y%m%d`

    if test -e "$dir/$DATE" -o -e "$box.$DATE"; then
        echo "$dir/$DATE already exists!  Skipping rotation."
        break
        rm -f $box.lock
    else
        if test -d "$dir"; then
            mv $box $dir/$DATE
        else
            mv $box $box.$DATE
        fi
    fi

    rm -f $box.lock

    if test "x$dir" = "xbackup"; then
        bzip2 -v --best $dir/$DATE
        echo "Deleting..."
        find $dir -atime +90 -name '*.bz2' -type f -exec rm '{}' ';' -print
        echo "Done deleting."
    fi
    echo "Compressing.."

    case $box in 
        "dups/msgid") COMPTIME= ;;
        *) COMPTIME="-atime +$DEFCOMPTIME" ;;
    esac
        
    if test -d "$dir"; then
        find $dir $COMPTIME '!' -name '*.bz2' -type f -exec bzip2 -v --best '{}' ';' -print
    else
        name=`basename $box`
        find `dirname $box` -name "$name*" $COMPTIME '!' -name '*.bz2' -type f -exec bzip2 -v --best '{}' ';' -print
    fi
    echo "Done compressing."
done
