#!/usr/bin/perl

use strict;
use Switch;
use POSIX 'strftime';
use POSIX;
use DBI;

# Code pushed to gitHub

#by default debug is off, change to 1 for debug
my $DEBUG=1;
my $LOGFILE="/var/log/basecheck/logic.log";
my $MAXCALLS=40;
my $TRY=$ARGV[0];
my $basename=$ARGV[1];

loging ("--- Basecheck Logic script started ---") if $DEBUG;


#=== Check count of active calls and queue files, Exit if more then MAXCALLS param

my $active_files=`ls -l /var/spool/asterisk/outgoing/ | grep 'BASECHECK' | wc -l`; chomp $active_files;
if ($active_files >= $MAXCALLS){
	loging ("--- MAXCALLS reached, passing iteration ---") if $DEBUG;
	loging ("--- Basecheck Logic script completed ---") if $DEBUG;
	exit;
}

#===


#=== Check SIP connection

my $trunkCLB = `asterisk -rx "sip show peers" | grep 'main_trunk1' | grep -v grep`; 
chomp $trunkCLB;
if ($trunkCLB =~ m/UN/) {
	loging ("$trunkCLB");
	my $conn = DBI->connect("DBI:mysql:crm:localhost", "root", "",{ RaiseError => 1 }) or die $DBI::errstr;
	my $query = $conn->prepare("UPDATE basecheck_active SET pause=1 LIMIT 1");
	my $res = $query->execute();
	$conn->disconnect();

	loging ("ATTENTION! PROBLEM WITH SIP SIGNALING... SETTING PAUSE ON");

	exit 1; 
} 

#=== Actual logic
#my $basename = `cat /etc/asterisk/basecheck/base`; chomp $basename;


my $conn = DBI->connect("DBI:mysql:bases:localhost", "root", "",{ RaiseError => 1 }) or die $DBI::errstr;
my $query = $conn->prepare("SELECT id, number, name, status FROM $basename WHERE `status` = '$TRY' ORDER BY RAND() LIMIT $MAXCALLS");
my $res = $query->execute();

#=== Check if no more numbers left to dial
if ($res == 0) {
	# ======
		# Basecheck Shutdown mechanism
		my $dt = strftime '%Y-%m-%d %H:%M:%S', localtime;
		if ($TRY == 0) {
			my $conn2 = DBI->connect("DBI:mysql:crm:localhost", "root", "",{ RaiseError => 1 }) or die $DBI::errstr;
			my $query2 = $conn2->prepare("UPDATE basecheck_active SET step1=2, step1endtime='$dt' LIMIT 1");
			my $res2 = $query2->execute();
			$conn2->disconnect();
			loging ("--- STEP1 COMPLETED ---") if $DEBUG;
		}
		elsif ($TRY == 1) {
			my $conn2 = DBI->connect("DBI:mysql:crm:localhost", "root", "",{ RaiseError => 1 }) or die $DBI::errstr;
			my $query2 = $conn2->prepare("UPDATE basecheck_active SET step2=2, step2endtime='$dt' LIMIT 1");
			my $res2 = $query2->execute();
			$conn2->disconnect();
			loging ("--- STEP2 COMPLETED ---") if $DEBUG;
		}
		elsif ($TRY == 2) {
			my $conn2 = DBI->connect("DBI:mysql:crm:localhost", "root", "",{ RaiseError => 1 }) or die $DBI::errstr;

			my $query = $conn2->prepare("SELECT report FROM basecheck_active LIMIT 1");
			my $res = $query->execute(); 
			
			my $r; 
			my $report;  
			while ($r = $query->fetchrow_arrayref()){
				$report = @$r[0];
			}

			#Generate report of failed numbers
			if ($report == 0) {
				my $query2 = $conn2->prepare("select a.calldate, a.did, a.disposition from asteriskcdrdb.cdr as a ,(select did,count(*) as tot from asteriskcdrdb.cdr where dcontext='basecheck' and userfield='$basename' and dst=2222 and disposition!='ANSWERED' group by did  having tot = 3 ) as b where a.did = b.did and a.dcontext='basecheck' and a.userfield='$basename' and a.dst=2222 and a.disposition!='ANSWERED' order by 2,1 into outfile '/var/www/html/reports/failed_$basename.csv' fields terminated by ',' lines terminated by '\n';");
				my $res2 = $query2->execute();
				if ($res2) {
					loging ("--- REPORT GENERATED ---") if $DEBUG;
				}

				$query2 = $conn2->prepare("UPDATE basecheck_active SET step3=2, step3endtime='$dt', completed=2, completetime='$dt', report=1 LIMIT 1");
				$res2 = $query2->execute();

				$query2 = $conn2->prepare("UPDATE bases.$basename SET status=0 LIMIT 1");
				$res2 = $query2->execute();

			}
			
			$conn2->disconnect();
			loging ("--- STEP3 COMPLETED ---") if $DEBUG;
		}
	# ======
	loging ("--- Basecheck Logic script completed successfully --- \n") if $DEBUG;
	exit;
}

my $r;
my $id;
my $num;
my $name;
my $status;
my $exec;
my $i=1;
while ($r = $query->fetchrow_arrayref()){
	$id = @$r[0];
	$num = @$r[1];
	$name = @$r[2];
	$status = @$r[3];

	loging (">>> Passing this number to dial >> $num $basename $status $name") if $DEBUG;
	$exec = `/etc/asterisk/basecheck/dial.sh $num $basename $id $status $name`;
	if($i%4==1){
		sleep(1);
	}
	$i+=1;
	if ($status == "0") {
		$status = "1";
	} 
	elsif ($status == "1") {
		$status = "2";
	}
	elsif ($status == "2") {
		$status = "3";
	}
	#=== UPDATE the status by number of try (0,1,2)
	my $datestring = strftime '%Y-%m-%d %H:%M:%S', localtime; chomp $datestring;
	my $updt = $conn->prepare("UPDATE $basename SET `status`='$status', `calledtime`='$datestring' WHERE id='$id' LIMIT 1");
	my $res_updt = $updt->execute();
}

$conn->disconnect();
loging ("--- Basecheck Logic script completed successfully --- \n") if $DEBUG;




sub loging {
  my ($text)=@_;
  my $datestring = strftime '%Y-%m-%d %H:%M:%S', localtime;
  open (LOG,">>$LOGFILE");
  print LOG "$datestring $text\n";
  close LOG;
}


