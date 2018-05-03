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

box=mbox

GREPMAILVER=`grepmail -V`

if test $? -ne 0 -o "x$GREPMAILVER" = "x"; then
    echo "No grepmail!"
    exit -1
fi

if lockfile -! $box/curr.lock; then
    echo "Error rotating mailbox $box!"
    exit -1
fi

DATE=`date +%Y%m%d`

if test -e "$box/$DATE"; then
    echo "$box/$DATE already exists!  Skipping rotation."
else
    cp -f $box/curr $box/bak.curr
    bzip2 -v -f $box/bak.curr
    mv $box/curr $box/.tmp

    grepmail -Y '^Status:\s*(O|N)' '.' $box/.tmp > "$box/curr"
    grepmail -vY '^Status:\s*(O|N)' '.' $box/.tmp > "$box/$DATE"

    rm $box/.tmp
    
fi

rm -f $box/curr.lock
