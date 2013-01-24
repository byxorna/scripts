#!/usr/bin/perl
# testing SMTP with ironports
# written June 11 2010
# requirements:
# sudo apt-get install libmail-mbox-messageparser-perl libmail-mboxparser-perl

use strict;
use Mail::Mbox::MessageParser;

# for now, we are forwarding to local machine.
# later we will send to testsmtp@wustl.edu, which will forward back to this machine, to go through the ironports

my %settings = (
#sendto 		=> 'testsmtp@freshet.nts.wustl.edu',	# address to test local delivery
sendto 		=> 'ironporttest@wustl.edu',	# address to test sending mail to (ironporttest@wustl.edu)
replyto		=> 'testsmtp@freshet.nts.wustl.edu',
subject		=> 'SMTP RTT Test Email from freshet.nts.wustl.edu',
uuidgen		=> `which uuidgen`,	# path to uuidgen
#sendmail	=> `which sendmail`,	# path to sendmail
sendmail	=> '/usr/sbin/sendmail',	# path to sendmail
mailfile	=> "/var/mail/testsmtp",	# where the mailbox is stored
maxwait		=> 300			# maximum amount of time to wait for delivery, in seconds
);

chomp $settings{uuidgen};
chomp $settings{sendmail};

# here is a stock message to inject into the mailbox if the mailbox is empty
my $fakemessage=q(
From fakeymcfakerson@thisperlscript.edu  Fri Jun 11 11:04:37 2010
Return-Path: <testsmtp@freshet.nts.wustl.edu>
Received: from mcfeely.wustl.edu (mcfeely.wustl.edu [128.252.29.1])
	by freshet.nts.wustl.edu (8.14.2/8.14.2/Debian-2build1) with ESMTP id o5BG4Zul008469
	for <testsmtp@freshet.nts.wustl.edu>; Fri, 11 Jun 2010 11:04:36 -0500
Received: from freshet.nts.wustl.edu ([128.252.28.58])
  by mcfeely.wustl.edu with ESMTP; 11 Jun 2010 11:04:35 -0500
Received: from freshet.nts.wustl.edu (localhost [127.0.0.1])
	by freshet.nts.wustl.edu (8.14.2/8.14.2/Debian-2build1) with ESMTP id o5BG4ZmI008466
	for <ironporttest@wustl.edu>; Fri, 11 Jun 2010 11:04:35 -0500
Received: (from testsmtp@localhost)
	by freshet.nts.wustl.edu (8.14.2/8.14.2/Submit) id o5BG4XoS008465;
	Fri, 11 Jun 2010 11:04:33 -0500
Date: Fri, 11 Jun 2010 11:04:33 -0500
Message-Id: <201006111604.o5BG4XoS008465@freshet.nts.wustl.edu>
Reply-to: testsmtp@freshet.nts.wustl.edu
Subject: FAKE MESSAGE from Ironport Test Script
To: ironporttest@wustl.edu
From: testsmtp@freshet.nts.wustl.edu
Content-type: text/plain

This message is FAKE! It was injected into the inbox because it was empty at runtime.

);

my $uuid = `$settings{uuidgen} -t`;
chomp $uuid;

sub print_settings{
  foreach my $keys (keys %settings) {
    print STDERR "settings[$keys] -> $settings{$keys}\n";
  }
}

#print_settings();

my $start_time = time();
print STDERR "Sending mail at $start_time...\n";

open SENDMAIL, "|$settings{sendmail} -t" or die "Cant open pipe to sendmail: $!";
print SENDMAIL "Reply-to: $settings{replyto}\n";
print SENDMAIL "Subject: $settings{subject} $uuid\n";
print SENDMAIL "To: $settings{sendto}\n";
print SENDMAIL "From: $settings{replyto}\n";
print SENDMAIL "Content-type: text/plain\n\n";
print SENDMAIL "$uuid";
close SENDMAIL;

print STDERR "Closed connection to sendmail\n";

# first, open up inbox and if it is empty, put some mail in it
if (-z $settings{mailfile}) {
  print STDERR "zero size mailfile detected, injecting fake email :)\n"; 
  open MAILBOX,'>',$settings{mailfile} or die "$settings{mailfile}: $!";
  print MAILBOX $fakemessage;
  close MAILBOX;
}


# make a messageparser to look through our mbox
my $fh = new FileHandle($settings{mailfile});
Mail::Mbox::MessageParser::SETUP_CACHE( { 'file_name' => "/home/testsmtp/cache" } );
my $mboxreader = new Mail::Mbox::MessageParser( {
		'file_name' => $settings{mailfile},
		'file_handle' => $fh,
		'enable_grep' => 1,
		#'debug' => 1,
		'force_processing' => 1,
} );

die $mboxreader unless ref $mboxreader; # this dies if the inbox is empty. we dont want, but we dont have much of a choice

my $found = 0;	# have we found the message we are looking for yet?
my $timeout = 0;

while(not $found and not $timeout) {
  $mboxreader->end_of_file() and $mboxreader->reset() and sleep 1;	# if we read through the whole inbox, loop back over it
  my $email = $mboxreader->read_next_email();
  $$email =~ /Subject: $settings{subject} $uuid/g and print STDERR "Received message $uuid\n" and $found = 1;
  my $time_passed = time() - $start_time;
  ($time_passed > $settings{maxwait} and not $found) and print STDERR "Timeout waiting for mail to arrive, aborting.\n" and $timeout=1;
}

my $end_time  = time();

if ($found and not $timeout) {
  print STDERR "Received mail at $end_time...\n";
  my $rtt_s = $end_time - $start_time;
  print STDERR "Total RTT is $rtt_s\n";
  print "$rtt_s\n";
} else { 	# timeout, cause we cant possibly timeout if we found it
  print STDERR "Mail timeout at $end_time\n";
  print STDERR "Total RTT is -1\n";
  print -1,"\n";
}

