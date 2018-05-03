#!/bin/sh
# 
# bin/postprocmail.sh, DESCRIPTION
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

ORGMAIL=/var/spool/mail/miner

if cd $HOME &&
    test -s $ORGMAIL &&
    lockfile -r0 -l1024 .newmail.lock 2>/dev/null
then
    trap "rm -f .newmail.lock" 1 2 3 13 15
    umask 077
    lockfile -l1024 -ml
    cat $ORGMAIL >>.newmail &&
    cat /dev/null >$ORGMAIL
    lockfile -mu
    formail -s procmail <.newmail &&
    rm -f .newmail
    rm -f .newmail.lock
fi
exit 0

