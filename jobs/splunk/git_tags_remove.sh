#!/usr/bin/env bash

export include="authman|bacon|dashkitmapsupport|dashKitinteractivemapsupport|kotlin|phantom|jubilee|mapbox|poutine|scpauth|hotfix|spacebridge|splunk|ribs|shortribs|sirloin|asgard|shared|release|prism|sausage|volib|77.77."

for i in $(git tag |grep -Ei $include); do git push origin :refs/tags/"$i"; done

for i in $(git tag |grep -v Short); do git push origin :refs/tags/"$i"; done

for i in $(git tag |grep -Ei $include); do git tag -d "$i"; done

for i in $(git tag |grep -v Short); do git tag -d "$i"; done
