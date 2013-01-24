#!/usr/bin/perl

# so basically, run this file, and it outputs cacti readable file to /tmp. Then you need to externally copy them to a cacti machine
# where a script will grab them and give them to cacti to graph


# where does the named.stats file live?
#$stats_file = "/export/named/named.stats";
$stats_file = "./named-appl.stats";
$temp_stats_file = "./named-appl.stats";
#$temp_stats_file = "/tmp/named.stats";
$rndc_command = "/export/bin/rndc";
$temp_dir = "/tmp";

$hostname = qx(hostname);
chomp($hostname);


# runs the rndc stats
sub runstats {
	@rndc = ($rndc_command,"stats");
	system(@rndc) == 0 or die "ERROR running $rndc_command stats!!!\n";
}



# copies stats into temp
sub copystats {
	@copy = ("cp",$stats_file,$temp_stats_file);
	system(@copy) == 0 or die "ERROR copying $stats_file to $temp_stats_file!!!\n";
}


# returns hash of parsed stats
sub parsestats {
	# all values are stored here, by their key = $headers[x]
	my %values;

	open STATS,'<',$temp_stats_file or die $!, "could not open stats file";
	local $/; # slurp up file
	my $string = <STATS>;
	close STATS;
	@sections = split(/[\+\-]+\s[\s\w]+\s+[\+\-]+.*/m,$string);
	local $/ = "\n";
	
	# assign out sections to each name
	@incomingrequests = 	split(/\n/,$sections[2]);
	@incomingqueries = 	split(/\n/,$sections[3]);
	@outgoingqueries = 	split(/\n/,$sections[4]);
	@serverstats = 		split(/\n/,$sections[5]);
	@zonemaintenance = 	split(/\n/,$sections[6]);
	@resolverstats =  	split(/\n/,$sections[7]);

	#these hashes will hold the description and values
	my $in_req = "";
	my $in_que;
	my $out_que;
	my $serv_stats;
	my $zone_maint;
	my $res_stats;


#print "== incoming req ==\n";

	foreach my $line (@incomingrequests){
		if ($line =~ /\s+(\d+)\s([\w\s]+)/) {
			#$2 =~ s/\s//g;
			($num,$temp) = ($1,$2);
			$temp =~ s/\s//g;
			$in_req = $in_req."$temp:$num ";
		}
	}
	# print out line to the file
	$in_req = $in_req."\n";
#	print $in_req;
	open FH,'>',$temp_dir."/dns-stats-incoming-requests".".$hostname" or die "ERROR opening file for writing!".$!;
	print FH $in_req;
	close FH;
	
#print "== incoming q ==\n";
	foreach my $line (@incomingqueries){
		if ($line =~ /\s+(\d+)\s([\w\s]+)/) {
			#$2 =~ s/\s//g;
			($num,$temp) = ($1,$2);
			$temp =~ s/\s//g;
			$in_que = $in_que."$temp:$num ";
		}
	}	

	# print out line to the file
	$in_que = $in_que."\n";
#	print $in_que;
	open FH,'>',$temp_dir."/dns-stats-incoming-queries".".$hostname"  or die "ERROR opening file for writing!".$!;
	print FH $in_que;
	close FH;

#print "\n";
#print "== outgoing q ==\n";

	foreach my $line (@outgoingqueries){
		if ($line =~ /\s+(\d+)\s([\w\s]+)/) {
			#$2 =~ s/\s//g;
			($num,$temp) = ($1,$2);
			$temp =~ s/\s//g;
			$out_que = $out_que."$temp:$num ";
		}
	}	
	# print out line to the file
	$out_que = $out_que."\n";
#	print $out_que;
	open FH,'>',$temp_dir."/dns-stats-outgoing-queries".".$hostname"  or die "ERROR opening file for writing!".$!;
	print FH $out_que;
	close FH;

#print "\n";
#print "== server stats ==\n";

	foreach my $line (@serverstats){
		if ($line =~ /\s+(\d+)\s([\w\s]+)/) {
			($num,$temp) = ($1,$2);
			$temp =~ s/\s//g;
			$serv_stats = $serv_stats."$temp:$num ";
			
		}
	}	
	# print out line to the file
	$serv_stats = $serv_stats."\n";
#	print $serv_stats;
	open FH,'>',$temp_dir."/dns-stats-server-stats".".$hostname"  or die "ERROR opening file for writing!".$!;
	print FH $serv_stats;
	close FH;

#print "\n";
#print "== zone maintenance ==\n";

	foreach my $line (@zonemaintenance){
		if ($line =~ /\s+(\d+)\s([\w\s]+)/) {
			($num,$temp) = ($1,$2);
			$temp =~ s/\s//g;
			$zone_maint = $zone_maint."$temp:$num ";
		}
	}	
	# print out line to the file
	$zone_maint = $zone_maint."\n";
#	print $zone_maint;
	open FH,'>',$temp_dir."/dns-stats-zone-maintanence".".$hostname"  or die "ERROR opening file for writing!".$!;
	print FH $zone_maint;
	close FH;
#print "\n";
#print "== resolver stats ==\n";

	foreach my $line (@resolverstats){
		if ($line =~ /\s+(\d+)\s([\w\s]+)/) {
			($num,$temp) = ($1,$2);
			$temp =~ s/\s//g;
			$res_stats = $res_stats."$temp:$num ";
		}
	}
	# print out line to the file
	$res_stats = $res_stats."\n";
#	print $res_stats;
	open FH,'>',$temp_dir."/dns-stats-resolver-stats".".$hostname"  or die "ERROR opening file for writing!".$!;
	print FH $res_stats;
	close FH;
#print "\n";

}


# first remove the old named.stats, because it just appends to it. >:o
if (-e $stats_file) {
	print "removing old $stats_file...\n";
	my $status = unlink($stats_file);
	($status != 1) and die"ERROR unlinking $stats_file, aborting! your named.stats is going to be appended to.\n";
}



#runstats();
#copystats();
parsestats();



