#!/bin/bash
set -euxo pipefail

kafka-produce-perf-test \
    --num-records $((10**8)) \
    --record-size $((2**10)) \
    --topic test \
    --throughput $((2**30)) \
    --producer-props \
        acks=1 \
        bootstrap.servers=${1:=10.0.0.4}:9092 \
        compression.type=none \
        retries=0 \
        max.in.flight.requests.per.connection=5 \
        batch.size=16384 \
        linger.ms=0
