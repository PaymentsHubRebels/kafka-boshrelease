#!/bin/bash

replication_factor=1
partitions=1

re='^[0-9]+$'
if [[ $1 =~ $re ]] ; then
  replication_factor=${1:-1}
  shift
fi

if [[ $1 =~ $re ]] ; then
  partitions=${1:-1}
  shift
fi

cat <<YAML
- type: replace
  path: /instance_groups/name=kafka/jobs/name=kafka/properties?/topics
  value:
YAML
for topic_name in $@; do
  cat <<YAML
  - name: $topic_name
    replication_factor: ${replication_factor}
    partitions: ${partitions}
YAML
done
