#!/usr/bin/env bash
# shellcheck disable=SC2140

DBINSTACES="merlin-emu-main-p-artifactory01,
        merlin-util-main-p-artifactory01,
        merlin-util-main-p-bitbucket02,
        merlin-util-main-p-confluence03,
        merlin-util-main-p-jira02"

TICKET="cicd-44637"

for i in ${DBINSTACES//,/ }; do
    # Extract database name (5th field when split by "-")
    DBNAME=$(echo "$i" | cut -d "-" -f 5)
    aws --profile merlin-sso rds describe-db-snapshots --db-instance-identifier "$i" --db-snapshot-identifier "$TICKET"-"$DBNAME" \
        --query 'DBSnapshots[].{Instance:DBInstanceIdentifier,Snapshot:DBSnapshotIdentifier,Status:Status}' --output table
done
