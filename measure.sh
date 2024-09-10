#! /usr/bin/env bash
THREADS=4
CONNECTIONS=400
DURATION_SECONDS=10

SUBJECT=$1

TSK_SRV="taskset -c 0,1,2,3"
TSK_LOAD="taskset -c 4,5,6,7"

if [ "$SUBJECT" = "" ] ; then
    echo "usage: $0 [zap, zigstd, httpz, zzz]"
    exit 1
fi

kill -9 $(lsof -t -i:3000) 2&> /dev/null

zig build -Doptimize=ReleaseFast "$SUBJECT" > /dev/null
$TSK_SRV ./zig-out/bin/"$SUBJECT" 2&> /dev/null &
PID=$!
URL=http://127.0.0.1:3000

sleep 1
echo "========================================================================"
echo "                          $SUBJECT"
echo "========================================================================"
$TSK_LOAD wrk -c $CONNECTIONS -t $THREADS -d $DURATION_SECONDS --latency $URL 

kill $PID
