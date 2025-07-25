#!/usr/bin/expect
# Usage: ./expect.sh host "command"

log_user 0
set timeout 10
set userid  "root"
set pass  "blu3H@tT0p"

set host  [lindex $argv 0] 
set command [lindex $argv 1]

# grab the password
#stty -echo
#send_user -- "Password for $userid@$host: "
#expect_user -re "(.*)\n"
#send_user "\n"
#stty echo
#set pass $expect_out(1,string)

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
