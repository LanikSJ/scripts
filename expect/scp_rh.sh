#!/usr/bin/expect
# Usage: ./script host "command"

log_user 0
set timeout 10
set userid  "root"
set pass  "***REMOVED***"

set host  [lindex $argv 0] 
set file1  [lindex $argv 1]
set file2  [lindex $argv 2]

spawn /usr/bin/scp $file1 $userid@$host:$file2
match_max [expr 32 * 1024]

expect {
    -re "RSA key fingerprint" {send "yes\r"}
    timeout {puts "$host is a known host"}
}

expect {
     -re "username: " {send "$userid\r"} 
     -re "(P|p)assword: " {send "$pass\r"}
     -re "Warning:" {send "$pass\r"}
     -re "Connection refused" {puts "Host error -> $expect_out(buffer)";exit}
     -re "Connection closed"  {puts "Host error -> $expect_out(buffer)";exit}
     -re "no address.*" {puts "Host error -> $expect_out(buffer)";exit}

     timeout {puts "Timeout error. Is $host down or unreachable??";exit}
}

expect 100%
sleep 1
set output $expect_out(buffer)
puts "$output\r\n"
