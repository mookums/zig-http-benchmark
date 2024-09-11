#! /usr/bin/env bash

# Extact the core count.
CORE_COUNT=$(lscpu | awk -F: '/^CPU\(s\):/ {print $2}' | tr -d " \n")
echo "Available Cores: $CORE_COUNT"
TSK_SRV_INTERVAL="0-$(($CORE_COUNT / 2 - 1))"
echo "Task Srv Interval: $TSK_SRV_INTERVAL"
TSK_LOAD_INTERVAL="$(($CORE_COUNT/2))-$(($CORE_COUNT - 1))"
echo "Task Load Interval: $TSK_LOAD_INTERVAL"

THREADS=$(($CORE_COUNT / 2))
CONNECTIONS=(50 100 200 300 400 500 600 700 800)
DURATION_SECONDS=$1

SUBJECTS="${@:2}"
echo "Benchmarking: $SUBJECTS"

TSK_SRV="taskset -c $TSK_SRV_INTERVAL"
TSK_LOAD="taskset -c $TSK_LOAD_INTERVAL"

declare -A rps_array

append_to_array() {
    local conn_count=$1
    local rps=$2

    if [ -z "{rps_array[$conn_count]}" ]; then
        rps_array[$conn_count]="$rps"
    else
        rps_array[$conn_count]+=",$rps"
    fi
}

cleanup() {
    echo "Cleaning..."
    kill -15 $(lsof -t -i:3000) 2> /dev/null || true
    wait
}

header="connections"

kill -9 $(lsof -t -i:3000) 2> /dev/null

for subject in ${SUBJECTS[@]}; do
    if [ -z "$subject" ] ; then
        echo "usage: $0 <list of subjects>"
        exit 1
    fi

    case "$subject" in
        zap|httpz|zzz|zigstd)
            zig build -Doptimize=ReleaseFast -Dthreads=$THREADS "$subject" > /dev/null
            ;;
        *)
            echo "Unknown subject: $subject"
            continue
            ;;
    esac

    header+=",$subject"

    cleanup
    $TSK_SRV ./zig-out/bin/"$subject" 2> /dev/null &
    PID=$!
    URL=http://127.0.0.1:3000

    printf "waiting"
    until curl --output /dev/null --silent --fail --max-time 1 http://127.0.0.1:3000; do
        printf '.'
        sleep 1
    done
    printf '\r'

    for conn_count in ${CONNECTIONS[@]}; do
        echo "========================================================================"
        echo "                      $subject @ $conn_count Conn" 
        echo "========================================================================"
        RPS=$($TSK_LOAD wrk -c $conn_count -t $THREADS -d $DURATION_SECONDS --latency $URL | tee /dev/tty | awk -F: 'NR==12 {print $2}' | tr -d "\n ")
        append_to_array "$conn_count" "$RPS"
    done

    kill -15 $PID 2> /dev/null
    wait $PID 2> /dev/null || true
done

printf "%s\n" "$header" > "result/benchmarks.csv"

for conn_count in ${CONNECTIONS[@]}; do
    rps_values="${rps_array[$conn_count]}"
    printf "%d%s\n" "$conn_count" "$rps_values" >> "result/benchmarks.csv"
done

