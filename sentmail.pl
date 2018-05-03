#!/usr/bin/perl -w
# 
# save.pl, DESCRIPTION
# 
# Copyright (C) 2001 Jonathan J. Miner
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
# $Id: save.pl,v 1.11 2004/01/10 20:37:15 miner Exp $
# Jonathan J. Miner <miner@doit.wisc.edu>

use strict;
use Date::Manip;
use Mail::Internet;
use Mail::Address;
use IO::File;

use vars qw/$VERSION $HOME $FILE $LOGFILE $LOG $LOCKFILE $FIFO $SAVEDIR $MAILDIR $MSGIDFILE $STAT/;

BEGIN {
    ($VERSION) = q$Revision: 1.11 $ =~ /([\d.]+)/;
    ($FILE) = q$RCSfile: save.pl,v $ =~ /^[^:]+: ([^\$]+),v $/;

    $HOME = "/home/miner";
    $LOGFILE = "$HOME/sentmail.log";
    $MAILDIR = "$HOME/mail";
    $SAVEDIR = "$MAILDIR/sent";
    $FIFO = "$SAVEDIR/sentmail";
    $LOCKFILE = "$SAVEDIR/.lock";
    $MSGIDFILE = "$SAVEDIR/.msgid";
    $STAT = (stat $0)[9];

    if (-e $LOCKFILE)  {
        exit;
    } else {
        $LOG = new IO::File( ">>$LOGFILE" );
        $LOG->autoflush(1);
        print $LOG "$$: ", scalar localtime, " $FILE v$VERSION Starting.. \n";
    }
}

$SIG{TERM} = $SIG{QUIT} = $SIG{INT} = sub {
    if ( defined $LOG ) {
        print $LOG "$$: ", scalar localtime, " Bailing.\n";
    }
    unlink($LOCKFILE);
    exit;
};

$SIG{HUP} = sub {
    if ( defined $LOG ) {
        print $LOG "$$: Restarting $0.\n";
    }
    unlink($LOCKFILE);
    $STAT = (stat $0)[9];
    exec($0);
};

END {
    if (defined $LOG) {
        print $LOG "$$: ", scalar localtime, " Ending.\n";
        $LOG->close;
    }
    unlink($LOCKFILE);
}

open LOCK, ">$LOCKFILE";
print LOCK "$$";
close LOCK;

while (1) {
    if ((stat $0)[9] != $STAT) {
        &{$SIG{HUP}};
    }

    unless ( -p $FIFO ) {
        unlink $FIFO;
        system('mknod', $FIFO, 'p')
            && die "Can't mknod $FIFO: $!";
    }

    open FIFO, "< $FIFO";
    my @stuff = <FIFO>;
    close FIFO;

    my $mail = new Mail::Internet (\@stuff);

    if ( $mail->head->get('From') =~ /^Mail System Internal Data/
         && $mail->head->get('Subject') =~ /^DON'T DELETE THIS MESSAGE -- FOLDER INTERNAL DATA/ ) {
         next;
     }

    my $msgid = $mail->head->get('Message-ID');

    open MSGID, "<$MSGIDFILE";
    my @msgids = <MSGID>;
    close MSGID;

    chomp(@msgids);
    chomp($msgid);

    if ( scalar grep $_ eq $msgid, @msgids ) {
        print $LOG "Skipping already processed message $msgid\n";
        next;
    }
    
    open MSGID, ">>$MSGIDFILE";
    print MSGID "$msgid\n";
    close MSGID;

    my @write = ( "$SAVEDIR/sent.".UnixDate("today", '%Y%m') );

    foreach my $header ( 'to', 'cc', 'bcc' ) {
        my @tmp = map( join( '/', $SAVEDIR, $header, lc($_->user) ), 
                          Mail::Address->parse($mail->head->get($header)) 
                     );
        print $LOG "Writing $header ", 
                     join(", ",@tmp), "\n" if (scalar @tmp);
        push @write, @tmp;
    }

    foreach (@write) {
        open(OUT, ">>$_");
        $mail->print(\*OUT);
        close(OUT);
    }
} continue {
    sleep 2;
}
