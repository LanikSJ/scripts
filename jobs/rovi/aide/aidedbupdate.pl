#! /usr/bin/perl -w
#
# This script will look to see if certain files have been modified, and update the DB for Aide
# to prevent a false positive return.
#
# v .3 May 11 2010
use strict;
use Sys::Hostname;
require "/root/aideCheck.pm";

my @output = ();                        # either ok, or a list of changes
my $difference = 0;
my $currentTime = time();
my $rsynced = 0;
my $uploaded = 0;
my $hostname = hostname();

&aideCheck::check4another;              # Check to see if its already running.
$rsynced = &checkForRsync;
$uploaded = &checkForImageUpload;
if($rsynced || $uploaded)
{
  print "At least one valid file was modified after the last check, lets update the DB.\n";
  print "Generating a report of the current DB state.\n***** Pease verify that the output is as expected *****\n";
  my @results = `/usr/sbin/aide -C`;
  push @output, @results;
  &aideCheck::printMAILdoc(2,$hostname,@output);
  system("/usr/sbin/aide -i");
  system("/bin/mv -f /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz");
}

sub checkForRsync
{
  my $fileName="/var/www/html/rsync/.";
  my @filestats=stat($fileName);
  my $updatedFile = 0;
  if(($currentTime - $filestats[9]) < 14100)
  {
    push @output, ("Time: $currentTime - File Mod Time: $filestats[9] - Difference: " . ($currentTime - $filestats[9]) . "\n");
    $updatedFile = 1;
  }
  return $updatedFile;
}

sub checkForImageUpload
{
  my @localTime = localtime(time());
  my $year = 1900;
  my $month = 1; 
  my $thisMonth = 0;
  my @folders = ();
#  my @fileTypes = ("jpg","jpeg","png","gif","JPG","GIF","JPEG","PNG");
  my $updatedFile = 0;
  my $command = "";
  if($localTime[3] == 1 && $localTime[2] < 4)
  { # This checks to see if the date is the 1st of the month and if it is before 4 AM server time
    if($localTime[3] == 1 && $localTime[4] == 0)
    { # This checks if it is the first of the year
      my $lastYear = $localTime[5] + $year - 1 . "12";
      my $thisYear = $localTime[5] + $year . "01";
      @folders = ($lastYear,$thisYear);
    }
    else
    {
      my $lastMonth = $localTime[5] + $year . $localTime[4];
      if($localTime[4] + $month < 10)
      {
        $thisMonth = $localTime[5] + $year . "0" . $localTime[4] + $month;
      }
      else
      {
        $thisMonth = $localTime[5] + $year . $localTime[4] + $month;
      }
      @folders = ($lastMonth,$thisMonth);
    }
  }
  else
  {
    if($localTime[4] + $month < 10)
    {
      $thisMonth = $localTime[5] + $year . "0" . $localTime[4] + $month;
    }
    else
    {
      $thisMonth = $localTime[5] + $year . $localTime[4] + $month;
    }
    @folders = ($thisMonth);
  }
  foreach my $folderName (@folders)
  {
    my @filesInDir = `/usr/bin/find /var/www/html/webextras/$folderName/* -mtime 0`;
    foreach my $fileName (@filesInDir)
    {
      $fileName =~ s/\s+$//;
      my @filestats=stat($fileName);
      if(($currentTime - $filestats[9]) < 14100 && $fileName =~ /(jpg|JPG|jpeg|JPEG|gif|GIF|png|PNG|bmp|BMP)/)
      {
        push @output, ("$fileName - Time: $currentTime - File Mod Time: $filestats[9] - Difference: " . ($currentTime - $filestats[9]) . "\n");
        $updatedFile += 1;
      }
    }
  }  
  return $updatedFile;
}
 
###
# A simple mail script that determins good or evil
###

#sub printMAILdoc
#{
#  # Set default address
#  my $toAddr = "scot.radowski\@rovicorp.com";
#  my $subject = "WARNING -- Aide DB update on $hostname!";
#  open (MAIL, "|/usr/sbin/sendmail -oi -t") or die "Cannot open sendmail";
#  print MAIL <<end_of_text;
#From: root\@$hostname
#To: $toAddr
#Subject: $subject
#The Aide DB was updated due to recent activity in either rsync or webextras. The output of the aide check follows, please verify there is nothing amiss in the report. 
#
#end_of_text
#  foreach my $line(@output)
#  {
#    print MAIL $line;
#  }
#  close (MAIL);
#}

