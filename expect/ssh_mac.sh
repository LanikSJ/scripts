#!/usr/bin/expect
# Usage: ./script host "command"

log_user 0
set timeout 30

set host  [lindex $argv 0]
set command [lindex $argv 1]

spawn /usr/bin/ssh $host
match_max [expr 32 * 1024]

expect {
   -re "~ %" {send "$command\r"}
   timeout {puts "Error reading prompt on $host -> $expect_out(buffer)";exit}
}

expect -re " ~ %"
set output $expect_out(buffer)
send "exit\r"
puts "$output\r\n"
