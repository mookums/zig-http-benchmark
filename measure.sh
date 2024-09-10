#! /usr/bin/env bash

# Extact the core count.
CORE_COUNT=$(lscpu | awk -F: 'NR==5 {print $2}' | tr -d "\n ")
#echo "Available Cores: $CORE_COUNT"
TSK_SRV_INTERVAL="0-$(($CORE_COUNT/2))"
#echo "Task Srv Interval: $TSK_SRV_INTERVAL"
TSK_LOAD_INTERVAL="$((($CORE_COUNT/2) + 1))-$CORE_COUNT"
#echo "Task Load Interval: $TSK_LOAD_INTERVAL"

THREADS=$(($CORE_COUNT / 2))
connectionsArray=(50 100 200 300 400 500 600 700 800)
DURATION_SECONDS=10

SUBJECT=$1

TSK_SRV="taskset -c $TSK_SRV_INTERVAL"
TSK_LOAD="taskset -c $TSK_LOAD_INTERVAL"

if [ "$SUBJECT" = "" ] ; then
    echo "usage: $0 [zap, zigstd, httpz, zzz]"
    exit 1
fi


zig build -Doptimize=ReleaseFast -Dthreads=$THREADS "$SUBJECT" > /dev/null

printf "" > "result/$SUBJECT.csv"
for conn_count in ${connectionsArray[@]}; do
    $TSK_SRV ./zig-out/bin/"$SUBJECT" 2&> /dev/null &
    PID=$!
    URL=http://127.0.0.1:3000
    sleep 3
    echo "========================================================================"
    echo "                          $SUBJECT @ $conn_count"
    echo "========================================================================"
    RPS=$($TSK_LOAD wrk -c $conn_count -t $THREADS -d $DURATION_SECONDS --latency $URL | tee /dev/tty | awk -F: 'NR==12 {print $2}' | tr -d "\n ")
    printf "$conn_count, $RPS\n" >> "result/$SUBJECT.csv"
    kill $(lsof -t -i:3000) 2&> /dev/null
done
