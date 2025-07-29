#!/usr/bin/env perl
#
# Script to report who has access to the system based on LDAP, Kerberos,
# PAM access control, and SSH daemon configurations.
#
# This script requires root privileges to access system configuration files.

use strict;
use warnings;
use feature 'say'; # Use 'say' for simpler printing with newline

# --- Configuration ---
my $VERSION = '0.2'; # Updated version number

# --- Helper Subroutines ---

# Function to print error messages to STDERR and exit
sub error_exit {
    my ($message, $exit_code) = @_;
    say STDERR "Error: $message";
    exit($exit_code);
}

# Function to check if a command exists and is executable
sub check_command {
    my ($cmd_name) = @_;
    my $path = `which $cmd_name 2>/dev/null`;
    chomp $path;
    return $path if (-x $path);
    return undef;
}

# --- Main Script Logic ---

# Handle --version flag
if ( $ARGV[0] && $ARGV[0] eq '--version' ) {
    say "Version: $VERSION";
    exit(0); # Exit with 0 for successful display of version
}

# Test for needed system utilities
my $UNAME_CMD = check_command('uname');
error_exit("Unable to determine system type (uname not found or not executable).", 2) unless $UNAME_CMD;

my $OS = `$UNAME_CMD`;
chomp $OS;
error_exit("$OS is not supported. Only Linux and SunOS are supported.", 1) unless $OS =~ /(Linux|SunOS)/;

my $GETENT_CMD = check_command('getent');
error_exit("getent not found or not executable.", 4) unless $GETENT_CMD;

my $ID_CMD = check_command('id');
error_exit("id not found or not executable.", 5) unless $ID_CMD;

# Only run script as root
my $scriptUserOutput = `$ID_CMD`;
my ($scriptUser) = $scriptUserOutput =~ /\((.*?)\)/; # Extract username from 'id' output
error_exit("Script must be run as root.", 7) unless defined $scriptUser && $scriptUser eq 'root';

# Local account files
my $PASSWORD_FILE = "/etc/passwd";
#my $GROUP_FILE="/etc/group"; # Not used in original script, keeping commented
#my $SHADOW_FILE="/etc/shadow"; # Not used in original script, keeping commented

# sshd_config location
my $SSHD_CONFIG;
if ( -f "/etc/ssh/sshd_config" ) {
    $SSHD_CONFIG = "/etc/ssh/sshd_config";
} elsif ( -f "/usr/local/etc/sshd_config" ) {
    $SSHD_CONFIG = "/usr/local/etc/sshd_config";
} else {
    error_exit("Unable to find sshd_config. Checked /etc/ssh/sshd_config and /usr/local/etc/sshd_config.", 8);
}

# ldap search parms for Sun systems - rig because Sun refuses to fix their ldap client.
my $LDAPSEARCH_CMD;
my $ldapConnect = ''; # Initialize to empty string
if ( $OS eq 'SunOS' ) {
    $LDAPSEARCH_CMD = check_command('ldapsearch');
    error_exit("Unable to execute ldapsearch (ldapsearch not found or not executable).", 3) unless $LDAPSEARCH_CMD;

    my $ldap_conf_file = '/etc/ldap.conf';
    error_exit("Unable to open $ldap_conf_file for reading.", 6) unless -r $ldap_conf_file;

    my $ldapHost;
    my $ldapSearchBase;
    my $ldapBindUserDn;
    my $ldapBindUserDnPassword;

    open(my $fh_ldap_conf, '<', $ldap_conf_file) || error_exit("Unable to open $ldap_conf_file: $!", 6);
    while (my $line = <$fh_ldap_conf>) {
        chomp $line;
        if ( $line =~ m/^base\s+(\S.*)/ ) { # Capture everything after 'base '
            $ldapSearchBase = $1;
            $ldapSearchBase =~ s/\s*#.*//; # Remove comments
            $ldapSearchBase =~ s/\s+$//; # Trim trailing whitespace
        }
        if ( $line =~ m/^host\s+(\S+)/ ) { # Capture single word after 'host '
            $ldapHost = $1;
        }
        if ( $line =~ m/^binddn\s+(\S.*)/ ) { # Capture everything after 'binddn '
            $ldapBindUserDn = $1;
            $ldapBindUserDn =~ s/\s*#.*//; # Remove comments
            $ldapBindUserDn =~ s/\s+$//; # Trim trailing whitespace
        }
        if ( $line =~ m/^bindpw\s+(\S+)/ ) { # Capture single word after 'bindpw '
            $ldapBindUserDnPassword = $1;
        }
    }
    close($fh_ldap_conf);

    # Ensure all necessary LDAP parameters were found
    unless (defined $ldapHost && defined $ldapSearchBase && defined $ldapBindUserDn && defined $ldapBindUserDnPassword) {
        error_exit("Missing one or more required LDAP parameters (host, base, binddn, bindpw) in $ldap_conf_file.", 9);
    }

    $ldapConnect = "-LLL -R -h \"$ldapHost\" -b \"$ldapSearchBase\" -D \"$ldapBindUserDn\" -w \'$ldapBindUserDnPassword\'";
}

# Push local user config info into arrays and hashes
my @passwdUsers;
my %usersGID;
open(my $fh_passwd, "<", $PASSWORD_FILE) || error_exit("Can't open $PASSWORD_FILE: $!", 10);
while (my $line = <$fh_passwd>) {
    chomp $line;
    my ($user, undef, my $uid, my $gid, undef) = split(/:/, $line, 5); # Use undef for unused fields

    # Push all users into array
    push @passwdUsers, $user;

    # Push gid into hashes
    $usersGID{$user} = $gid;
}
close($fh_passwd);

# Show accounts that can authenticate via LDAP.
say ""; # Print a newline

my @userListIn;
my @userList;
my $ldapAuth = 0;
my $krbAuth = 0;
my $pamAccess = 0;
my $sshAccess = 0; # This variable seems unused in the original logic, keeping for now
my @accessList;
my @accessListtmp;
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

    unless (defined $systemAuth && -f $systemAuth) {
        error_exit("Unable to find PAM system-auth configuration.", 11);
    } else {
        open(my $fh_system_auth, "<", $systemAuth) || error_exit("Can't open $systemAuth: $!", 12);
        while(my $line = <$fh_system_auth>) {
            chomp $line;
            if ( $line =~ /^auth/ && $line =~ /pam_ldap\.so/ ) {
                $ldapAuth = 1;
            }
            if ( $line =~ /^auth/ && $line =~ /pam_krb5\.so/ ) {
                $krbAuth = 1;
            }
        }
        close($fh_system_auth);

        unless (defined $systemAccess && -f $systemAccess) {
            error_exit("Unable to find PAM system-access configuration.", 13);
        } else {
            open(my $fh_system_access, "<", $systemAccess) || error_exit("Can't open $systemAccess: $!", 14);
            while(my $line = <$fh_system_access>) {
                chomp $line;
                if ( $line =~ /^account/ && $line =~ /pam_access\.so/ ) {
                    $pamAccess = 1;
                }
            }
            close($fh_system_access);
        }
    }
}

if ( $OS eq "SunOS" ) {
    my $pam_conf_file = "/etc/pam.conf";
    unless (-f $pam_conf_file) {
        error_exit("Unable to find $pam_conf_file.", 15);
    } else {
        open(my $fh_pam_conf, "<", $pam_conf_file) || error_exit("Can't open $pam_conf_file: $!", 16);
        while(my $line = <$fh_pam_conf>) {
            chomp $line;
            if ( $line =~ /^other/ && $line =~ /pam_ldap\.so/ ) {
                $ldapAuth = 1;
            }
        }
        close($fh_pam_conf);
    }
}

if ( $ldapAuth == 0 && $krbAuth == 0 ) {
    say "LDAP or Kerberos Authentication is not enabled.";
} else {
    if ( $pamAccess == 0 ) {
        if ( $OS eq 'Linux' ) {
            say STDERR "WARNING: pam_access module not enabled.";
        }
    } else {
        say "Access control via pam_access module.";
        my $access_conf_file = "/etc/security/access.conf";
        open(my $fh_pam_access, "<", $access_conf_file) || error_exit("Can't open $access_conf_file: $!", 17);
        my $defaultDeny = 0;
        while(my $line = <$fh_pam_access>) {
            my ($access, $list, $host);
            chomp $line;
            next if $line =~ /^\s*#/; # Skip comments and empty lines

            ($access, $list, $host) = split(/:/, $line, 3); # Limit split to 3 fields
            $list =~ s/^\s+|\s+$//g; # Trim leading/trailing whitespace
            $list =~ s/\s+/ /g; # Replace multiple spaces with single space

            if ( $access eq "+" ) {
                push @accessList, split(/ /, $list);
            } elsif ( $access eq "-" ) {
                if ( $list eq "ALL" ) {
                    $defaultDeny = 1;
                    last; # No need to parse further if default deny is found
                }
            }
        }
        close($fh_pam_access);

        if ( $defaultDeny == 0 ) {
            say STDERR "WARNING! There is no entry in /etc/security/access.conf to set default access to DENY.";
        }

        # See if any groups exist in access list
        @accessListtmp = (); # Clear for reuse
        foreach my $entry (@accessList) {
            push(@accessListtmp, users_per_group($entry));
        }
        push (@accessList, @accessListtmp); # Append group members to accessList

        foreach my $entry (@accessList) {
            # See if the user is local.
            if ( grep { $_ eq $entry } @passwdUsers ) { # More robust grep
                next;
            } elsif ( $entry !~ /^\@/ ) {
                push @userListIn, $entry;
            }
            # Resolve nisnetgroup memberships.
            if ( $entry =~ /^\@/ ) {
                my @nisListTmp;
                (my $nis_group = $entry) =~ s/^\@//; # Remove @ prefix
                my $nisList = `$GETENT_CMD netgroup $nis_group 2>/dev/null`;
                chomp $nisList;
                # Parse netgroup output: (host,user,domain) (host,user,domain) ...
                while ($nisList =~ /\(([^,]*),([^,]*),([^)]*)\)/g) {
                    my ($host, $user, $domain) = ($1, $2, $3);
                    push @nisListTmp, $user if $user ne ''; # Add user if not empty
                }
                push @userListIn, @nisListTmp;
            }
        }
        # Unique the @userList array
        my %saw = map { $_ => 1 } @userListIn;
        @userList = sort keys %saw;
    }

    # Look for AllowUser and AllowGroup entries in /etc/ssh/sshd_config
    my @sshAllowUsers;
    my @sshAllowGroups; # This variable is declared but not used to store groups
    my $sshAccessControl = 0;

    unless (defined $SSHD_CONFIG && -f $SSHD_CONFIG) {
        say STDERR "Error: Unable to find sshd_config. Skipping SSH access control check.";
    } else {
        open(my $fh_sshd, "<", $SSHD_CONFIG) || say STDERR "Error: Can't open $SSHD_CONFIG: $!. Skipping SSH access control check.";
        while(my $line = <$fh_sshd>) {
            chomp $line;
            if ( $line =~ /^AllowGroups\s+(.*)/ ) {
                $sshAccessControl = 1;
                say "Access control via ssh's AllowGroups.";
                my @groupList = split(/\s+/, $1);
                foreach my $group_name (@groupList) {
                    my @users_in_group = users_per_group($group_name);
                    foreach my $user_in_group (@users_in_group) {
                        # Only add if not a local user
                        push @sshAllowUsers, $user_in_group unless grep { $_ eq $user_in_group } @passwdUsers;
                    }
                }
            } elsif ($line =~ /^AllowUsers\s+(.*)/ ) {
                $sshAccessControl = 1;
                say "Access control via ssh's AllowUsers.";
                my @users_from_config = split(/\s+/, $1);
                foreach my $user_from_config (@users_from_config) {
                    # Only add if not a local user
                    push @sshAllowUsers, $user_from_config unless grep { $_ eq $user_from_config } @passwdUsers;
                }
            }
        }
        close($fh_sshd);

        # Unique the @sshAllowUsers array
        my %saw_ssh = map { $_ => 1 } @sshAllowUsers;
        @sshAllowUsers = sort keys %saw_ssh;
    }

    # Display user information
    if ( $sshAccessControl == 0 && $pamAccess == 0 ) {
        say STDERR "WARNING: LDAP is enabled without access control!";
    } else {
        say "\nThe following accounts have access to this system via LDAP authentication:";
        my $PRINTF_FORMAT = "%-15s%-10s%-50s\n";
        printf($PRINTF_FORMAT, "Account", "UID", "Name");
        printf($PRINTF_FORMAT, "=======", "===", "====");

        if ( $sshAccessControl == 1 && $pamAccess == 0 ) {
            foreach my $user (@sshAllowUsers) {
                print_user($user);
            }
        } elsif ( $sshAccessControl == 0 && $pamAccess == 1 ) {
            foreach my $user (@userList) {
                print_user($user);
            }
        } elsif ( $sshAccessControl == 1 && $pamAccess == 1 ) {
            # user must exist in both arrays (intersection)
            my %ssh_allowed_map = map { $_ => 1 } @sshAllowUsers;
            foreach my $user (@userList) {
                if (exists $ssh_allowed_map{$user}) {
                    print_user($user);
                }
            }
        }
    }
}

# Verify Remote Root is disabled in sshd_config
say ""; # Newline for separation
unless (defined $SSHD_CONFIG && -f $SSHD_CONFIG) {
    say STDERR "Unable to find sshd_config. Cannot verify Remote Root Login.";
} else {
    open (my $fh_sshd_root, "<", $SSHD_CONFIG) || say STDERR "Error: Can't open $SSHD_CONFIG: $!. Cannot verify Remote Root Login.";
    my $root_login_disabled = 0;
    while (my $line = <$fh_sshd_root>) {
        chomp $line;
        if ($line =~ /^\s*PermitRootLogin\s+no/i) { # Case-insensitive match, allow leading whitespace
            $root_login_disabled = 1;
            last;
        }
    }
    close($fh_sshd_root);

    if ($root_login_disabled) {
        say "Remote Root Login via SSH is disabled.";
    } else {
        say STDERR "WARNING: Remote Root Login via SSH is enabled.";
    }
}
say ""; # Final newline

# --- Sub Routines ---

sub print_user {
    my ($user) = @_;
    return unless defined $user && $user ne '';

    my $PRINTF_FORMAT = "%-15s%-10s%-50s\n";
    my $userInfo = `$GETENT_CMD passwd $user 2>/dev/null`;
    chomp $userInfo;

    if ($userInfo) {
        my ($pAccount, undef, my $pUid, undef, my $pName, undef, undef) = split(/:/, $userInfo, 7);
        printf($PRINTF_FORMAT, $pAccount, $pUid, $pName);
    } else {
        say STDERR "Warning: Could not retrieve user info for '$user' from getent passwd.";
    }
}

sub users_per_group {
    # Returns a list of users for a given group name
    my ($gname) = @_;
    return unless defined $gname && $gname ne '';

    my @groupMembers;

    my $gEntry = `$GETENT_CMD group $gname 2>/dev/null`;
    chomp $gEntry;

    if ($gEntry) {
        my ($gnameT, undef, my $gid, my $glist) = split(/:/, $gEntry, 4);
        if ($glist) {
            push @groupMembers, split(/\,/, $glist);
        }
    } else {
        say STDERR "Warning: Could not retrieve group info for '$gname' from getent group.";
    }

    # Find local users with primary group.
    foreach my $user (keys %usersGID) {
        if (defined $usersGID{$user} && $usersGID{$user} eq $gid) {
            push @groupMembers, $user;
        }
    }

    # Find ldap users with primary group.
    if ( $OS eq 'SunOS' ) {
        # This part assumes $LDAPSEARCH_CMD and $ldapConnect are globally available or passed.
        # For robustness, these should ideally be passed as arguments or the function should be a method of an object.
        # Given the current script structure, we rely on global scope.
        unless (defined $LDAPSEARCH_CMD && defined $ldapConnect && $ldapConnect ne '') {
            say STDERR "Warning: LDAP search command or connection parameters not defined for SunOS. Skipping LDAP group member search.";
        } else {
            my @PrimaryGroup = `$LDAPSEARCH_CMD $ldapConnect "(&(objectclass=user)(msSFU30Name=\*)(gidNumber=$gid))" msSFU30Name 2>/dev/null`;
            foreach my $line (@PrimaryGroup) {
                chomp $line;
                if ( $line =~ /^msSFU30Name:\s*(.*)/ ) {
                    push @groupMembers, $1;
                }
            }
        }
    } else { # Linux
        # For Linux, getent passwd already includes primary GID.
        # We can iterate through all passwd entries and check their GID.
        # This is less efficient if called repeatedly, but safer than parsing 'id -gn' for every user.
        my @all_passwd_entries = `$GETENT_CMD passwd 2>/dev/null`;
        foreach my $entry_line (@all_passwd_entries) {
            chomp $entry_line;
            my @entry_parts = split(/:/, $entry_line);
            if (scalar @entry_parts >= 4 && $entry_parts[3] eq "$gid") { # Check if GID matches
                push @groupMembers, $entry_parts[0]; # Add username
            }
        }
    }

    # Return unique list of members
    my %seen;
    return grep {!$seen{$_}++} @groupMembers;
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
