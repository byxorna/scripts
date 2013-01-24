#!/usr/bin/perl
# script to allow me to tether my android phone via ADB without rooting with azilink
# written Apr 26 2010
use strict;

# requirements: openvpn, android adb
# this should start up the tethering on the computer. You should enable azilink on the phone.

#TODO: make script check for root, and then respawn as root
# TODO: add check for running as root, and prompt
# TODO add preventing changes to resolv from Network manager??? maybe???
# TODO unforward adb connections

my $scriptname = "start_tethering.sh";
my $vpnconfig = "dev tun\n remote 127.0.0.1 41927 tcp-client\n ifconfig 192.168.56.2 192.168.56.1\n route 0.0.0.0 128.0.0.0\n route 128.0.0.0 128.0.0.0\n socket-flags TCP_NODELAY\n #keepalive 10 30\n ping 10\n dhcp-option DNS 192.168.56.1\n";
my $resolv_conf = "nameserver 192.168.56.1";
my $udevrules = 'SUBSYSTEM=="usb", SYSFS{idVendor}=="0bb4", MODE="0666"';
my $udevrules_target = "/etc/udev/rules.d/51-android.rules";

# check for notify-send, to spice things up :)
my $notify_bin = `which notify-send`;
chomp $notify_bin;
if (-x $notify_bin) {
  # yay, we can notify!
  #print "Libnotify found...\n";
} else {
  #print "No libnotify found\n";
  undef $notify_bin;
}

sub getdate(){
  my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
  my $year = 1900 + $yearOffset;
  return "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
}

print "Starting android tethering\n";
(defined $notify_bin) and system("'$notify_bin' 'Configuring phone tethering...'");

####### perform checks before doing anything ######

print "Checking for android udev rules... ";
if (-f $udevrules_target && -r _ ) {
  print "ok\n";
} else {
  print "failed\n";
  print ":: Installing udev rules to $udevrules_target... ";
  open UDEVRULE, ">", $udevrules_target or die "failed!\n:: ERROR opening $udevrules_target for writing, aborting!\n$!";
  print UDEVRULE "#Created by $scriptname on ",getdate(),"\n";
  print UDEVRULE "$udevrules\n";
  # dont forget to set the correct permissions root:root
  close UDEVRULE;
  print "ok\n";
}

# check for openvpn
print "Checking for openvpn... ";
my $openvpn_path = `which openvpn`;
chomp $openvpn_path;
$? != 0 and die ":: ERROR finding the openvpn binary in your \$PATH!" or print "ok\n";

# check for adb
print "Checking for android adb... ";
my $adb_path = `which adb`;
chomp $adb_path;
if ($? != 0) {
  # try /opt/android-sdk/tools/adb
  if (-x "/opt/android-sdk/tools/adb"){
    $adb_path = "/opt/android-sdk/tools/adb";
  } else {
    die ":: ERROR finding the adb binary in your \$PATH!";
  }
}
print "ok\n";

# prompt for device if not present, tell them to start azilink
my $devfound = 0;
while ($devfound == 0){
  print "Checking for device... ";
  my $device_scan = `$adb_path devices`;
  my @lines=split(/\n/,$device_scan);
  for my $line (@lines) { 
    if ($line =~ /^(\w+)\s+(\w+)$/) {
      print "ok ($1: $2)\n";
      $devfound = 1;
    }
    ($devfound == 1) and last;
  }
  if ($devfound == 0){
    print "failed\n";
    print ":: ERROR could not find a phone plugged in with \`adb devices\`\n";
    print "Press ENTER when you have plugged in your phone:";
    (defined $notify_bin) and system("'$notify_bin' -u critical 'I could not find your phone. Is it plugged in?'");
    (my $input = <>);
  }
}

##### now start the tethering #####

# start adb forwarding
print "Forwarding connections... ";
my $adb_status = system("$adb_path forward tcp:41927 tcp:41927");
($adb_status != 0) and die ":: ERROR forwarding connection to phone.";
print "ok\n";

# configure resolver
print "Configuring DNS resolution... ";
open RESOLV,"<","/etc/resolv.conf" or die ":: ERROR opening /etc/resolv.conf to read current DNS settings!";
my @dns_config_orig = <RESOLV>;	# save the original DNS settings for when the connection terminates
close RESOLV;

open RESOLV,">","/etc/resolv.conf" or die ":: ERROR opening /etc/resolv.conf to change DNS resolution!";
print RESOLV "$resolv_conf\n";
close RESOLV;
print "ok\n";

# start openvpn
print "Starting the VPN... ";
(defined $notify_bin) and system("'$notify_bin' 'Starting tether: Please turn on Azilink on your phone'");
system("printf  '$vpnconfig' | cat - > /tmp/openvpn.config ; $openvpn_path --config /tmp/openvpn.config");
print "\nCaught signal, cleaning up\n";
(defined $notify_bin) and system("'$notify_bin' 'Terminating tether...'");

print "Restoring original DNS settings... ";
open RESOLV,">","/etc/resolv.conf" or die ":: ERROR opening /etc/resolv.conf to change DNS settings back to original!";
for (@dns_config_orig) { print RESOLV $_; }
close RESOLV;
print "ok\n";
(defined $notify_bin) and system("'$notify_bin' 'Disconnected sucessfully'");




