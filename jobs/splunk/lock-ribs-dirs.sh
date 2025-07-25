#!/usr/bin/env bash

DIRS="AuthMan \
    Bacon \
    Butter \
    DashKit \
    DashKitMapSupport \
    Jubilee \
    PhantomSDK \
    Poutine \
    SCPAuthSDK \
    Sausage \
    ShortRibs \
    Sirloin \
    Spacebridge \
    SplunkAnalytics \
    SplunkCloudAuth \
    SplunkNotificationService \
    VictorOpsLib"

for d in $DIRS; do
  IFS=$'\n'
  for i in $(find $d/* -type f ! -name '.gitkeep'); do
    git lfs lock $i
  done
done
