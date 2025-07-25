#!/usr/bin/expect

#spawn ssh ssuser\@$1
#set password "$%^&ss@mvsn!"
#expect "ssuser@$1's password:"
#send "$password\r"
#expect "\$"
#send "cp /c/site/cg/smp.dll/c/site/cg/smp_raph.dll\r"
#send "exit\r"
spawn scp test ssuser\@$:/c/site/cg/
set password "$%^&ss@mvsn!"
expect "ssuser@$'s password:"
send "$password\r"
expect "\$"
expect eof
exit 0
