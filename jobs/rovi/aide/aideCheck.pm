package aideCheck;

use strict;
use vars qw(
$VERSION
);

#############################################################################
#
# This sub takes 3 arguments.  The first argument is used to check if there 
# was a failure, warning or nothing unusual. The second is the output data. 
# The third is the hostname of the server.
#
#############################################################################

sub printMAILdoc
{
  my ($failedCheck, $hostname, @output) = @_;
  my $toAddr = "scot.radowski\@rovicorp.com";
  my $subject = "";
  my $body = "";
  
  print "Hostname: $hostname\n";

  if($failedCheck == 1)
  {
    $subject = "File altered on $hostname!";
    $toAddr .=",it-infosec\@rovicorp.com,sys-eng\@rovicorp.com";
    $body = "At least one file has been altered. Please review the information below!\n"
  }
  elsif($failedCheck == 2)
  {
    $subject = "WARNING -- Aide DB update on $hostname!";
    $toAddr .=",it-infosec\@rovicorp.com,sys-eng\@rovicorp.com";
    $body = "The Aide DB was updated due to recent activity in either rsync or webextras. The output of the aide check follows, please verify there is nothing amiss in the report.\n"
  }
  else
  {
    $subject = "Aide check OK on $hostname!";
    $body = "Check OK!\n"
  }
  open (MAIL, "|/usr/sbin/sendmail -oi -t") or die "Cannot open sendmail";
  print MAIL <<end_of_text;
From: root\@$hostname
To: $toAddr
Subject: $subject

$body

end_of_text
  foreach my $line(@output)
  {
    print MAIL $line;
  }
  close (MAIL);
}

sub check4another
{
  my @processes = `ps -ef | grep .pl | grep -v grep`;
  if($processes[0] =~ "check.pl|aidedbupdate.pl")
  {
    foreach my $line (@processes)
    {
      (my $owner, my $process, my $parent, my @rest) = split(/\s+/, $line);
      if($process != $$)
      {
        kill 9, $process;
      }
    }
  }
}

$VERSION = "0.2";

1;
__END__
