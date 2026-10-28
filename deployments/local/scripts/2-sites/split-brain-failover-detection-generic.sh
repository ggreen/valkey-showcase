#!/usr/bin/env bash
set -euo pipefail

# Auto-heal and failover controller for Valkey clusters.
# Handles quorum consensus, site-failover takeovers, partial slot coverage,
# and cluster-fix operations while respecting announce-hostnames and TLS/Auth.

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  -c, --cluster-nodes       List of cluster endpoints to check (comma- or space-separated)
                            [Default: env var \$CLUSTER_NODES_TO_CHECK]
  -r, --replicas-to-promote List of replica endpoints to promote (comma- or space-separated)
                            [Default: env var \$REPLICAS_TO_PROMOTE]
  -a, --auth                Password for authentication [Default: env var \$VALKEY_PASSWORD]
  --user                    Valkey ACL username [Default: env var \$VALKEY_USER]
  --tls                     Enable TLS for valkey-cli connections [Default: env var \$VALKEY_TLS=true]
  --cacert                  Path to CA Certificate [Default: env var \$VALKEY_CACERT]
  --cert                    Path to Client Certificate [Default: env var \$VALKEY_CERT]
  --key                     Path to Client Private Key [Default: env var \$VALKEY_KEY]
  -h, --help                Show this help message and exit

Examples:
  $0 -c "node1:7001,node2:7002" -r "node3:7003,node4:7004" --tls
EOF
    exit 1
}

# --- CLI and Environment Parameter Defaults ---

RAW_CLUSTER_NODES="${CLUSTER_NODES_TO_CHECK:-}"
RAW_REPLICAS="${REPLICAS_TO_PROMOTE:-}"
VALKEY_PASSWORD="${VALKEY_PASSWORD:-}"
VALKEY_USER="${VALKEY_USER:-}"
VALKEY_TLS="${VALKEY_TLS:-false}"
VALKEY_CACERT="${VALKEY_CACERT:-}"
VALKEY_CERT="${VALKEY_CERT:-}"
VALKEY_KEY="${VALKEY_KEY:-}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--cluster-nodes)       RAW_CLUSTER_NODES="$2"; shift 2 ;;
        -r|--replicas-to-promote) RAW_REPLICAS="$2"; shift 2 ;;
        -a|--auth)                VALKEY_PASSWORD="$2"; shift 2 ;;
        --user)                   VALKEY_USER="$2"; shift 2 ;;
        --tls)                    VALKEY_TLS=true; shift 1 ;;
        --cacert)                 VALKEY_CACERT="$2"; shift 2 ;;
        --cert)                   VALKEY_CERT="$2"; shift 2 ;;
        --key)                    VALKEY_KEY="$2"; shift 2 ;;
        -h|--help)                usage ;;
        *) echo "ERROR: Unknown parameter '$1'" >&2; usage ;;
    esac
done

if [[ -z "$RAW_CLUSTER_NODES" || -z "$RAW_REPLICAS" ]]; then
    echo "ERROR: Missing required cluster nodes or replica target lists." >&2
    usage
fi

IFS=',' read -r -a CLUSTER_NODES_TO_CHECK <<< "${RAW_CLUSTER_NODES// /,}"
IFS=',' read -r -a REPLICAS_TO_PROMOTE <<< "${RAW_REPLICAS// /,}"

# --- Helper: Unified Valkey CLI Invocation ---

vk_cli() {
    local host="$1"
    local port="$2"
    shift 2

    local cmd=(valkey-cli -h "$host" -p "$port")

    [[ -n "$VALKEY_USER" ]] && cmd+=(--user "$VALKEY_USER")
    [[ -n "$VALKEY_PASSWORD" ]] && cmd+=(-a "$VALKEY_PASSWORD")

    if [[ "$VALKEY_TLS" == "true" ]]; then
        cmd+=(--tls)
        [[ -n "$VALKEY_CACERT" ]] && cmd+=(--cacert "$VALKEY_CACERT")
        [[ -n "$VALKEY_CERT" ]] && cmd+=(--cert "$VALKEY_CERT")
        [[ -n "$VALKEY_KEY" ]] && cmd+=(--key "$VALKEY_KEY")
    fi

    "${cmd[@]}" "$@"
}

# Extracts announce hostname or falls back to IP while supporting IPv4 and IPv6
resolve_endpoint_hostname() {
    local raw_addr="$1"
    local hostname=""
    local port=""

    # Valkey CLUSTER NODES format: <ip>:<port>@<cport>[,<hostname>][,<aux_port>]
    if [[ "$raw_addr" =~ ,([^,@]+) ]]; then
        hostname="${BASH_REMATCH[1]}"
        local base_addr="${raw_addr%%,*}"
        base_addr="${base_addr%%@*}"
        port="${base_addr##*:}"
        echo "${hostname}:${port}"
    else
        local base_addr="${raw_addr%%@*}"
        echo "${base_addr%%,*}"
    fi
}

split_endpoint() {
    local endpoint="$1"
    local host port
    if [[ "$endpoint" =~ ^\[(.*)\]:([0-9]+)$ ]]; then
        host="${BASH_REMATCH[1]}"
        port="${BASH_REMATCH[2]}"
    else
        host="${endpoint%%:*}"
        port="${endpoint##*:}"
        [[ "$host" == "$port" ]] && port="6379"
    fi
    echo "$host" "$port"
}

# --- Health and Topology Inspections ---

# Checks cluster health by gathering consensus across all reachable nodes
check_valkey_cluster_consensus() {
    local endpoints=("$@")
    local reachable=0
    local ok_votes=0
    local fail_votes=0

    for node in "${endpoints[@]}"; do

        [[ -z "$node" ]] && continue
        read -r host port < <(split_endpoint "$node")

        local info_output
        if info_output=$(vk_cli "$host" "$port" CLUSTER INFO 2>/dev/null); then
            ((++reachable))
            local state
            state=$(echo "$info_output" | awk -F: '/cluster_state/ {print $2}' | tr -d '\r')
            if [[ "$state" == "ok" ]]; then
                ((++ok_votes))
            elif [[ "$state" == "fail" ]]; then
                ((++fail_votes))
            fi
        fi
    done

  echo "ok_votes $ok_votes, reachable nodes $reachable"

    if [[ "$reachable" -eq 0 ]]; then
        echo "CRITICAL: Unable to reach any nodes in the check list." >&2
        return 2
    fi

    # Require strict majority of reachable nodes reporting 'ok'
    if [[ $ok_votes -gt $((reachable / 2)) ]]; then
        return 0
    fi

    return 1
}

count_valkey_running_primaries() {
    local endpoints=("$@")

    for node in "${endpoints[@]}"; do
        [[ -z "$node" ]] && continue
        read -r host port < <(split_endpoint "$node")

        local nodes_output
        if nodes_output=$(vk_cli "$host" "$port" CLUSTER NODES 2>/dev/null); then
            local count
            count=$(echo "$nodes_output" | awk '$3 ~ /master/ && $3 !~ /fail/ && $8 == "connected"' | wc -l | tr -d ' ')
            echo "$count"
            return 0
        fi
    done

    echo "0"
    return 1
}

# --- Recovery Operations ---

enable_partial_slot_availability() {
    local endpoints=("$@")
    local applied_count=0

    echo "NOTICE: Enabling partial slot availability (cluster-require-full-coverage no)..." >&2

    for node in "${endpoints[@]}"; do
        [[ -z "$node" ]] && continue
        read -r host port < <(split_endpoint "$node")

        local res
        if res=$(vk_cli "$host" "$port" CONFIG SET cluster-require-full-coverage no 2>&1); then
            if [[ "$res" =~ OK ]]; then
                applied_count=$((applied_count + 1))
            fi
        fi
    done

    echo "Applied full-coverage override to ${applied_count} node(s)." >&2
}

trigger_failover_takeover_on_replicas() {
    local target_replicas=("$@")
    local success_count=0
    local fail_count=0

    echo "Starting takeover execution on target replicas..." >&2

    for node in "${target_replicas[@]}"; do
        [[ -z "$node" ]] && continue
        read -r host port < <(split_endpoint "$node")

        local role
        role=$(vk_cli "$host" "$port" INFO replication 2>/dev/null | awk -F: '/role:/ {print $2}' | tr -d '\r')

        if [[ "$role" == "master" ]]; then
            echo "SKIP: Node ${host}:${port} is already primary." >&2
            ((++success_count))

            continue
        elif [[ -z "$role" ]]; then
            echo "WARNING: Could not connect to ${host}:${port}." >&2
            ((++fail_count))
            continue
        fi

        echo "Issuing 'CLUSTER FAILOVER TAKEOVER' on ${host}:${port}..." >&2
        local failover_res
        if failover_res=$(vk_cli "$host" "$port" CLUSTER FAILOVER TAKEOVER 2>&1) && [[ "$failover_res" =~ OK ]]; then
            echo "SUCCESS: Takeover initiated on ${host}:${port}." >&2
            ((++success_count))
        else
            echo "ERROR: Failed takeover on ${host}:${port}: ${failover_res}" >&2
            ((++fail_count))
        fi
    done

    [[ $fail_count -gt 0 ]] && return 1
    return 0
}

assign_missing_slots_to_surviving_masters() {
    local endpoints=("$@")
    local target_fix_endpoint=""

    for node in "${endpoints[@]}"; do
        [[ -z "$node" ]] && continue
        read -r host port < <(split_endpoint "$node")

        if vk_cli "$host" "$port" PING 2>/dev/null | grep -q PONG; then
            target_fix_endpoint="${host}:${port}"
            break
        fi
    done

    if [[ -z "$target_fix_endpoint" ]]; then
        echo "CRITICAL: No reachable endpoint available for cluster fix." >&2
        return 1
    fi

    echo "Running 'valkey-cli --cluster fix' via ${target_fix_endpoint}..." >&2

    local cli_cmd=(valkey-cli)
    [[ -n "$VALKEY_USER" ]] && cli_cmd+=(--user "$VALKEY_USER")
    [[ -n "$VALKEY_PASSWORD" ]] && cli_cmd+=(-a "$VALKEY_PASSWORD")

    if [[ "$VALKEY_TLS" == "true" ]]; then
        cli_cmd+=(--tls)
        [[ -n "$VALKEY_CACERT" ]] && cli_cmd+=(--cacert "$VALKEY_CACERT")
        [[ -n "$VALKEY_CERT" ]] && cli_cmd+=(--cert "$VALKEY_CERT")
        [[ -n "$VALKEY_KEY" ]] && cli_cmd+=(--key "$VALKEY_KEY")
    fi

    cli_cmd+=(--cluster fix "$target_fix_endpoint" --cluster-fix-with-unreachable-primaries --cluster-yes)

    if echo "yes" | "${cli_cmd[@]}"; then
        echo "SUCCESS: Cluster fix executed." >&2
        return 0
    else
        local status=$?
        echo "ERROR: Cluster fix failed with code ${status}." >&2
        return $status
    fi
}

# --- Main Watchdog Loop ---

FAILED_CONSECUTIVE_COUNT=0
HEALTHY_CONSECUTIVE_COUNT=0
RECOVERY_STAGE=0 # 0: Normal, 1: Takeover triggered, 2: Partial availability enabled, 3: Cluster fixed

echo "Valkey Cluster Watchdog started."
echo "Monitored endpoints: ${CLUSTER_NODES_TO_CHECK[*]}"
echo "Promotion targets: ${REPLICAS_TO_PROMOTE[*]}"

while true; do
    if check_valkey_cluster_consensus "${CLUSTER_NODES_TO_CHECK[@]}"; then


        HEALTHY_CONSECUTIVE_COUNT=$((HEALTHY_CONSECUTIVE_COUNT + 1))
        FAILED_CONSECUTIVE_COUNT=0

        # Require 3 consecutive healthy cycles before resetting recovery state to prevent flapping
        if [[ $HEALTHY_CONSECUTIVE_COUNT -ge 3 ]]; then
            if [[ $RECOVERY_STAGE -ne 0 ]]; then
                echo "Cluster confirmed stable and healthy. Resetting recovery stage."
            fi
            RECOVERY_STAGE=0
        fi
    else
        HEALTHY_CONSECUTIVE_COUNT=0
        FAILED_CONSECUTIVE_COUNT=$((FAILED_CONSECUTIVE_COUNT + 1))
        echo "Cluster check failed (Consecutive failure count: ${FAILED_CONSECUTIVE_COUNT})" >&2

        PRIMARY_COUNT=$(count_valkey_running_primaries "${CLUSTER_NODES_TO_CHECK[@]}")
        echo "Active connected primaries detected: ${PRIMARY_COUNT}" >&2

        # Stage 1: Initial takeover attempt when primaries are lost
        if [[ "$PRIMARY_COUNT" -eq 0 && $RECOVERY_STAGE -lt 1 ]]; then
            echo "Stage 1: No active primaries found. Initiating site failover takeover..." >&2
            trigger_failover_takeover_on_replicas "${REPLICAS_TO_PROMOTE[@]}" || true
            RECOVERY_STAGE=1
        fi

        # Stage 2: Persistent failure after 3 failed intervals -> enable partial coverage
        if [[ $FAILED_CONSECUTIVE_COUNT -ge 3 && $RECOVERY_STAGE -lt 2 ]]; then
            echo "Stage 2: Cluster failed for 3+ cycles. Enabling partial slot availability..." >&2
            enable_partial_slot_availability "${CLUSTER_NODES_TO_CHECK[@]}"
            RECOVERY_STAGE=2
        fi

        # Stage 3: Severe failure (<3 primaries, 4+ intervals) -> reclaim and repair slots
        if [[ $FAILED_CONSECUTIVE_COUNT -gt 3 && "$PRIMARY_COUNT" -lt 3 && $RECOVERY_STAGE -lt 3 ]]; then
            echo "Stage 3: Cluster has insufficient primaries. Running automated cluster slot fix..." >&2
            assign_missing_slots_to_surviving_masters "${CLUSTER_NODES_TO_CHECK[@]}" || true
            RECOVERY_STAGE=3
        fi

    fi

    echo "sleeping 15 seconds"
    sleep 15
done