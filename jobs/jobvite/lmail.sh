#!/usr/bin/env bash

svn update ~/SVN/Operations
echo $1@jobvite.com $1@exchange.jobvite.com >> ~/SVN/Operations/sendmail/virtusertable 
cat ~/SVN/Operations/sendmail/virtusertable |sort -d > ~/SVN/Operations/sendmail/virtusertable.new
mv ~/SVN/Operations/sendmail/virtusertable.new ~/SVN/Operations/sendmail/virtusertable
svn commit ~/SVN/Operations/sendmail/virtusertable -m "Adding users to Lmail."
