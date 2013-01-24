#!/usr/bin/perl -w
# written Apr 26 2010
#use strict;

#############################
#
# this script checks the md array
# and emails if the array has
# been degraded
#
#############################
#
# ---{ sample output needed to be parsed }---
#gc2@barnaby:~$ cat /proc/mdstat 
#Personalities : [linear] [multipath] [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
#md0 : active raid5 sda1[0] sdg1[7](S) sdh1[6] sdf1[5] sde1[4] sdd1[3] sdc1[2] sdb1[1]
#      8790815616 blocks level 5, 64k chunk, algorithm 2 [7/7] [UUUUUUU]
#      
#unused devices: <none>

# build the list of mounted md devices
my @mount=`mount`;
my @mddevs;
foreach (@mount) {
  if ( /^\/dev\/md.*$/ ) {
    chomp (my $temp=$_);
    push(@mddevs,$temp);
  }
}
@mddevs=sort(@mddevs);  # devices managed by MDraid from mount


# now get the md disk statuses
open(FH,"/proc/mdstat");
#open(FH,"/home/gc2/testmd");
my @mdstat=<FH>;
close(FH);
shift @mdstat;    # get rid of "^Personalities"
pop @mdstat;    # get rid of unused devices lines

for ($i=0; $i < scalar @mdstat; $i++) {
  if ( $mdstat[$i] =~ /^md\d+.*$/ ){
    my $temp1 = $mdstat[$i++];    # grab this line, and jump to the next
    my $temp2 = $mdstat[$i++];    # grab the next line, and skip the empty line
    chomp $temp1;
    chomp $temp2;

    push (@othermd,$temp1 . $temp2 );  # push both lines as one
  }
}
@mdstat = sort @othermd;

##############################################################
#
#
#  now determine for each md, its active members, if it has failed
#  which disk failed, and where the mounted md is in the FS
# and suggest a method to recover
#
#
##############################################################

my $sendemail=0;
my $numofarrays = scalar @mdstat;
my $failuremessage="";

# loop over all meta disks looking for failures
for (my $i=0; $i < $numofarrays; $i++){
  my $numfailures = 0;  # number of failed disks
  my @faileddisks;
  my $numinarray;
  my $numrunning;
  my $numfailed;
  my $metadisk;
  my $mountedon;
  my @status;  # for UUUU
  my @disks;  # partitions on this metadisk

  $mdstat[$i] =~ /^(md\d+).*$/ and $metadisk = $1;    # what metadisk are we working on?
  $mddevs[$i] =~ /on\s([\/|\w]+).*$/ and $mountedon = $1;  # where is the metadisk mounted?
  $mdstat[$i] =~ /\[(\w+)\]$/ and @status=split(//,$1);  # split up the disk statuses into @status
  $mdstat[$i] =~ /((sd[[:alpha:]]\d\[\d\](\(F\))?\s+)+).*$/ and @disks = split(/\s/, $1);  # splits up disks into @disks
  $mdstat[$i] =~ /\[(\d+)\/(\d+)\]\s\[\w+\]/
    and $numinarray=$1     # figure out number of disks and running ones
    and $numrunning=$2
    and $numfailed= $numinarray-$numrunning;


  $failuremessage .= "################ $metadisk on $mountedon status ################\n";
  $failuremessage .= "$numinarray disks in $metadisk, $numrunning running, $numfailed failed\n";
  $failuremessage .= join "\t",@disks,"\n";
  $failuremessage .= join "\t",@status,"\n\n";


  for ( my $i=0; $i < scalar @disks; $i++) {    # loop over disks in array
    if (not $status[$i] =~ /U/) {      # check if disk is not ok (not == 'U')
      push (@faileddisks,$disks[$i]);  # push the disk label that has failed onto the array
      $numfailures++;
    }
  }
  if ($numfailed > 0){ $sendemail=1 ; }    # send email if there is one problem
  if ($numfailed > 0) {
    $failuremessage .= "!!! array $metadisk mounted on $mountedon has suffered $numfailures failure[s]: ".join (" ",@faileddisks)." !!!\n";
    $failuremessage .= "RUN THIS TO RECOVER:\n\n";
    foreach $failure (@faileddisks) {
      my $volume;
      my $partition;
      if ($failure =~ /([[:alpha:]]+)(\d)\[\d\](\(F\))?$/){
        $volume = $1;
        $partition = $2;

#####################
# calculate difference in failed disks and alive disks
#####################
        my @inter;
        my @diff;
        foreach my $element (@faileddisks, @disks) {
          $count{$element}++;
        };
        foreach my $element (keys %count) {
          push @{ $count{$element} > 1 ? \@inter : \@diff }, $element;
        };
####################
# end difference
####################
        if (scalar @diff > 0){
          $failuremessage .= "mdmadm --manage /dev/$metadisk --fail /dev/$volume$partition\n";
          $failuremessage .= "mdmadm --manage /dev/$metadisk --remove /dev/$volume$partition\n";
          $failuremessage .= "# fail and remove other partitions associated with /dev/$volume>\n";
          $failuremessage .= "# remove the failed drive, and replace it.>\n";
          $diff[0] =~ /([[:alpha:]]+)\d/ and $t = $1;    # grab a non failed drive handle
          $failuremessage .= "sfdisk -d /dev/$t | sfdisk /dev/$volume\n";
          $failuremessage .= "mdmadm --manage /dev/$metadisk --add /dev/$volume$partition\n";
          $failuremessage .= "# repeat, adding other partitons to their respective metadisk arrays>\n";
          $failuremessage .= "cat /proc/mdstat\n";

        } else {
          $failuremessage .= "no unfailed disks exist with which to copy the formatting from. this is BAD.\n"

        }

        $failuremessage .= "\n";
      }
    }
  }
}

if ($sendemail != 0) {    # send an email! degraded array 
  my $date = time();
  open FAILURE,'>',"/tmp/$date-diskfailure";
  print FAILURE $failuremessage;
  close FAILURE;
  `mail -s "!!! DISK FAILURE !!! on skillet.nts.wustl.edu" unixadmins\@list.wustl.edu < /tmp/$date-diskfailure`;
  print "$failuremessage\n";
  exit 2;

} else {     # everything is groovy
  exit 0;
}




