#!/usr/bin/env bash

# This is DRAFT reference script for detecting a Valkey Cluster
# Split brain, where all primaries in site 1 are down.
# The script will issue a cluster failover takeover in site 2,
# enable partial slot availability if the cluster remains failed after 3 tries,
# reduce slot replicas to 0 (detaching all slaves to independent masters),
# and automatically repair missing/unassigned slots via 'valkey-cli --cluster fix --cluster-fix-with-unreachable-primaries --cluster-yes'.
# All operations consistently use --cluster-announce-hostname.

# Helper: Resolves the --cluster-announce-hostname and port from CLUSTER NODES column 2
# Input format: <ip>:<port>@<cport>[,<hostname>]
resolve_endpoint_hostname() {
    local raw_addr="$1"
    local hostname=""
    local port=""

    if [[ "$raw_addr" == *","* ]]; then
        hostname="${raw_addr##*,}"
        local before_comma="${raw_addr%%,*}"
        local ip_port="${before_comma%%@*}"
        port="${ip_port##*:}"
        echo "${hostname}:${port}"
    else
        # Fallback to IP:port if no announce hostname is configured on the node
        local ip_port="${raw_addr%%@*}"
        echo "$ip_port"
    fi
}

# Checks overall cluster state via CLUSTER INFO across multiple host:port endpoints
check_valkey_cluster() {
    local endpoints=("$@")

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
        host="${node%%:*}"
        port="${node##*:}"
        [ "$host" = "$port" ] && port="6379"

        cli_cmd=(valkey-cli -h "$host" -p "$port")
        info_output=$("${cli_cmd[@]}" CLUSTER INFO 2>/dev/null)
        exit_code=$?

        if [ $exit_code -ne 0 ] || [ -z "$info_output" ]; then
            echo "WARNING: Could not connect to Valkey node at ${host}:${port}. Trying next..." >&2
            continue
        fi

        queried_successfully=true
        echo "Successfully connected to ${host}:${port}" >&2

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
                echo "UNKNOWN: Unexpected cluster state output: '${cluster_state}'." >&2
                return 3
                ;;
        esac
    done

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

        running_primaries=$(echo "$nodes_output" | awk '$3 ~ /master/ && $3 !~ /fail/ && $8 == "connected"' | wc -l | tr -d ' ')
        echo "$running_primaries"
        return 0
    done

    if [ "$queried_successfully" = false ]; then
        echo "CRITICAL: Failed to connect to ALL specified Valkey nodes." >&2
        return 2
    fi
}

# Sets cluster-require-full-coverage to no across all reachable nodes
enable_partial_slot_availability() {
    local endpoints=("$@")
    local node host port res exit_code applied_count=0

    echo "NOTICE: Enabling partial slot availability (cluster-require-full-coverage no) on reachable nodes..." >&2

    for node in "${endpoints[@]}"; do
        [ -z "$node" ] && continue
        node=$(echo "$node" | tr -s ':')
        host="${node%%:*}"
        port="${node##*:}"
        [ "$host" = "$port" ] && port="6379"

        res=$(valkey-cli -h "$host" -p "$port" CONFIG SET cluster-require-full-coverage no 2>&1)
        exit_code=$?

        if [ $exit_code -eq 0 ] && [[ "$res" == *"OK"* ]]; then
            echo "SUCCESS: Set 'cluster-require-full-coverage no' on ${host}:${port}" >&2
            ((applied_count++))
        else
            echo "WARNING: Failed to set full coverage on ${host}:${port}: ${res}" >&2
        fi
    done

    echo "Partial slot availability applied to ${applied_count} node(s)." >&2
}

# Dynamically sets slot replicas to 0 by detaching all active slaves into independent masters
# using --cluster-announce-hostname and disabling automatic replica migration
set_cluster_replicas_to_zero() {
    local endpoints=("$@")
    local node host port nodes_output=""
    local detached_count=0

    # Step 1: Query CLUSTER NODES from an active node
    for node in "${endpoints[@]}"; do
        host="${node%%:*}"
        port="${node##*:}"
        [ "$host" = "$port" ] && port="6379"

        nodes_output=$(valkey-cli -h "$host" -p "$port" CLUSTER NODES 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$nodes_output" ]; then
            break
        fi
    done

    if [ -z "$nodes_output" ]; then
        echo "ERROR: Could not retrieve CLUSTER NODES to set replicas to zero." >&2
        return 1
    fi

    # Step 2: Prevent automatic replica migration across reachable nodes
    for node in "${endpoints[@]}"; do
        host="${node%%:*}"
        port="${node##*:}"
        [ "$host" = "$port" ] && port="6379"
        valkey-cli -h "$host" -p "$port" CONFIG SET cluster-migration-barrier 9999 >/dev/null 2>&1
    done

    # Step 3: Find all connected replica/slave nodes using their announce hostnames
    echo "NOTICE: Promoting all replicas using announce hostnames to establish 0 replicas..." >&2

    local raw_addr
    while IFS= read -r raw_addr; do
        [ -z "$raw_addr" ] && continue
        local target
        target=$(resolve_endpoint_hostname "$raw_addr")
        t_host="${target%%:*}"
        t_port="${target##*:}"

        echo "Detaching replica via announce hostname at ${t_host}:${t_port}..." >&2
        res=$(valkey-cli -h "$t_host" -p "$t_port" CLUSTER FAILOVER TAKEOVER 2>&1)
        if [ $? -eq 0 ] && [[ "$res" == *"OK"* ]]; then
            echo "SUCCESS: Replica ${target} detached into master." >&2
            ((detached_count++))
        else
            echo "WARNING: Failed takeover on ${target}: ${res}" >&2
        fi
    done < <(echo "$nodes_output" | awk '$3 ~ /slave/ && $3 !~ /fail/ && $8 == "connected" {print $2}')

    echo "Slot replicas detached: ${detached_count} node(s) promoted to master." >&2
}

# Executes 'valkey-cli --cluster fix --cluster-fix-with-unreachable-primaries --cluster-yes'
# against the first reachable alive master via its --cluster-announce-hostname
assign_missing_slots_to_surviving_masters() {
    local endpoints=("$@")
    local node host port nodes_output=""
    local target_fix_endpoint=""

    # Step 1: Connect to any accessible node and read cluster topology
    for node in "${endpoints[@]}"; do
        host="${node%%:*}"
        port="${node##*:}"
        [ "$host" = "$port" ] && port="6379"

        nodes_output=$(valkey-cli -h "$host" -p "$port" CLUSTER NODES 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$nodes_output" ]; then
            break
        fi
    done

    if [ -z "$nodes_output" ]; then
        echo "ERROR: Unable to retrieve CLUSTER NODES to determine cluster fix target." >&2
        return 1
    fi

    # Step 2: Extract the first reachable healthy master using its announce hostname
    local raw_master_addr
    while IFS= read -r raw_master_addr; do
        if [ -n "$raw_master_addr" ]; then
            target_fix_endpoint=$(resolve_endpoint_hostname "$raw_master_addr")
            break
        fi
    done < <(echo "$nodes_output" | awk '$3 ~ /master/ && $3 !~ /fail/ && $8 == "connected" {print $2}')

    # Fallback to first reachable endpoint if no healthy master was recognized
    if [ -z "$target_fix_endpoint" ]; then
        for node in "${endpoints[@]}"; do
            host="${node%%:*}"
            port="${node##*:}"
            [ "$host" = "$port" ] && port="6379"
            if valkey-cli -h "$host" -p "$port" PING 2>/dev/null | grep -q PONG; then
                target_fix_endpoint="${host}:${port}"
                break
            fi
        done
    fi

    if [ -z "$target_fix_endpoint" ]; then
        echo "CRITICAL: No reachable Valkey master node found to run cluster fix!" >&2
        return 1
    fi

    echo "Running 'valkey-cli --cluster fix' against target ${target_fix_endpoint} with unreachable primaries auto-fix..." >&2

     echo "yes" | valkey-cli --cluster fix "$target_fix_endpoint" \
        --cluster-fix-with-unreachable-primaries  \
        --cluster-yes
    local fix_exit_code=$?

    if [ $fix_exit_code -eq 0 ]; then
        echo "SUCCESS: Cluster fix completed successfully on ${target_fix_endpoint}." >&2
        return 0
    else
        echo "ERROR: Cluster fix failed with exit code ${fix_exit_code} on ${target_fix_endpoint}." >&2
        return $fix_exit_code
    fi
}

# Executes CLUSTER FAILOVER TAKEOVER on target endpoints, skipping nodes that are already primaries
trigger_failover_takeover_on_replicas() {
    local target_replicas=("$@")

    if [ ${#target_replicas[@]} -eq 0 ]; then
        echo "CRITICAL: No replica endpoints provided to trigger failover." >&2
        return 2
    fi

    local raw_endpoint clean_endpoint host port role failover_res exit_code
    local success_count=0
    local fail_count=0
    local skipped_count=0

    echo "Starting takeover execution on specified targets..." >&2

    for raw_endpoint in "${target_replicas[@]}"; do
        [ -z "$raw_endpoint" ] && continue

        clean_endpoint=$(echo "$raw_endpoint" | tr -s ':')
        host="${clean_endpoint%%:*}"
        port="${clean_endpoint##*:}"
        [ "$host" = "$port" ] && port="6379"

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

        echo "Issuing 'CLUSTER FAILOVER TAKEOVER' to replica at announce hostname ${host}:${port}..." >&2

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

# --- Configuration & Main Loop ---

CLUSTER_NODES_TO_CHECK=("valkey-server-7011:7011" "valkey-server-7012:7012" "valkey-server-7013:7013" "valkey-server-7014:7014" "valkey-server-7015:7015" "valkey-server-7016:7016" "valkey-server-7021:7021" "valkey-server-7022:7022" "valkey-server-7023:7023" "valkey-server-7024:7024" "valkey-server-7025:7025" "valkey-server-7026:7026")

REPLICAS_TO_PROMOTE=("valkey-server-7014:7014" "valkey-server-7015:7015" "valkey-server-7016:7016" "valkey-server-7021:7021" "valkey-server-7022:7022" "valkey-server-7023:7023" "valkey-server-7024:7024" "valkey-server-7025:7025" "valkey-server-7026:7026")

TAKEOVER_TRIES=0
FAILED_COUNT=0
PARTIAL_AVAILABILITY_APPLIED=false
SLOTS_REASSIGNED=false
REPLICAS_SET_TO_ZERO=false

while true; do
    if check_valkey_cluster "${CLUSTER_NODES_TO_CHECK[@]}"; then
        echo "Cluster is healthy, proceeding with normal operations..."
        TAKEOVER_TRIES=0
        FAILED_COUNT=0
        PARTIAL_AVAILABILITY_APPLIED=false
        SLOTS_REASSIGNED=false
        REPLICAS_SET_TO_ZERO=false
    else
        echo "Cluster check failed with exit status $?"

        ((FAILED_COUNT++))
        echo "Failed Count: $FAILED_COUNT"

        PRIMARY_COUNT=$(count_valkey_running_primaries "${CLUSTER_NODES_TO_CHECK[@]}")
        echo "Running primaries count: $PRIMARY_COUNT"

        if [ "${PRIMARY_COUNT:-1}" -eq 0 ]; then
            ((TAKEOVER_TRIES++))
            echo "Takeover attempt #${TAKEOVER_TRIES}..."
            trigger_failover_takeover_on_replicas "${REPLICAS_TO_PROMOTE[@]}"
        fi

        # Conditions met: Fail check greater than 3 (FAILED_COUNT > 3) and primaries less than 3
        if [ "$FAILED_COUNT" -gt 3 ] && [ "${PRIMARY_COUNT:-1}" -lt 3 ]; then

            # 1. Trigger takeover on remaining target replicas
            ((TAKEOVER_TRIES++))
            echo "Takeover attempt #${TAKEOVER_TRIES} due to < 3 primaries..."
            trigger_failover_takeover_on_replicas "${REPLICAS_TO_PROMOTE[@]}"

            # 2. Convert all remaining replicas to independent masters (0 replicas configuration)
            if [ "$REPLICAS_SET_TO_ZERO" = false ]; then
                echo "Setting cluster slot replicas to 0 dynamically using announce hostnames..."
                set_cluster_replicas_to_zero "${CLUSTER_NODES_TO_CHECK[@]}"
                REPLICAS_SET_TO_ZERO=true
            fi

            sleep 2

            # 3. Fix unassigned slots and unreachable primaries automatically
            if [ "$SLOTS_REASSIGNED" = false ]; then
                echo "Executing valkey-cli cluster fix with unreachable primaries..."
                assign_missing_slots_to_surviving_masters "${CLUSTER_NODES_TO_CHECK[@]}"
                SLOTS_REASSIGNED=true
            fi
        fi
    fi

    echo "Sleeping 30 seconds ..."
    sleep 30
done