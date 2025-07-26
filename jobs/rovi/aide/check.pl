#! /usr/bin/perl -w
use strict;
use Sys::Hostname;
require "/root/aideCheck.pm";

my @output = ();			# either ok, or a list of changes 
my $difference = 0;
my @results = `/usr/sbin/aide -C`;
my $hostname = hostname;

&aideCheck::check4another;				# Check to see if its already running.
&logger("Starting");			# Start time in the log file.

foreach my $line (@results)
{
  if($line =~"AIDE found differences")
  {
    $difference = 1;
  }
}

if($difference==1)
{
  print "There was a difference, generating e-mail!\n";
  push @output, @results;
}
else
{
  print "Check OK!\n";
  push @output, ("Check OK!");
}
&logger(@output);

&aideCheck::printMAILdoc($difference, $hostname, @output);

my $enddate = "Ended at " . &mytime . "\n";
&logger("Ending");

#############################
###   The land of subs    ###
###   isn't land at all   ###
#############################

###
# A simple sub to return the current date and time.
###

sub mytime
{
	my @date = localtime(time()-86400);
	my $date = sprintf ("%04d-%02d-%02d %02d:%02d:%02d",$date[5]+1900,$date[4]+1,$date[3],$date[2],$date[1],$date[0]);
	return $date;
}

###
# This subroutine checks to see if another instance of the script is already running.
# If it finds one that isn't _this_ instance, it will kill it.
###

#sub check4another
#{
#	my @processes = `ps -ef | grep check.pl | grep -v grep`;
#	if($processes[0] =~ "check.pl")
#	{
#		foreach my $line (@processes)
#		{
#			(my $owner, my $process, my $parent, my @rest) = split(/\s+/, $line);
#			if($process != $$)
#			{
#				kill 9, $process;
#			}
#		}
#	}
#}

###
# A simple log that also shows how long the script was running.
###

sub logger
{
	open LOGFILE, ">>/var/log/aidecheck.log";
	print LOGFILE $_[0] . ": " . &mytime . "\n";
	close(LOGFILE);
}

###
# A simple mail script that determins good or evil
###

#sub printMAILdoc
#{
#  # Set default address
#  my $toAddr = "scot.radowski\@rovicorp.com";
#  my $subject = "";
#  if($_[0] == 1)
#  {
#    $subject = "File altered on $hostname!";
#    $toAddr .=",it-infosec\@rovicorp.com,sys-eng\@rovicorp.com";
#  }
#  else
#  {
#    $subject = "Aide check OK on $hostname!";
#  }
#  open (MAIL, "|/usr/sbin/sendmail -oi -t") or die "Cannot open sendmail";
#  print MAIL <<end_of_text;
#From: root\@$hostname
#To: $toAddr
#Subject: $subject
#The Following was found:
#end_of_text
#  foreach my $line(@output)
#  {
#    print MAIL $line;
#  }
#  close (MAIL);
#}
