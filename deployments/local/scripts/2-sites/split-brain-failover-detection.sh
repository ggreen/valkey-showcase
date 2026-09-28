#!/usr/bin/env bash

# This is DRAFT reference scripts for detection a Valkey Cluster
# Split brain, where all primaries in site 1 are down.
# It script will issue a cluster failover command in site 2,
# if all primaries are not available.

# Checks overall cluster state via CLUSTER INFO across multiple host:port endpoints
check_valkey_cluster() {
    local endpoints=("$@")

    # Fallback to defaults or environment variables if no arguments passed
    if [ ${#endpoints[@]} -eq 0 ]; then
        if [ -n "$VALKEY_NODES" ]; then
            read -r -a endpoints <<< "$VALKEY_NODES"
        else
            endpoints=("${VALKEY_HOST:-localhost}:${VALKEY_PORT:-7001}")
        fi
    fi

    local node host port cli_cmd info_output exit_code cluster_state
    local queried_successfully=false

    for node in "${endpoints[@]}"; do
        # Split host:port (defaults port to 6379 if missing)
        host="${node%%:*}"
        port="${node##*:}"
        [ "$host" = "$port" ] && port="6379"

        cli_cmd=(valkey-cli -h "$host" -p "$port")
        info_output=$("${cli_cmd[@]}" CLUSTER INFO 2>/dev/null)
        exit_code=$?

        # Skip to next node if connection fails
        if [ $exit_code -ne 0 ] || [ -z "$info_output" ]; then
            echo "WARNING: Could not connect to Valkey node at ${host}:${port}. Trying next..." >&2
            continue
        fi

        queried_successfully=true
        echo "Successfully connected to ${host}:${port}" >&2

        # Extract cluster_state value
        cluster_state=$(echo "$info_output" | awk -F: '/cluster_state/ {print $2}' | tr -d '\r')

        case "$cluster_state" in
            "ok")
                echo "OK: Valkey cluster state is operational (ok)." >&2
                return 0
                ;;
            "fail")
                echo "CRITICAL: Valkey cluster state is failed (fail)." >&2
                return 1
                ;;
            *)
                echo "UNKNOWN: Unexpected cluster state standard output: '${cluster_state}'." >&2
                return 3
                ;;
        esac
    done

    # If loop finishes without querying any node
    if [ "$queried_successfully" = false ]; then
        echo "CRITICAL: Failed to connect to ALL specified Valkey nodes." >&2
        return 2
    fi
}

# Counts total active/running primary (master) nodes across the cluster
count_valkey_running_primaries() {
    local endpoints=("$@")

    if [ ${#endpoints[@]} -eq 0 ]; then
        if [ -n "$VALKEY_NODES" ]; then
            read -r -a endpoints <<< "$VALKEY_NODES"
        else
            endpoints=("${VALKEY_HOST:-localhost}:${VALKEY_PORT:-7001}")
        fi
    fi

    local node host port cli_cmd nodes_output exit_code
    local running_primaries
    local queried_successfully=false

    for node in "${endpoints[@]}"; do
        host="${node%%:*}"
        port="${node##*:}"
        [ "$host" = "$port" ] && port="6379"

        cli_cmd=(valkey-cli -h "$host" -p "$port")
        nodes_output=$("${cli_cmd[@]}" CLUSTER NODES 2>/dev/null)
        exit_code=$?

        if [ $exit_code -ne 0 ] || [ -z "$nodes_output" ]; then
            echo "WARNING: Could not connect to Valkey node at ${host}:${port}. Trying next..." >&2
            continue
        fi

        queried_successfully=true

        # Filter for master nodes ($3 ~ /master/), ensure state is connected ($8 == "connected"),
        # and verify flags do NOT contain fail ($3 !~ /fail/)
        running_primaries=$(echo "$nodes_output" | awk '$3 ~ /master/ && $3 !~ /fail/ && $8 == "connected"' | wc -l | tr -d ' ')

        # Echo count to stdout for capture
        echo "$running_primaries"
        return 0
    done

    if [ "$queried_successfully" = false ]; then
        echo "CRITICAL: Failed to connect to ALL specified Valkey nodes." >&2
        return 2
    fi
}


# Executes CLUSTER FAILOVER TAKEOVER on target endpoints, skipping nodes that are already primaries
trigger_failover_takeover_on_replicas() {
    local target_replicas=("$@")

    if [ ${#target_replicas[@]} -eq 0 ]; then
        echo "CRITICAL: No replica endpoints provided to trigger failover." >&2
        return 2
    fi

    local raw_endpoint clean_endpoint host port node_info role failover_res exit_code
    local success_count=0
    local fail_count=0
    local skipped_count=0

    echo "Starting takeover execution on specified targets..." >&2

    for raw_endpoint in "${target_replicas[@]}"; do
        [ -z "$raw_endpoint" ] && continue

        # Clean up accidental double colons (e.g., 'host::port' -> 'host:port')
        clean_endpoint=$(echo "$raw_endpoint" | tr -s ':')

        # Split host:port
        host="${clean_endpoint%%:*}"
        port="${clean_endpoint##*:}"
        [ "$host" = "$port" ] && port="6379"

        # Check the role of the node first
        role=$(valkey-cli -h "$host" -p "$port" INFO replication 2>/dev/null | awk -F: '/role:/ {print $2}' | tr -d '\r')

        if [ "$role" = "master" ]; then
            echo "SKIP: Node ${host}:${port} is already a primary (master). No takeover needed." >&2
            ((skipped_count++))
            ((success_count++))
            continue
        elif [ -z "$role" ]; then
            echo "ERROR: Unable to connect or read role from ${host}:${port}." >&2
            ((fail_count++))
            continue
        fi

        echo "Issuing 'CLUSTER FAILOVER TAKEOVER' to replica at ${host}:${port}..." >&2

        failover_res=$(valkey-cli -h "$host" -p "$port" CLUSTER FAILOVER TAKEOVER 2>&1)
        exit_code=$?

        if [ $exit_code -eq 0 ] && [[ "$failover_res" == *"OK"* ]]; then
            echo "SUCCESS: Takeover initiated on ${host}:${port}." >&2
            ((success_count++))
        else
            echo "ERROR: Failed takeover on ${host}:${port}. Output: ${failover_res}" >&2
            ((fail_count++))
        fi
    done

    echo "Takeover sequence completed. Successful: ${success_count} (Skipped/Already Master: ${skipped_count}), Failed: ${fail_count}." >&2

    if [ "$fail_count" -gt 0 ]; then
        return 1
    fi
    return 0
}

# --- Example Usage --- Change the host:ports to reflect your local environment

CLUSTER_NODES_TO_CHECK=("valkey-site1-server-1:7001" "valkey-site1-server-2:7002" "valkey-site1-server-3:7003" "valkey-site2-server-1:7004" "valkey-site2-server-2:7005" "valkey-site2-server-3:7006")
REPLICAS_TO_PROMOTE=("valkey-site2-server-1:7004" "valkey-site2-server-2:7005" "valkey-site2-server-3::7006")

while true; do
    if check_valkey_cluster "${CLUSTER_NODES_TO_CHECK[@]}"; then
        echo "Cluster is healthy, proceeding with deployment..."
    else
        echo "Cluster check failed with exit status $?"

        # Capture down primaries count
        PRIMARY_COUNT=$(count_valkey_running_primaries "${CLUSTER_NODES_TO_CHECK[@]}")
        echo "Running primaries count: $PRIMARY_COUNT"
        if [ "${PRIMARY_COUNT:-1}" -eq 0 ]; then

          # Trigger force takeover on all replicas matching site2 IPs or hostnames
          trigger_failover_takeover_on_replicas "${REPLICAS_TO_PROMOTE[@]}"
        fi
    fi

    echo "Sleeping 30 seconds ..."
    sleep 30
done


