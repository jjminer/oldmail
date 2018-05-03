#!/usr/bin/perl -w
# 
# mimesubject.pl, DESCRIPTION
# 
# Copyright (C) 2003 Jonathan J. Miner
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
($FILE) = q$RCSfile: mimesubject.pl,v $ =~ /^[^:]+: ([^\$]+),v $/;

use strict;
use MIME::Base64;

my $head = 1;

while (<STDIN>) {
    $head = 0 if (/^$/);
    if ($head) {
        if (/^Subject: =\?ISO-8859-1\?[BQ]\?(.*)/i) {
            print "Subject: ", decode_base64($1), "\n";
            print "Original-$_";
        } else {
            print;
        }
    } else {
        print;
    }
}
