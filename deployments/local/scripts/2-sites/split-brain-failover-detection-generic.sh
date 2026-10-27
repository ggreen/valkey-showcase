#!/usr/bin/env bash

# This is DRAFT reference script for detecting a Valkey Cluster
# Split brain, where all primaries in site 1 are down.
# The script will issue a cluster failover takeover in site 2,
# enable partial slot availability if the cluster remains failed after 3 tries,
# and assign all missing slots directly via CLUSTER ADDSLOTS across surviving masters using announce hostnames.

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

# Identifies all missing/uncovered slots (0-16383) and assigns them via CLUSTER ADDSLOTS
# using the --cluster-announce-hostname of the surviving masters, followed by CLUSTER BUMPEPOCH
assign_missing_slots_to_surviving_masters() {
    local endpoints=("$@")
    local node host port nodes_output=""
    local healthy_masters=()

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
        echo "ERROR: Unable to retrieve CLUSTER NODES from any endpoint." >&2
        return 1
    fi

    # Step 2: Extract reachable healthy master host:port endpoints using announce hostname
    # Format of field 2: <ip>:<port>@<cport>[,<hostname>]
    while IFS= read -r ep; do
        [ -n "$ep" ] && healthy_masters+=("$ep")
    done < <(echo "$nodes_output" | awk '$3 ~ /master/ && $3 !~ /fail/ && $8 == "connected" {
        addr = $2

        # Check if an announce hostname is present after a comma
        if (index(addr, ",") > 0) {
            split(addr, parts, ",")
            hostname = parts[2]

            # Extract port from IP:PORT@CPORT
            split(parts[1], ipparts, "@")
            split(ipparts[1], hp, ":")
            port = hp[2]

            print hostname ":" port
        } else {
            # Fallback to IP address if no announce hostname was configured
            sub(/@.*/, "", addr)
            print addr
        }
    }')

    if [ ${#healthy_masters[@]} -eq 0 ]; then
        echo "CRITICAL: No healthy master nodes available to adopt missing slots!" >&2
        return 1
    fi

    echo "Found ${#healthy_masters[@]} healthy master target(s): ${healthy_masters[*]}" >&2

    # Step 3: Scan slots 0-16383. Only slots served by healthy masters are considered covered.
    local missing_slots=()
    while IFS= read -r s; do
        [ -n "$s" ] && missing_slots+=("$s")
    done < <(echo "$nodes_output" | awk '
    BEGIN {
        for (i = 0; i <= 16383; i++) slot[i] = 0;
    }
    $3 ~ /master/ && $3 !~ /fail/ && $8 == "connected" {
        for (i = 9; i <= NF; i++) {
            if ($i ~ /^\[/) continue; # Ignore migrating/importing markers
            if ($i ~ /^[0-9]+-[0-9]+$/) {
                split($i, bounds, "-")
                for (s = bounds[1]; s <= bounds[2]; s++) slot[s] = 1;
            } else if ($i ~ /^[0-9]+$/) {
                slot[$i] = 1;
            }
        }
    }
    END {
        for (i = 0; i <= 16383; i++) {
            if (slot[i] == 0) print i;
        }
    }')

    local total_missing=${#missing_slots[@]}
    if [ "$total_missing" -eq 0 ]; then
        echo "No missing slots found. All 16,384 slots are covered by active masters." >&2
        return 0
    fi

    echo "Found ${total_missing} missing slot(s). Distributing via CLUSTER ADDSLOTS using announce hostnames..." >&2

    # Step 4: Distribute missing slots evenly across healthy masters using CLUSTER ADDSLOTS
    local num_masters=${#healthy_masters[@]}
    local slots_per_master=$(( (total_missing + num_masters - 1) / num_masters ))
    local BATCH_SIZE=500

    local current_idx=0
    for ((m = 0; m < num_masters; m++)); do
        local target="${healthy_masters[$m]}"
        local t_host="${target%%:*}"
        local t_port="${target##*:}"

        local assigned_count=0
        local batch=()

        while [ $assigned_count -lt $slots_per_master ] && [ $current_idx -lt $total_missing ]; do
            batch+=("${missing_slots[$current_idx]}")
            ((current_idx++))
            ((assigned_count++))

            # Dispatch when reaching BATCH_SIZE
            if [ ${#batch[@]} -ge $BATCH_SIZE ]; then
                local res
                res=$(valkey-cli -h "$t_host" -p "$t_port" CLUSTER ADDSLOTS "${batch[@]}" 2>&1)
                if [ $? -ne 0 ]; then
                    echo "WARNING: Failed to run CLUSTER ADDSLOTS batch on ${target}: ${res}" >&2
                fi
                batch=()
            fi
        done

        # Dispatch any remaining slots in this master's share
        if [ ${#batch[@]} -gt 0 ]; then
            local res
            res=$(valkey-cli -h "$t_host" -p "$t_port" CLUSTER ADDSLOTS "${batch[@]}" 2>&1)
            if [ $? -ne 0 ]; then
                echo "WARNING: Failed to run CLUSTER ADDSLOTS batch on ${target}: ${res}" >&2
            fi
        fi

        echo "Issued CLUSTER ADDSLOTS for ${assigned_count} slot(s) to announce hostname ${target}." >&2

        # Step 5: Bump epoch to ensure other nodes honor this master's new slot ownership
        if [ $assigned_count -gt 0 ]; then
            local bump_res
            bump_res=$(valkey-cli -h "$t_host" -p "$t_port" CLUSTER BUMPEPOCH 2>&1)
            echo "BUMPEPOCH on ${target}: ${bump_res}" >&2
        fi

        [ $current_idx -ge $total_missing ] && break
    done

    echo "Finished assigning missing slots and bumping epochs." >&2
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

# --- Configuration & Main Loop ---

CLUSTER_NODES_TO_CHECK=("valkey-server-7011:7011" "valkey-server-7012:7012" "valkey-server-7013:7013" "valkey-server-7014:7014" "valkey-server-7015:7015" "valkey-server-7016:7016" "valkey-server-7021:7021" "valkey-server-7022:7022" "valkey-server-7023:7023" "valkey-server-7024:7024" "valkey-server-7025:7025" "valkey-server-7026:7026")

REPLICAS_TO_PROMOTE=("valkey-server-7014:7014" "valkey-server-7015:7015" "valkey-server-7016:7016" "valkey-server-7021:7021" "valkey-server-7022:7022" "valkey-server-7023:7023" "valkey-server-7024:7024" "valkey-server-7025:7025" "valkey-server-7026:7026")

TAKEOVER_TRIES=0
FAILED_COUNT=0
PARTIAL_AVAILABILITY_APPLIED=false
SLOTS_REASSIGNED=false

while true; do
    if check_valkey_cluster "${CLUSTER_NODES_TO_CHECK[@]}"; then
        echo "Cluster is healthy, proceeding with normal operations..."
        TAKEOVER_TRIES=0
        FAILED_COUNT=0
        PARTIAL_AVAILABILITY_APPLIED=false
        SLOTS_REASSIGNED=false
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

        # After 3 failed attempts:
        # 1. Trigger takeover if masters count is below quorum/expected threshold
        # 2. Add missing slots to active masters so all 16,384 slots are claimed
        if [ "$FAILED_COUNT" -ge 3 ]; then

            if [ "${PRIMARY_COUNT:-1}" -lt 3 ]; then
                ((TAKEOVER_TRIES++))
                echo "Takeover attempt #${TAKEOVER_TRIES}..."
                trigger_failover_takeover_on_replicas "${REPLICAS_TO_PROMOTE[@]}"
            fi

            sleep 2

            if [ "$SLOTS_REASSIGNED" = false ]; then
                echo "Assigning missing slots to online masters via CLUSTER ADDSLOTS..."
                assign_missing_slots_to_surviving_masters "${CLUSTER_NODES_TO_CHECK[@]}"
                SLOTS_REASSIGNED=true
            fi
        fi
    fi

    echo "Sleeping 30 seconds ..."
    sleep 30
done