#!/usr/bin/perl 
# script to look up vendor of a MAC
# written Jan 21 2010
use strict;
use Net::MAC::Vendor;

my %vendors = (
'AGERE SYSTEMS',				'AGERE SYSTEMS',
'APPLE COMPUTER',				'APPLE',
'APPLE COMPUTER INC',				'APPLE',
'APPLE COMPUTER INC.',				'APPLE',
'APPLE COMPUTER, INC.',				'APPLE',
'APPLE, INC',					'APPLE',
'APPLE, INC.',					'APPLE',
'ARCADYAN TECHNOLOGY CORPORATION',		'ARCADYAN TECH',
'ASKEY  COMPUTER  CORP',			'ASKEY COMPUTER',
'ASKEY COMPUTER',				'ASKEY COMPUTER',
'ASKEY COMPUTER CORP',				'ASKEY COMPUTER',
'ASKEY COMPUTER CORP.',				'ASKEY COMPUTER',
'ASUSTEK COMPUTER INC.',			'ASKEY COMPUTER',
'AZUREWAVE TECHNOLOGIES (SHANGHAI) INC.',	'AZUREWAVE TECH',
'AZUREWAVE TECHNOLOGIES, INC',			'AZUREWAVE TECH',
'AZUREWAVE TECHNOLOGIES, INC.',			'AZUREWAVE TECH',
'BELKIN INTERNATIONAL INC.',			'BELKIN',
'CC&C TECHNOLOGIES, INC.',			'CC&C TECH',
'CISCO SYSTEMS, INC.', 				'CISCO/LINKSYS',
'CISCO-LINKSYS LLC',				'CISCO/LINKSYS',
'D-LINK CORPORATION',				'D-LINK',
'EASTMAN KODAK COMPANY',			'KODAK',
'EDIMAX TECHNOLOGY CO. LTD.',			'EDIMAX',
'GEMTEK TECHNOLOGY CO., LTD.',			'GEMTEK',
'GVC CORPORATION',				'GVC',
'HIGH TECH COMPUTER CORP',			'HIGH TECH',
'HON HAI PRECISION IND. CO., LTD',		'HON HAI',
'HON HAI PRECISION IND. CO., LTD.',		'HON HAI',
'HON HAI PRECISION IND. CO.,LTD.',		'HON HAI',
'HON HAI PRECISION IND.CO., LTD.',		'HON HAI',
'HON HAI PRECISION IND.CO.,LTD.',		'HON HAI',
'INTEL CORP',					'INTEL',
'INTEL CORPORATE',				'INTEL',
'INTEL CORPORATION',				'INTEL',
'LITE-ON TECHNOLOGY CORP.',			'LITE-ON',
'LITEON TECHNOLOGY CORPORATION',		'LITE-ON',
'MICRO-STAR INT\'L CO.,LTD.',			'MSI',
'MICRO-STAR INTERNATIONAL CO., LTD.',		'MSI',
'NETGEAR INC.',					'NETGEAR',
'NOKIA DANMARK A/S',				'NOKIA',
'PHILIPS',					'PHILIPS',
'PRIVATE',					'PRIVATE',
'QUANTA MICROSYSTEMS, INC.',			'QUANTA',
'RESEARCH IN MOTION',				'RIM',
'RESEARCH IN MOTION LIMITED',			'RIM',
'RIM',						'RIM',
'RIM TESTING SERVICES',				'RIM',
'SOLOMON EXTREME INTERNATIONAL LTD.',		'SOLOMON EXTREME',
'SYCHIP INC.',					'SYCHIP',
'XEROX CORPORATION',				'XEROX'
);

sub get_mac_oui {
	my $mac = shift;
	my $refarray = Net::MAC::Vendor::lookup($mac);
	my ($oui) = @$refarray;
	chomp $oui;
	return $oui;
}

sub get_mac_vendor {
	my $mac = shift;
	my $refarray = Net::MAC::Vendor::lookup($mac);
	shift @$refarray;
	my ($vendor) = @$refarray;
	chomp $vendor;
	return $vendor;
}

sub get_mac_oui_vendor {
	my $mac = shift;
	my $refarray = Net::MAC::Vendor::lookup($mac);
	my ($oui,$vendor) = @$refarray;
	chomp($oui,$vendor);
	return ($oui,$vendor);
}

$ARGV[0] or die "I need a MAC address to work on! (- or : separated plzkthxbai.)";
my ($oui,$vendor) = get_mac_oui_vendor($ARGV[0]);
if (-r $ARGV[0]) {	# then the argument is a file, so the while loop over the addresses
	open(FILE,"$ARGV[0]");
	while (<FILE>) {
		chomp(my $mac = $_);
		my $oui = get_mac_oui($mac);
		$oui =~ tr/a-z/A-Z/;
		unless ($vendors{$oui}) {
			$vendors{$oui} = $oui ;
		}
		print "$vendors{$oui}\n";
	}
	close FILE;
} else {
	my ($oui) = get_mac_oui_vendor($ARGV[0]);
	print $oui,"\n";
	#print "$vendors{$oui}\n";
}
