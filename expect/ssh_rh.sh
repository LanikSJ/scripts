#!/usr/bin/expect
# Usage: ./script host "command"

log_user 0
set timeout 10
set userid  "root"
set pass  "***REMOVED***"

set host  [lindex $argv 0] 
set command [lindex $argv 1]

spawn /usr/bin/ssh -l $userid $host
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

expect {
   -re "\~]#" {send "term len 0\r"}
   timeout {puts "Error reading prompt on $host -> $expect_out(buffer)";exit}
}

expect {
   -re "\~]#" {send "$command\r"}

   timeout {puts "Error reading prompt on $host -> $expect_out(buffer)";exit}
}

expect -re "~]#"
set output $expect_out(buffer)
send "exit\r"
puts "$output\r\n"
