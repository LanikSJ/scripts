#!/usr/bin/perl -w

#
#   Script to report who has access
#


# Print Version for --version

$VERSION='.1';
if ( $ARGV[0] && $ARGV[0] eq '--version' ) {
	print "\nVersion: $VERSION\n";
	exit(1);
}

# Test for needed system utils

$UNAME=`which uname 2>/dev/null`;
chomp $UNAME;

if ( ! -x $UNAME ) {
	print "Error: Unable to determine system type.\n";
	exit(2);
}

$OS=`$UNAME`;
chomp $OS;

if ( $OS !~ /(Linux|SunOS)/ ) {
	print "Error: $OS is not supported.\n";
	exit(1);
}

$GETENT=`which getent 2>/dev/null`;
chomp $GETENT;
if ( ! -x $GETENT ) {
	print "Error: getent not found.\n";
	exit(4);
}

$ID=`which id 2>/dev/null`;
chomp $ID;
if ( ! -x $ID ) {
	print "Error: id not found.\n";
	exit(5);
}

# Only run script as root

$scriptUser=`$ID`;
@scriptUserA = split(/\(|\)/, $scriptUser);
$scriptUser = $scriptUserA[1];
if ( $scriptUser ne 'root' ) {
	print "Error: script must be run as root.\n";
	exit(7);
}

# Local account files

$PASSWORD_FILE="/etc/passwd";
#$GROUP_FILE="/etc/group";
#$SHADOW_FILE="/etc/shadow";

# sshd_config location

if ( -f "/etc/ssh/sshd_config" ) {
	$SSHD_CONFIG="/etc/ssh/sshd_config";
} elsif ( -f "/usr/local/etc/sshd_config" ) {
	$SSHD_CONFIG="/usr/local/etc/sshd_config";
}


# ldap search parms for Sun systems - rig because Sun refuses to fix their ldap client.

my $LDAPSEARCH;
my $ldapConnect;
if ( $OS eq 'SunOS' ) {
	$LDAPSEARCH=`which ldapsearch 2>/dev/null`;
	chomp $LDAPSEARCH;
	if ( ! -x $LDAPSEARCH ) {
		print "Error: Unable to execute ldapsearch\n";
		exit(3);
	}
	if ( ! -r '/etc/ldap.conf' ) {
		print "Error: Unable to open /etc/ldap.conf\n";
		exit(6);
	}
	my $ldapHost;
	my $ldapSearchBase;
	my $ldapBindUserDn;
	my $ldapBindUserDnPassword;
	open(LDAP_CONF, '</etc/ldap.conf') || die "Error: Unable to open /etc/ldap.conf\n";
	while (<LDAP_CONF>) {
		my $line = $_;
		chomp $line;
		if ( $line =~ m/^base\s/ ) {
			my @lineA = split(/\s/, $line);
			shift(@lineA);
			@lineA = split(/\#/, "@lineA");
			$lineA[0] =~ s/\s{1,}$//;
			$ldapSearchBase = "$lineA[0]";
		}
		if ( $line =~ m/^host\s/ ) {
			my @lineA = split(/\s/, $line);
			$ldapHost = $lineA[1];
			$ldapHost =~ s/\s//g;
		}
		if ( $line =~ m/^binddn\s/ ) {
			my @lineA = split(/\s/, $line);
			shift(@lineA);
			@lineA = split(/\#/, "@lineA");
			$lineA[0] =~ s/\s{1,}$//;
			$ldapBindUserDn = "$lineA[0]";
		}	
		if ( $line =~ m/^bindpw\s/ ) {
			my @lineA = split(/\s/, $line);
			$ldapBindUserDnPassword = $lineA[1];
			$ldapBindUserDnPassword =~ s/\s//g;
		}
	}
	$ldapConnect="-LLL -R -h \"$ldapHost\" -b \"$ldapSearchBase\" -D \"$ldapBindUserDn\" -w \'$ldapBindUserDnPassword\'";	
}

# Push local user config info into arrays and hashes 

@passwdUsers=();
%usersGID=();
open(PASSWD, "<$PASSWORD_FILE") || die "ERROR: can't open $PASSWORD_FILE: $!";
my $user;
my $extra;
my $extra1;
my $uid;
my $gid;
while (<PASSWD>) {
	$line = $_;
	chomp $line;
	($user, $extra, $uid, $gid, $extra1) = split(/:/, $line);	
	
	#
	# push all users into array
	#
	push @passwdUsers, $user;

	#
	# push gid into hashes
	#
	$usersGID{$user} = $gid;

}
close(PASSWD);

# Show accounts that can authenticate via LDAP.
print "\n";
my $userListIn=();
my $userList=();
my $ldapAuth=0;
my $krbAuth=0;
my $pamAccess=0;
my $sshAccess=0;
my @accessList=();
my @accessListtmp=();
my $systemAuth; 
my $systemAccess; 
if ( $OS eq "Linux" ) {
	if ( -f "/etc/pam.d/system-auth" ) {
		$systemAuth = "/etc/pam.d/system-auth";
		$systemAccess = "/etc/pam.d/system-auth";
	} elsif ( -f "/etc/pam.d/common-auth" && -f "/etc/pam.d/common-account" ) {
		$systemAuth = "/etc/pam.d/common-auth";
		$systemAccess = "/etc/pam.d/common-account";
	} 
	if ( ! -f "$systemAuth" ) {
		print "ERROR: unable to find PAM system-auth configuration.\n";
	} else {
		open(SYSTEM_AUTH, "<$systemAuth");
		while(<SYSTEM_AUTH>) {
			my $line = $_;
			chomp $line;
			if ( $line =~ /^auth/ && $line =~ /pam_ldap.so/ ) {
				$ldapAuth=1;
			}
			if ( $line =~ /^auth/ && $line =~ /pam_krb5.so/ ) {
				$krbAuth=1;
			}
		}
		close(SYSTEM_AUTH);
		open(SYSTEM_ACCESS, "<$systemAccess");
		while(<SYSTEM_ACCESS>) {
			my $line = $_;
			chomp $line;
			if ( $line =~ /^account/ && $line =~ /pam_access.so/ ) {
				$pamAccess=1;
			}
		}
		close(SYSTEM_ACCESS);
	}
}
if ( $OS eq "SunOS" ) {
	if ( ! -f "/etc/pam.conf" ) {
		print "ERROR: unable to find pam.conf.\n";
	} else {
		open(PAM_CONF, "</etc/pam.conf");
		my @accessList=();
		my @accessListtmp=();
		while(<PAM_CONF>) {
			my $line = $_;
			chomp $line;
			if ( $line =~ /^other/ && $line =~ /pam_ldap.so/ ) {
				$ldapAuth=1;
			}
		}
	}
}

if ( $ldapAuth == 0 && $krbAuth == 0 ) {
	print "LDAP or Kerberos Authentication is not enabled.\n";
} else {
	if ( $pamAccess == 0 ) {
		if ( $OS eq 'Linux' ) {
			print "WARNING: pam_access module not enabled.\n";
		}
	} else {
		print "Access control via pam_access module.\n";
		open(PAM_ACCESS, "</etc/security/access.conf");
		my $defaultDeny=0;
		while(<PAM_ACCESS>) {	
			my $line = $_;
			my $access;
			my $list;
			my $host;
			chomp $line;
			if ( $line =~ /[\t ]{0,}\#/ ) {
				next;
			}
			($access, $list, $host) = split(/:/, $line);
			$list =~ s/[\t ]{1,}/ /g;
			$list =~ s/^[\t ]{1,}//g;
			$list =~ s/[\t ]{1,}$//g;
			if ( $access eq "+" ) {
				@accessListtmp = split(/ /, $list);
				foreach (@accessListtmp) {
					push @accessList, $_;
				}
			} elsif ( $access eq "-" ) {
				if ( $list eq "ALL" ) {
					$defaultDeny=1;
					last;
				}
			}
	
		}
		if ( $defaultDeny == 0 ) {
			print "WARNING! There is no entry in /etc/security/access.conf to set default access to DENY.\n";
		}
		
		# See if any groups exist in access list
		@accessListtmp=();
		foreach (@accessList) {
			my $entry = $_;
			push(@accessListtmp, users_per_group($entry));
		}
		push (@accessList, @accessListtmp);

		foreach (@accessList) {
			my $entry = $_;
			#
			# see if the user is local.
			#
			if ( grep/^$entry$/, @passwdUsers) {
				next;
			} elsif ( $entry !~ /^\@/ ) {
				push @userListIn, $entry;
				# Set if this is also a group
			}
			#
			# resolve nisnetgroup memberships.
			#
			if ( $entry =~ /^\@/ ) {
				my @nisListTmp=();
				$entry =~ s/\@//;
				$nisList=`$GETENT netgroup $entry`;
				chomp $nisList;
				@nisListTmp=split(/\(/, $nisList);	
				splice(@nisListTmp, 0, 1,);
				foreach (@nisListTmp) {
					my $nisEntry = $_;
					$nisEntry =~ s/( |\,|\))//g;
					push @userListIn, $nisEntry;
				}
			}
		}
		#
		# Unique the @userList array
		#
		my %saw = map { $_ => 1 } @userListIn;	
		@userList = sort keys %saw;
	}

	#
	# Look for AllowUser and AllowGroup entries in /etc/ssh/sshd_config
	#
	my @sshAllowUsers=();
	my @sshAllowUsersT=();
	my @sshAllowGroups=();
	my $sshAccessControl=0;
	if ( ! -f "$SSHD_CONFIG" ) {
		print "Error: Unable to find sshd_config.\n";
	} else {
		open(SSHD, "<$SSHD_CONFIG");
		while(<SSHD>) {
			my $line = $_;
			chomp $line;
			if ( $line =~ /^AllowGroups/ ) {
				$sshAccessControl=1;
				print "Access control via ssh's AllowGroups.\n"; 
				my @groupList=split(/\s+/, $line);
				splice(@groupList, 0, 1,);
				foreach (@groupList) {
					@sshAllowUsersT=users_per_group($_);
					foreach(@sshAllowUsersT) {
						my $user=$_;
						if ( ! grep/^$user$/, @passwdUsers ) {
							push @sshAllowUsers, $user;
						}
					}
				}
			} elsif ($line =~ /^AllowUsers/ ) { 
				$sshAccessControl=1;
				print "Access control via ssh's AllowUsers.\n";
				@sshAllowUsersT=split(/\s+/, $line);
				splice(@sshAllowUsersT, 0, 1,);
				foreach(@sshAllowUsersT) {
					my $user=$_;
					if ( ! grep/^$user$/, @passwdUsers ) {
						push @sshAllowUsers, $user;
					}
				}
			}
			#
			# Unique the @userList array
			#
			my %saw = map { $_ => 1 } @sshAllowUsers;	
			@sshAllowUsers = sort keys %saw;
		}
	}

	#
	# Display user information
	#
	if ( $sshAccessControl == 0 && $pamAccess == 0 ) {
		print "WARNING: LDAP is enabled without access control!\n";
	} else {
		print "\nThe following accounts have access to this system via LDAP authentication:\n";
		$PRINTF="%-15s%-10s%-50s\n";
		printf($PRINTF, "Account", "UID", "Name");
		printf($PRINTF, "=======", "===", "====");
		if ( $sshAccessControl == 1 && $pamAccess == 0 ) { 
			foreach(@sshAllowUsers) {
				print_user($_);
			}	
		} elsif ( $sshAccessControl == 0 && $pamAccess == 1 ) {
			foreach(@userList) {
				print_user($_);
			}
		} elsif ( $sshAccessControl == 1 && $pamAccess == 1 ) {
			# user must exist in both arrays
			foreach(@userList) { 
				my $user = $_;
				if ( grep/^$user$/, @sshAllowUsers) {
					print_user($user);
				}	
			}
			
		}	

	}
}
	

#
# Verify Remote Root is disable in sshd_config

if ( ! -f $SSHD_CONFIG ) {
	print "\nUnable to find sshd_config.\n";
} else {
	open (SSHD, "<$SSHD_CONFIG"); 
	if ( grep(/PermitRootLogin no/, <SSHD>) ) {
		print "\nRemote Root Login via SSH is disabled.\n";
	} else {
		print "\nRemote Root Login via SSH is enabled.\n";
	}
}
print "\n";
		
#
# Sub Routines
#

sub print_user {
	my $user = $_[0];
	if ( ! $user ) {
		return;
	}
	my $PRINTF="%-15s%-10s%-50s\n";
	my $pAccount;
	my $pX;
	my $pUid;
	my $pGid;
	my $pName;
	my $pHome;
	my $pShell;
	my $userInfo=`$GETENT passwd $user`;
	chomp $userInfo;
	if ( $userInfo ) {
		($pAccount, $pX, $pUid, $pGid, $pName, $pHome, $pShell) = split(/:/, $userInfo);
		printf($PRINTF, $pAccount, $pUid, $pName);
	}	
}
	


sub users_per_group {
#
# Returns a list of users for a given group name
#
	my $gname = $_[0];
	my $gid;
	my $gnameT;
	my $gX;
	my $glist;
	my @groupMembers=();

	if ( ! $gname ) {
		return;
	}
	my $gEntry = `$GETENT group $gname`;	
	chomp $gEntry;
	if ( ! $gEntry ) {
		return;
	}
	($gnameT, $gX, $gid, $glist) = split(/:/, $gEntry); 
	if ( $glist ) {
		@groupMembers=split(/\,/, $glist);
	} 
	#
	# find local users with primary group.
	#
	foreach (keys %usersGID ) {
		my $user = $_;
		if ($usersGID{$user} eq $gid) {
			push @groupMembers, $user;
		}
	}
	#
	# find ldap users with primary group.
	#
	if ( $OS eq 'SunOS' ) {
		my @PrimaryGroup = `$LDAPSEARCH $ldapConnect "(&(objectclass=user)(msSFU30Name=\*)(gidNumber=$gid))" msSFU30Name 2>/dev/null`;
		foreach (@PrimaryGroup) {
			my $line = $_;
			chomp $line;
			my $xtra;
			my $user;
			if ( $line =~ /^msSFU30Name:/ ) {
				($xtra, $user) = split(/: /, $line);
				push @groupMembers, $user;
			}
		}	
	} else {
		my @PrimaryGroup = `$GETENT passwd 2>/dev/null`;
		foreach ( @PrimaryGroup ) {
			my $entry = $_;
			chomp $entry;
			my @entry = split(/:/, $entry);
			if ( $entry[3] eq "$gid" ) {
				push @groupMembers, $entry[0];
			}
		}
	}
	return @groupMembers;	
}
	
