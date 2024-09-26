#! /usr/bin/env bash

# Up the file limit.
ulimit -n 4096

# Extact the core count.
CORE_COUNT=$(lscpu | awk -F: '/^CPU\(s\):/ {print $2}' | tr -d " \n")
echo "Available Cores: $CORE_COUNT"
TSK_SRV_INTERVAL="0-$(($CORE_COUNT / 2 - 1))"
echo "Task Srv Interval: $TSK_SRV_INTERVAL"
TSK_LOAD_INTERVAL="$(($CORE_COUNT/2))-$(($CORE_COUNT - 1))"
echo "Task Load Interval: $TSK_LOAD_INTERVAL"

THREADS=$(($CORE_COUNT / 2))
CONNECTIONS=(100 200 300 400 500 600 700 800 900 1000 1100 1300 1500 1800)
BENCHMARKING_TOOL=$1
DURATION_SECONDS=$2

SUBJECTS="${@:3}"
echo "Benchmarking: $SUBJECTS"

TSK_SRV="taskset -c $TSK_SRV_INTERVAL"
TSK_LOAD="taskset -c $TSK_LOAD_INTERVAL"

REQUEST_CSV="./result/request.csv"
MEMORY_CSV="./result/memory.csv"

measure_peak_memory() {
    local name=$1
    local duration=$2
    local peak_mem=0
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))

    # for duration
    while [ $(date +%s) -lt $end_time ]; do
        local current_mem=0
        # this is important for zap that spawns more.
        for p in $(pgrep $name); do
            local mem=$(ps -o rss= -p $p | tr -d ' ')
            current_mem=$((current_mem + mem))
        done
        if [ $current_mem -gt $peak_mem ]; then
            peak_mem=$current_mem
        fi
        sleep 0.1
    done

    echo $peak_mem
}

declare -A rps_array
declare -A mem_array

append_to_rps() {
    local conn_count=$1
    local rps=$2

    if [ -z "{rps_array[$conn_count]}" ]; then
        rps_array[$conn_count]="$rps"
    else
        rps_array[$conn_count]+=",$rps"
    fi
}

append_to_mem() {
    local subject=$1
    local mem=$2

    mem_array[$subject]="$mem"
}

cleanup() {
    echo "Cleaning..."
    kill -15 $(lsof -t -i:3000) 2> /dev/null || true
    wait
}

rps_header="connections"
mem_header="memory,server"

kill -9 $(lsof -t -i:3000) 2> /dev/null

for subject in ${SUBJECTS[@]}; do
    if [ -z "$subject" ] ; then
        echo "usage: $0 <list of subjects>"
        exit 1
    fi

    case "$subject" in
        zap|httpz|zzz|zzz_busyloop|zzz_epoll|zzz_iouring)
            zig build -Doptimize=ReleaseFast -Dthreads=$THREADS "$subject" 2> /dev/null
            EXEC="./zig-out/bin/$subject"
            ;;
        go|fasthttp|gnet)
            cd impl/$subject && go build -o "$subject" main.go > /dev/null && cd ../../
            EXEC="./impl/$subject/$subject"
            ;;
        bun)
            EXEC="bun run ./impl/bun/index.ts"
            ;;
        axum)
            cargo build --release --manifest-path=impl/axum/Cargo.toml 2> /dev/null
            EXEC="./impl/axum/target/release/axum-benchmark"
            ;;
        *)
            echo "Unknown subject: $subject"
            continue
            ;;
    esac

    rps_header+=",$subject"

    cleanup

    printf "running: %s!\n" "$EXEC"
    $TSK_SRV $EXEC &
    PID=$!
    URL=http://127.0.0.1:3000

    until curl --output /dev/null --silent --fail --max-time 1 http://127.0.0.1:3000; do
        printf '.'
        sleep 1
    done
    printf '\n'

    PEAK_MEM=0
    for conn_count in ${CONNECTIONS[@]}; do
        echo "========================================================================"
        echo "                          $subject @ $conn_count Conn" 
        echo "========================================================================"

        measure_peak_memory $subject $DURATION_SECONDS > /tmp/peak_mem_$subject &
        MEM_PID=$!
        
        case "$BENCHMARKING_TOOL" in
            wrk)
                RPS=$($TSK_LOAD wrk -c $conn_count -t $THREADS -d $DURATION_SECONDS --latency $URL | tee /dev/tty | awk -F: '/^Requests\/sec:/ {print $2}' | tr -d "\n ")
                append_to_rps "$conn_count" "$RPS"
                ;;
            oha)
                OHA_JSON=$($TSK_LOAD oha -c $conn_count -z $(printf "%ssec" "$DURATION_SECONDS") --no-tui $URL -j)
                RPS=$(echo $OHA_JSON | jq '.summary.requestsPerSec')
                printf "%s\n" "$(echo $OHA_JSON  | jq ".summary")"
                append_to_rps "$conn_count" "$RPS"
                ;;
            *)
                echo "not a valid benchmarking tool (wrk, oha)"
                exit 1
                ;;
        esac

        wait $MEM_PID
        CONN_PEAK_MEM=$(cat /tmp/peak_mem_$subject)
        rm /tmp/peak_mem_$subject

        if [ $CONN_PEAK_MEM -gt $PEAK_MEM ]; then
            PEAK_MEM=$CONN_PEAK_MEM
        fi
    done

    PIDS=$(lsof -t -i:3000)
    for pid in ${PIDS[@]}; do
        kill -15 $pid 2> /dev/null
        wait $pid 2> /dev/null || true
    done

    printf "Peak Mem: %d kB\n" "$PEAK_MEM"
    append_to_mem "$subject" "$PEAK_MEM"

    kill -15 $PID 2> /dev/null
    wait $PID 2> /dev/null || true
done

printf "%s\n" "$rps_header" > $REQUEST_CSV 
for conn_count in ${CONNECTIONS[@]}; do
    rps_values="${rps_array[$conn_count]}"
    printf "%d%s\n" "$conn_count" "$rps_values" >> $REQUEST_CSV 
done

printf "%s\n" "$mem_header" > $MEMORY_CSV 
for subject in ${SUBJECTS[@]}; do
    mem_value="${mem_array[$subject]}"
    printf "%d,%s\n" "$mem_value" "$subject" >> $MEMORY_CSV 
done
