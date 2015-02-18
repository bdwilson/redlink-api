#!/usr/bin/perl 

# Perl interface to Honeywell Redlink/Honeywell TotalConnectComfort 
#
# This interface can be extended if you follow the API spec available
# here: https://rs.alarmnet.com/TotalConnectComfort/ws/MobileV2.asmx
#
# 2/18/2015 - bubba@bubba.org
# 
# For installation instructions, please see:
# https://github.com/bdwilson/redlink-api
#
###

use LWP::UserAgent;
use XML::TreePP;
use HTTP::Request::Common qw(POST);
use Data::Dumper;
use Config::Simple;

### 
if (!-f "$ENV{'HOME'}/.redlink.ini") {
	print "Please create a config file in $ENV{HOME}/.redlink.ini\n";
	exit;
}
$cfg = new Config::Simple("$ENV{HOME}/.redlink.ini");
$user=$cfg->param('user.username');
$pass=$cfg->param('user.password');
$appid=$cfg->param('user.appid');
$expire=$cfg->param('user.expire');
$session=$cfg->param('user.session');
$svcUrl="https://rs.alarmnet.com/TotalConnectComfort/ws/MobileV2.asmx";

$ua= LWP::UserAgent->new;
my %headers = (
	'Content-Type' => 'application/x-www-form-urlencoded',
	'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Encoding' => 'sdch',
        'Host' => 'rs.alarmnet.com',
        'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.95 Safari/537.36'
);


if ($expire && $session) {
	if ($expire < time()) {
		#print "Expire\n";
		$session = &login($user,$pass,$appid);
	} else {
		#print "keep alive\n";
		$ret = &keepalive($session);
		if (!$ret) {
			$session = &login($user,$pass,$appid);
		}
	}
	
} else {
	#print "No session\n";
	$session = &login($user,$pass,$appid);
}

&getLocations($session);

sub getLocations {
	my $sessid = shift;
	my %postdata = ("sessionID" => $sessid);
	my $req = HTTP::Request->new;
        $req = POST("$svcUrl/GetLocations", [%postdata]);
        $req->header([%headers]);
        $res = $ua->request($req);
        if ($res->is_success) {
                my $xs = XML::TreePP->new();
                my $ref = $xs->parse($res->content);
		#print Dumper $ref;
		foreach my $key (@{$ref->{GetLocationsResult}->{Locations}->{LocationInfo}->{Thermostats}->{ThermostatInfo}}) {
			my $ui=$key->{'UI'};
			#print Dumper $key;
			print $key->{'DeviceName'} . "\n";
			print "\t $ui->{'DispTemperature'} / ";
			if ($ui->{'SystemSwitchPosition'} == 1) {
				if ($ui->{'SchedHeatSp'} != $ui->{'HeatSetpoint'}) {
					$override=1;
					$sp=$ui->{'HeatSetpoint'};
				}
				# this makes no sense. StatusHeat/StatusCool is 0 if 
				# your system is running on schedule
				if ($ui->{'StatusHeat'} == 0) {
					# this is not completely accurate; since the system
					# can still run if the SP and DispTemp are the same
					if ($ui->{'DispTemperature'} != $ui->{'SchedHeatSp'}) {
						$status = "Heat on (schedule)";
						
					} elsif ($ui->{'DispTemperature'} == $ui->{'SchedHeatSp'}) {
						$status="Heat off";
					}
					$sp=$ui->{'SchedHeatSp'};
				}
				if ($override) {
					if ($ui->{'StatusHeat'} == 1) {
						$status = "Heat on (overridden)";
					} elsif ($ui->{'StatusHeat'} == 0 && $override) {
						$status ="Heat off (overridden)";
					}
				}
			} elsif ($ui->{'SystemSwitchPosition'} == 3) {
				if ($ui->{'SchedCoolSp'} != $ui->{'CoolSetpoint'}) {
					$override=1;
					$sp=$ui->{'CoolSetpoint'};
				}
				# this makes no sense. StatusHeat/StatusCool is 0 if 
				# your system is running on schedule
				if ($ui->{'StatusCool'} == 0) {
					# this is not completely accurate; since the system
					# can still run if the SP and DispTemp are the same
					if ($ui->{'DispTemperature'} != $ui->{'SchedCoolSp'}) {
						$status = "Cool on (schedule)";
						
					} elsif ($ui->{'DispTemperature'} == $ui->{'SchedCooltSp'}) {
						$status="Cool off";
					}
					$sp=$ui->{'SchedCoolSp'};
				}
				if ($override) {
					if ($ui->{'StatusCool'} == 1) {
						$status = "Cool on (overridden)";
					} elsif ($ui->{'StatusHeat'} == 0 && $override) {
						$status ="Cool off (overridden)";
					}
				}
			}
			print "$sp ($status)\n";
		}
	}
}

sub keepalive {
	my $sessid = shift;
	my %postdata = ("sessionID" => $sessid);
	my $req = HTTP::Request->new;
        $req = POST("$svcUrl/KeepAlive", [%postdata]);
        $req->header([%headers]);
        $res = $ua->request($req);
        if ($res->is_success) {
                my $xs = XML::TreePP->new();
                my $ref = $xs->parse($res->content);
		#print Dumper $ref;
		if ($ref->{'KeepAliveResult'}->{'Result'} eq "Success") {
			return 1;
		} else {
			return 0;
		}
	}
}

sub login {
	my ($user,$pass,$appid) = @_;
	my %postdata = ("username" => $user,
		"password" => "$pass",
	        "applicationID" => "$appid",
		"applicationVersion" => "2",
		"uiLanguage" => "English");
	$req = HTTP::Request->new;
	$req = POST("$svcUrl/AuthenticateUserLogin", [%postdata]);
	$req->header([%headers]);
	$res = $ua->request($req);
	if ($res->is_success) {
		my $xs = XML::TreePP->new();
		my $ref = $xs->parse($res->content);
		if ($ref->{'AuthenticateLoginResult'}->{'SessionID'}) {
          		$cfg->param('user.expire',time()+3600);
			$cfg->param('user.session',$ref->{'AuthenticateLoginResult'}->{'SessionID'});
                        $cfg->save();
			return $ref->{'AuthenticateLoginResult'}->{'SessionID'};
		} else { 
			print "Authentication failed. Please check your credentials\n";
			print Dumper $ref;
			return 0;
		}
	}
}
