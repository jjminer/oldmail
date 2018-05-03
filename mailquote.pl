#!/usr/bin/perl -w
# 
# bin/mailquote.pl, DESCRIPTION
# 
# Copyright (C) 2016 Jonathan J. Miner
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

use vars qw/$VERSION $FILE/;
($VERSION) = q$Revision: 1.1 $ =~ /([\d.]+)/;
($FILE) = q$RCSfile: bin/mailquote.pl,v $ =~ /^[^:]+: ([^\$]+),v $/;

use strict;

while ( <> ) {
    s/[\r\n]+(\s\s\s\s)?/\n> /g;
    # $_ = "> $_\n";

    s/^>\s+>/>>/g;
    # s/>\s+>/>>/g;

    print;
}

