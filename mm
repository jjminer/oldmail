#!/usr/bin/perl
#
# mailmenu.pl, display menu of folders with new mail
#
# Copyright (C) 1999 Jonathan J. Miner
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
# $Id: mailmenu.pl,v 1.20 2003/08/08 15:34:02 miner Exp $
# Jon Miner <miner@doit.wisc.edu>
#


BEGIN { $Curses::OldCurses = 1; }
use Curses;
use perlmenu;
use Data::Dumper;

($VERSION) = q$Revision: 1.20 $ =~ /([\d\.]+)/;
$HEADER = "JMXMail v$VERSION -";

$| = 1;				# Flush after every write to stdout

$PROG = $0;

$mailerbin = $ENV{MUTT_CMDLINE} ? $ENV{MUTT_CMDLINE} : "mutt";
$mailreadbin = "mr";

# $maileropts = "-f";
$maileropts = "";
$postponedopts = "-p";
$folderprefix = "+";
$draftmessage = "~/nomessage";
$draftopts = "-H";

$mailloc = "~/mail";
$postponedfile = "$mailloc/postponed";
$aliasfile = "~/.aliases";
$aliaspos = 1;

$dat = "~/.mm";

$aliasfile =~ s/~/$ENV{HOME}/g;
$postponedfile =~ s/~/$ENV{HOME}/g;
$mailloc =~ s/~/$ENV{HOME}/g;
$dat =~ s/~/$ENV{HOME}/g;

$stats{prog} = (stat $0)[9];

&menu_prefs(0,0,0,"","",1,0);

$i = 0;
while (1) {
    %newmail = ();
    %newmail = &initmail();

    &menu_init(1,"-$HEADER New Mail ($i)",1);
    $i++;

    if ($newmail{numnew} != 0) {
        $xtitle = "$HEADER $newmail{numnew} unread messages ";
        $xtitle .= "($newmail{numtotal} total) in $newmail{newfolders} folders";
        &menu_item("Refresh ($newmail{newfolders}:$newmail{numnew} ".
                   "- $newmail{allfolders}:$newmail{numtotal})","refresh");

        if (defined($newmail{'mbox/curr'})) {
            &menu_item("inbox (".$newmail{'mbox/curr'}->{new}.
                       ":".$newmail{'mbox/curr'}->{total}.")",'mbox/curr');
            $xtitle .= " (".$newmail{'mbox/curr'}->{new}." inbox)";
        }

        &menu_item("Send Mail","sendmail");
        &menu_item("All","all");
        &menu_item("postponed","postponed") if ((! -z $postponedfile) && (-e $postponedfile));

        foreach $key (grep($_ ne 'mbox/curr', sort keys %newmail)) {
            next if (($key eq "numnew")
                     || ($key eq "numtotal")
                     || ($key eq "newfolders")
                     || ($key eq "allfolders")
                     || ($key =~ /^backup/)
                     || ( ($key =~ m#^spam/#) && ($key ne 'spam/curr') )
                     || ($newmail{$key}->{new} == 0)
                     || (! -e "$mailloc/$key")
                     || ( $key =~ m#^dups/# )
                 );
            my ($name) = $key =~ m!(.*)/curr!;
            $name ||= $key;
            &menu_item("$name (".$newmail{$key}->{new}.":".$newmail{$key}->{total}.")",$key);
        }

        &Xtitle("$xtitle");
    }

    $sel= &menu_display("");
    &Xtitle("$HEADER $sel");

    exit if ($sel eq "exit");
    if ($sel eq "sendmail") {
        &menu_init(1,"$HEADER Sending Mail",0);

        &menu_item("Back", "%UP%");
        &menu_item("Blank","Blank");
        open( ALIASES, "$aliasfile") || die ("open ($aliasfile): $!\n");

        %aliases = ();
        while (<ALIASES>) {
            /alias (\S*) ([^<]*) </;
            $aliases{$1} = $2;
        }
        foreach (sort keys %aliases) {
            &menu_item($aliases{$_}, $_);
        }

        close( ALIASES );

        $to = &menu_display("");

        exit if ($to eq "exit");
        next if ($to eq "%UP%");
        if ($to eq "Blank") {
            system($mailerbin,$draftopts,$draftmessage);
            next;
        }

        system($mailerbin,$to);

        next;
    }
    if ($sel eq "%EMPTY%") {
        sleep 5;
        next;
    }
    if ($sel eq "postponed") {
        system($mailerbin, $postponedopts);
        next;
    }
    if ($sel eq "all") {
        &menu_init(1,"$HEADER All Folders",0);

        &menu_item("Back", "%UP%");
        $xtitle = "$HEADER $newmail{numnew} messages, ".($#newmail + 1)." folders";
        foreach $key (sort keys %newmail) {
            next if (($key eq "numnew")
                     || ($key eq "numtotal")
                     || ($key eq "newfolders")
                     || ($key eq "allfolders"));
            &menu_item("$key (".$newmail{$key}->{new}.":".$newmail{$key}->{total}.")",$key);
            $xtitle .= " ($newmail{$key} inbox)" if ($key eq "mbox/curr");
        }

        &Xtitle("$xtitle)");
        $to = &menu_display("");

        exit if ($to eq "exit");
        next if ($to eq "%UP%");
        system($mailreadbin,$maileropts,"$folderprefix$to");
        next;
    }
    if ($sel eq "refresh") {
        %newmail = ();
        # %newmail = &initmail();
        next;
    }
    print STDERR "$folderprefix$sel\n";
    system($mailreadbin, "$folderprefix$sel");
    # $fuck = <STDIN>
}

sub Xtitle {
    my $title = shift;
    print "]0\;$title";
}

sub initmail() {

    if ( -f $dat ) {
        # print "Reading cache...\n";
        $tmp = do $dat;
        my $old = $stats{prog};
        %stats = %{$tmp->[0]};
        $stats{prog} = $old;
        %folders = %{$tmp->[1]};

        # print STDERR "FOLDERS: ", join ",", keys %folders, "\n";
        # print STDERR "STATS: ", join ",", keys %stats, "\n";
    }

    $progstat = (stat $PROG)[9];
    if ($progstat != $stats{prog})  {
        print STDERR "Executable changed - Reloading $PROG\n";
        $stats{prog} = $progstat;
        exec $PROG;
    }

    print STDERR "reading directory...";
    %oldfolders = %folders;
    %folders = ();

    &process_dir( '' );

    print STDERR "done.\n";

    $folders{'numnew'} = 0;
    $folders{'numtotal'} = 0;
    $folders{'newfolders'} = 0;
    $folders{'allfolders'} = 0;

    foreach $key (keys %folders) {
        delete $folders{$key} if (-d "$mailloc/$key");
        next if (($key =~ /^backup/)
                 || ( ($key =~ m#^spam/#) && ($key ne 'spam/curr') )
                 || ("numnew" eq $key)
                 || ("numtotal" eq $key)
                 || ("newfolders" eq $key)
                 || ("allfolders" eq $key)
                 || ($key =~ m#^dups/#));
        $folders{'numnew'} += $folders{$key}->{new};
        $folders{'numtotal'} += $folders{$key}->{total};
        $folders{'newfolders'}++ if ($folders{$key}->{new} != 0);
        $folders{'allfolders'}++;
    }

    open DAT, ">$dat";
    print DAT Dumper([ \%stats, \%folders ]);
    close DAT;

    %folders;
}

sub process_dir {
    my $dir = shift;

    # print STDERR "DIR: $dir\n";

    opendir(DIR, "$mailloc/$dir");
    foreach my $folder (sort readdir(DIR)) {
        # next unless ( $folder =~ /^(f|l|m)/ );
        # next unless ( $folder =~ /^(s|2)/ );
        next if ( $folder =~ /^\./ );

        if ( -d "$mailloc/$dir/$folder" ) {
            &process_dir( $dir eq '' ? $folder : "$dir/$folder" );
        } elsif ( -f "$mailloc/$dir/$folder" ) {
            &process_mail( $dir eq '' ? $folder : "$dir/$folder" );
        }
    }
    closedir(DIR);
}

sub process_mail {
    my $folder = shift;

    # print STDERR "Processing $folder..\n";

    $stat = (stat "$mailloc/$folder")[10];
    # print STDERR "$mailloc/$folder: $stat > $stats{$folder}\n";
    if ($stat > $stats{$folder}) {
        # print "Reloading $folder\n";
        $stats{$folder} = "$stat";
        $folders{$folder}->{new} = 0;
        $folders{$folder}->{total} = 0;

        if ($folder !~ /^backup/) {
            open(FILE,"<$mailloc/$folder");
            my $header = 1;
            while (<FILE>) {
                $folders{$folder}->{new}++ if ($header && /^Status: (O|N)/);
                if (/^From /) {
                    $folders{$folder}->{total}++;
                    $header = 1;
                }
                $header = 0 if (/^$/);
            }
            close(FILE);
        }
        if ($folder{$folder}->{new} > 0 ) {
            print STDERR "O";
        } else {
            print STDERR "o";
        }

    } else {
        $folders{$folder} = $oldfolders{$folder};
        print STDERR ".";
   }
}
