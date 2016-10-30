#!/usr/bin/perl -w
use MIME::Base64;
#use MIME::Base91; # We're doing this locally here. Base91 has no standard lib in CPAN

use Data::Dumper qw(Dumper);
use Ham::APRS::IS;
use Ham::APRS::FAP qw(parseaprs);
use LWP::UserAgent;
use DateTime;
use DateTime::Format::RFC3339;
use Digest::SHA qw(sha256_hex);
use Digest::CRC qw(crcccitt crc32);
use Config;

#my $SSDV_RS_EXE = "/home/thomas/bin/reed-solomon/ssdv_rs";

my @b91_enctab = (
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
	'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
	'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
	'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '!', '#', '$',
	'%', '&', '(', ')', '*', '+', ',', '.', '/', ':', ';', '<', '=',
	'>', '?', '@', '[', ']', '^', '_', '`', '{', '|', '}', '~', '"'
);

my %b91_dectab;
for (my $i = 0; $i < @b91_enctab; ++$i) {
	$b91_dectab{$b91_enctab[$i]} = $i;
}

my $decoded = "";
my $base64encoded = "";
my @datapoints = ();
my $ssdv_sync_byte = 0x55;

for (;;) {
	my $l = <STDIN>;
# for debug
#$l = '[0.1] DO7EN-11>APECAN:{{IiMVx/?CAC"bFCAAAdpX&R$unq8C}v#d.pT=Uj(Ki=W>KZob@#F[AWtDt5X2%5HpY1VFyPX&BsGe$VQA+:@i&,<p$j/K&j(L[4@10M0Li5OPnYes$`8tf1PkwKuqE{5)r>,~i0GF+agPg;RM!<:.=Mn4G2]GKePGBm]D,9veJzpG1x8r=O9+!9+:;3lN@A:apct;,}gBs_/05wLXQ}O6AFFu2m&[IYl]QmyqA>=ql8;ya_u]O[1d5.c"Cs?|!YN{Tl7u.^ck2UA6ZB';

#	$l = 'DL7AD-12>APECAN,qAR,DL7AD:{{I)GBl*`DAC"bFAAAA)kQ&X/YDNbr*?3^e$xso6.yl%?$coT`_gUX83J)NJ.^`3q?1*Ln"3+s|)#tfekx=/I<4IfCUQ8hi]p;FwRxbf|}8@0=I>2}HAj6L45Yl,sT:cMC_]mGnrN"nr][zT@8bqIo@:<R{Xk#FPZ{48rpFAjhdu>l$|j4)5I[^l2KI3Eu9}0e+tb53z@U;1?72voQ,pr&[rpvCKKwdWvC&1)qCC9Z][gAyxxand;;yBA34TtnwqkP*:v??qRz.u+C<M';
	next if (!defined $l);
	print "\n--- new packet ---\n$l\n";

    # If custom packet is recognized, decode with special parser
	if ($l =~ /\:\{\{I/) { # recognize custom ssdv packet by the substring ":{{I"
		# parse custom packet 
		my ($path_string, $payload) = split /\{\{(.+)?/, $l;
		my ($callsign_balloon, @callsign_path) = split(/>/, $path_string);
		$payload =~ s/^I//; # get rid of the ssdv identifier "I" at the start of the line.

		
		print "Custom ssdv packet found:\n";
		print "Path: $path_string\n";
		my $len = length($payload);
		print "Payload: $payload (Base91 encoded) (length = $len)\n";

		# decrypt Base91
		$decoded = decode_base91($payload);
		
		my $crc = crc32($decoded); #integer number
		my $crchex = sprintf('%08X', $crc); #hex representation of $crc in a string
		my $crcbin = pack('H8', $crchex); # binary representation of crc. Does this really need to be this complicated? hmpf...
		my $decoded_crc = $decoded . $crcbin;
		#my $ssdv_rs = `$SSDV_RS_EXE -c $decoded_crc`;
		
		my $unencrypted_packet = chr($ssdv_sync_byte) . $decoded_crc ; #. $ssdv_rs;
 
		$base64encoded = encode_base64($unencrypted_packet);
		$base64encoded =~ s/\n//g; #remove last <cr> produced by encode_base64()

		$len = length($decoded);
		print "\n\ndecoded payload in hex: (length = $len)\n";
 
        my @dec_ary1 = split //, $decoded;
		#print Dumper \@dec_ary;
		foreach $i (@dec_ary1)
		{
			my $ii = sprintf('%02X', ord($i));
			print "$ii,";
		}
		print "\n";

		$len = length($crcbin);
		print "\n\nCRC32 in hex: (length = $len)\n";
		my @dec_ary2 = split //, $crcbin;
		#print Dumper \@dec_ary;
		foreach $i (@dec_ary2)
		{
			my $ii = sprintf('%02X', ord($i));
			print "$ii,";
		}
		print "\n";

		$len = length($decoded_crc);
		print "\n\ndecoded payload + crc in hex: (length = $len)\n";
		my @dec_ary3 = split //, $decoded_crc;
		#print Dumper \@dec_ary;
		foreach $i (@dec_ary3)
		{
			my $ii = sprintf('%02X', ord($i));
			print "$ii,";
		}
		print "\n";

		$len = length($unencrypted_packet);
		print "\n\nssdv_sync_byte + decoded payload + crc + fec in hex: (length = $len)\n";
		my @dec_ary4 = split //, $unencrypted_packet;
		#print Dumper \@dec_ary;
		foreach $i (@dec_ary4)
		{
			my $ii = sprintf('%02X', ord($i));
			print "$ii,";
		}
		print "\n";
        
		my $last_path = $callsign_path[-1];
		my @last_path_elements = split(',', $last_path);
		my $receiver_callsign = "APRS/" . $last_path_elements[-1];
		$receiver_callsign =~ s/:$//;
		print "receiver_callsign = $receiver_callsign\n";

		# Post the ssdv packet to ssdv.habhub.org
        post2ssdv($receiver_callsign, $base64encoded);

	} else {

		# decoding with FAP
      
		my %packetdata;
		my $retval = parseaprs($l, \%packetdata);
		 
		if ($retval == 1) {
			while (my ($key, $value) = each(%packetdata)) {
				if ($key =~ m/digipeaters/) {

					print "Digis: (\n";
					# print Dumper \$value;
					#split digis
					foreach my $digi (@$value) {
						print "\tDigi: $digi->{call} $digi->{wasdigied}\n";
					}
					print ")\n";
				} else {
					print "$key: $value\n";
				}
			}

		} else {
	#		warn "Parsing failed: $packetdata{resultmsg} ($packetdata{resultcode})\n";
			warn "Parsing failed: Result code: ($packetdata{resultcode})\n";
		}
	}
}
  
$is->disconnect() || die "Failed to disconnect: $is->{error}";
exit 0;

######################################################################################################
sub post2ssdv
{
	my ($receiver_callsign, $payload) = @_;
	my $ua = LWP::UserAgent->new;
	my $f = DateTime::Format::RFC3339->new();

	my $server_base_url = "http://ssdv.habhub.org/api/v0/packets";
	#my $server_base_url = "http://192.168.2.13/packets.php";
	my $dt = DateTime->now;

#		#Write log file
#		open(my $fh, '>>', 'pecan.log');
#		print $fh "$raw_telemetry_data";
#		close $fh;

	# Format for ssdv.habhub.org

	$dt = DateTime->now;
	$RFC3339_timestamp = $f->format_datetime($dt);


	print "server_base_url = $server_base_url\n";
	print "RFC3339_timestamp = $RFC3339_timestamp\n";

	# set custom HTTP request header fields
	my $req = HTTP::Request->new(POST => $server_base_url);
	$req->header('content-type' => 'application/json');
	 
	# add POST data to HTTP request body
	my $post_data = "{
		\"type\": \"packet\", 
		\"packet\": \"$payload\", 
		\"encoding\": \"base64\", 
		\"received\": \"$RFC3339_timestamp\", 
		\"receiver\": \"$receiver_callsign\", 
		\"fixes\": 0
	}";


	print "post_data = $post_data\n";

	$req->content($post_data);

	# Send data to habitat
	my $resp = $ua->request($req);
	print $resp,"\n";
    if ($resp->is_success) {
		print "get request code:\n";
        my $message = $resp->decoded_content;
		print "Received reply: $message\n";
	}
	else {
		print "HTTP POST error code: ", $resp->code, "\n";
		print "HTTP POST error message: ", $resp->message, "\n";
	}
    print "ready...";
}

sub decode_base91 {
	my @d = split(//,shift(@_));
	my $v = -1;
	my $b = 0;
	my $n = 0;
	my $o;
	my $c;

	for (my $i = 0; $i < @d; ++$i) {
		$c = $b91_dectab{$d[$i]};
		if(!defined($c)){
			next;
		}
		if ($v < 0){
			$v = $c;
		}else{
			$v += $c * 91;
			$b |= ($v << $n);
			$n += ($v & 8191) > 88 ? 13 : 14;
			do {
				$o .= chr($b & 255);
				$b >>= 8;
				$n -= 8;
			} while ($n > 7);
			$v = -1;
		}
	}
	if($v + 1){
		$o .= chr(($b | $v << $n) & 255);
	}
	return $o;
}

sub encode_base91 {
	my @d = split(//,shift(@_));
	my $b = 0;
	my $n = 0;
	my $o;
	my $v;

	for (my $i = 0; $i < @d; ++$i) {
		$b |= ord($d[$i]) << $n;
		$n += 8;
		if($n > 13){
			$v = $b & 8191;
			if ($v > 88){
				$b >>= 13;
				$n -= 13;
			}else{
				$v = $b & 16383;
				$b >>= 14;
				$n -= 14;
			}
			$o .= $b91_enctab[$v % 91] . $b91_enctab[$v / 91];
		}
	}
	if($n){
		$o .= $b91_enctab[$b % 91];
		if ($n > 7 || $b > 90){
			$o .= $b91_enctab[$b / 91];
		}
	}
	return $o;
}

sub encode_rs_8
{
	my ($data) = @_;
	my $parity = "";
	my $pad = 0;

	my @ALPHA_TO = (
		0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80,0x87,0x89,0x95,0xAD,0xDD,0x3D,0x7A,0xF4,
		0x6F,0xDE,0x3B,0x76,0xEC,0x5F,0xBE,0xFB,0x71,0xE2,0x43,0x86,0x8B,0x91,0xA5,0xCD,
		0x1D,0x3A,0x74,0xE8,0x57,0xAE,0xDB,0x31,0x62,0xC4,0x0F,0x1E,0x3C,0x78,0xF0,0x67,
		0xCE,0x1B,0x36,0x6C,0xD8,0x37,0x6E,0xDC,0x3F,0x7E,0xFC,0x7F,0xFE,0x7B,0xF6,0x6B,
		0xD6,0x2B,0x56,0xAC,0xDF,0x39,0x72,0xE4,0x4F,0x9E,0xBB,0xF1,0x65,0xCA,0x13,0x26,
		0x4C,0x98,0xB7,0xE9,0x55,0xAA,0xD3,0x21,0x42,0x84,0x8F,0x99,0xB5,0xED,0x5D,0xBA,
		0xF3,0x61,0xC2,0x03,0x06,0x0C,0x18,0x30,0x60,0xC0,0x07,0x0E,0x1C,0x38,0x70,0xE0,
		0x47,0x8E,0x9B,0xB1,0xE5,0x4D,0x9A,0xB3,0xE1,0x45,0x8A,0x93,0xA1,0xC5,0x0D,0x1A,
		0x34,0x68,0xD0,0x27,0x4E,0x9C,0xBF,0xF9,0x75,0xEA,0x53,0xA6,0xCB,0x11,0x22,0x44,
		0x88,0x97,0xA9,0xD5,0x2D,0x5A,0xB4,0xEF,0x59,0xB2,0xE3,0x41,0x82,0x83,0x81,0x85,
		0x8D,0x9D,0xBD,0xFD,0x7D,0xFA,0x73,0xE6,0x4B,0x96,0xAB,0xD1,0x25,0x4A,0x94,0xAF,
		0xD9,0x35,0x6A,0xD4,0x2F,0x5E,0xBC,0xFF,0x79,0xF2,0x63,0xC6,0x0B,0x16,0x2C,0x58,
		0xB0,0xE7,0x49,0x92,0xA3,0xC1,0x05,0x0A,0x14,0x28,0x50,0xA0,0xC7,0x09,0x12,0x24,
		0x48,0x90,0xA7,0xC9,0x15,0x2A,0x54,0xA8,0xD7,0x29,0x52,0xA4,0xCF,0x19,0x32,0x64,
		0xC8,0x17,0x2E,0x5C,0xB8,0xF7,0x69,0xD2,0x23,0x46,0x8C,0x9F,0xB9,0xF5,0x6D,0xDA,
		0x33,0x66,0xCC,0x1F,0x3E,0x7C,0xF8,0x77,0xEE,0x5B,0xB6,0xEB,0x51,0xA2,0xC3,0x00
	);

	my @INDEX_OF = (
		0xFF,0x00,0x01,0x63,0x02,0xC6,0x64,0x6A,0x03,0xCD,0xC7,0xBC,0x65,0x7E,0x6B,0x2A,
		0x04,0x8D,0xCE,0x4E,0xC8,0xD4,0xBD,0xE1,0x66,0xDD,0x7F,0x31,0x6C,0x20,0x2B,0xF3,
		0x05,0x57,0x8E,0xE8,0xCF,0xAC,0x4F,0x83,0xC9,0xD9,0xD5,0x41,0xBE,0x94,0xE2,0xB4,
		0x67,0x27,0xDE,0xF0,0x80,0xB1,0x32,0x35,0x6D,0x45,0x21,0x12,0x2C,0x0D,0xF4,0x38,
		0x06,0x9B,0x58,0x1A,0x8F,0x79,0xE9,0x70,0xD0,0xC2,0xAD,0xA8,0x50,0x75,0x84,0x48,
		0xCA,0xFC,0xDA,0x8A,0xD6,0x54,0x42,0x24,0xBF,0x98,0x95,0xF9,0xE3,0x5E,0xB5,0x15,
		0x68,0x61,0x28,0xBA,0xDF,0x4C,0xF1,0x2F,0x81,0xE6,0xB2,0x3F,0x33,0xEE,0x36,0x10,
		0x6E,0x18,0x46,0xA6,0x22,0x88,0x13,0xF7,0x2D,0xB8,0x0E,0x3D,0xF5,0xA4,0x39,0x3B,
		0x07,0x9E,0x9C,0x9D,0x59,0x9F,0x1B,0x08,0x90,0x09,0x7A,0x1C,0xEA,0xA0,0x71,0x5A,
		0xD1,0x1D,0xC3,0x7B,0xAE,0x0A,0xA9,0x91,0x51,0x5B,0x76,0x72,0x85,0xA1,0x49,0xEB,
		0xCB,0x7C,0xFD,0xC4,0xDB,0x1E,0x8B,0xD2,0xD7,0x92,0x55,0xAA,0x43,0x0B,0x25,0xAF,
		0xC0,0x73,0x99,0x77,0x96,0x5C,0xFA,0x52,0xE4,0xEC,0x5F,0x4A,0xB6,0xA2,0x16,0x86,
		0x69,0xC5,0x62,0xFE,0x29,0x7D,0xBB,0xCC,0xE0,0xD3,0x4D,0x8C,0xF2,0x1F,0x30,0xDC,
		0x82,0xAB,0xE7,0x56,0xB3,0x93,0x40,0xD8,0x34,0xB0,0xEF,0x26,0x37,0x0C,0x11,0x44,
		0x6F,0x78,0x19,0x9A,0x47,0x74,0xA7,0xC1,0x23,0x53,0x89,0xFB,0x14,0x5D,0xF8,0x97,
		0x2E,0x4B,0xB9,0x60,0x0F,0xED,0x3E,0xE5,0xF6,0x87,0xA5,0x17,0x3A,0xA3,0x3C,0xB7
	);

	my @GENPOLY = (
		0x00,0xF9,0x3B,0x42,0x04,0x2B,0x7E,0xFB,0x61,0x1E,0x03,0xD5,0x32,0x42,0xAA,0x05,
		0x18,0x05,0xAA,0x42,0x32,0xD5,0x03,0x1E,0x61,0xFB,0x7E,0x2B,0x04,0x42,0x3B,0xF9,
		0x00
	);

	# Variables
	my $i;
	my $j;
	my $feedback;

	# Pseudo constants
	my $MM = 8;
	my $NN = 255;
	my $NROOTS = 32;
#	my $FCR = 112; # not used
#	my $PRIM = 11; # not used
#	my $IPRIM = 116; # not used
	my $A0 = $NN; # Special reserved value encoding zero in index form

#	memset(parity, 0, NROOTS * sizeof(uint8_t));
	
	for($i = 0; $i < $NN - $NROOTS - $pad; $i++)
	{
		my $letter = substr($data, $i, 1);
		$feedback = $INDEX_OF[$letter ^ substr($parity,0,1)];
		if($feedback != $A0) # feedback term is non-zero 
		{
			for($j = 1; $j < $NROOTS; $j++)
			{
				$parity[$j] = $parity[$j] ^ $ALPHA_TO[mod255($feedback + $GENPOLY[$NROOTS - $j])];
			}
		}
		
		# Shift
#??		memmove(&parity[0], &parity[1], sizeof(uint8_t) * ($NROOTS - 1));
		$parity = substr($parity, 1);
		
		if($feedback != $A0)
		{
			$parity[$NROOTS - 1] = $ALPHA_TO[mod255($feedback + $GENPOLY[0])];
		}		
		else
		{
			$parity[$NROOTS - 1] = 0;
		}
	}
	return ($parity);
}

sub mod255
{
	my $x = @_;
	while($x >= 255)
	{
		$x -= 255;
		$x = ($x >> 8) + ($x & 255);
	}
	return($x);
}
