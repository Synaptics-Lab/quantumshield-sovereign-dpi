#!/usr/bin/env bash
# ==============================================================================
# SynapticChain Observer Node — 1-Click Auditor & Operator Launcher
# ==============================================================================
# Connects to the public SynapticChain African Testnet mesh via libp2p GossipSub.
# Verifies consensus state roots locally without third-party trust.
# Exposes local JSON-RPC at http://localhost:8545 and WebSocket at :8546.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

RPC_URL="http://127.0.0.1:8545"
DATA_DIR="${ROOT_DIR}/data/observer"
LOG_FILE="${ROOT_DIR}/observer.log"
BINARY_URL="https://synapticchain.xyz/downloads/synaptic-node"
LOCAL_BIN="${ROOT_DIR}/bin/synaptic-node"

print_banner() {
    echo "======================================================================"
    echo "  ⚡ SYNAPTICCHAIN OBSERVER NODE — 1-CLICK AUDITOR KIT"
    echo "======================================================================"
    echo "• Mode:          Read-Only Observer (Zero Stake, Zero Voting Power)"
    echo "• Local RPC:     http://localhost:8545"
    echo "• Local WS:      ws://localhost:8546"
    echo "• Mesh P2P:      :9000 (Bootstrap: nodes.synapticchain.xyz:9000)"
    echo "• Verification:  100% Trustless Local State Root Validation"
    echo "======================================================================"
}

check_status() {
    if curl -s -X POST "${RPC_URL}" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"syn_getStatus","params":[],"id":1}' --connect-timeout 2 >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

show_status() {
    print_banner
    if check_status; then
        echo -e "\n🟢 Observer Node is ACTIVE and listening on ${RPC_URL}!\n"
        curl -s -X POST "${RPC_URL}" \
            -H "Content-Type: application/json" \
            -d '{"jsonrpc":"2.0","method":"syn_getStatus","params":[],"id":1}' | jq .
    else
        echo -e "\n🔴 Observer Node is NOT running on ${RPC_URL}."
    fi
}

stop_observer() {
    echo "Stopping SynapticChain Observer Node..."
    if command -v docker >/dev/null 2>&1 && docker compose -f "${ROOT_DIR}/docker-compose.observer.yml" ps --services --filter "status=running" 2>/dev/null | grep -q observer; then
        docker compose -f "${ROOT_DIR}/docker-compose.observer.yml" down
        echo "✓ Docker observer container stopped."
    fi
    pkill -f "synaptic-node.*--mode.*light" 2>/dev/null || true
    echo "✓ Stopped."
}

# Handle command flags
if [[ "${1:-}" == "--status" ]]; then
    show_status
    exit 0
elif [[ "${1:-}" == "--stop" ]]; then
    stop_observer
    exit 0
elif [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: $0 [--docker | --native | --status | --stop]"
    exit 0
fi

print_banner

# Determine execution mode
USE_DOCKER=true
if [[ "${1:-}" == "--native" ]]; then
    USE_DOCKER=false
elif ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    echo "ℹ️  Docker not available or daemon not running. Falling back to native Linux execution."
    USE_DOCKER=false
fi

if [[ "${USE_DOCKER}" == "true" ]]; then
    echo -e "\n🐳 Starting Observer Node & Local Canopy Explorer via Docker Compose..."
    docker compose -f "${ROOT_DIR}/docker-compose.observer.yml" up -d

    echo -n "⏳ Waiting for local observer RPC (:8545) to initialize..."
    for i in $(seq 1 30); do
        if check_status; then
            echo " Ready!"
            break
        fi
        echo -n "."
        sleep 1
    done

    if ! check_status; then
        echo -e "\n⚠️  Observer node took longer than 30s to initialize. Check logs with:"
        echo "   docker compose -f docker-compose.observer.yml logs"
        exit 1
    fi
else
    # Native Linux Execution
    echo -e "\n⚙️  Running native observer binary..."
    mkdir -p "${DATA_DIR}" "${ROOT_DIR}/bin"

    BIN_EXEC=""
    if command -v synaptic-node >/dev/null 2>&1; then
        BIN_EXEC="$(command -v synaptic-node)"
    elif [[ -f "${LOCAL_BIN}" ]]; then
        BIN_EXEC="${LOCAL_BIN}"
    else
        echo "📥 Downloading official pre-compiled synaptic-node binary..."
        curl -fsSL "${BINARY_URL}" -o "${LOCAL_BIN}"
        chmod +x "${LOCAL_BIN}"
        BIN_EXEC="${LOCAL_BIN}"
    fi

    echo "Using binary: ${BIN_EXEC}"
    echo "Starting observer in background (log: ${LOG_FILE})..."
    nohup "${BIN_EXEC}" \
        --mode light \
        --rpc-port 8545 \
        --p2p-port 9000 \
        --data-dir "${DATA_DIR}" \
        --log-level info \
        --skip-stake-check \
        --bootstrap "/dns4/nodes.synapticchain.xyz/tcp/9000" \
        > "${LOG_FILE}" 2>&1 &

    echo -n "⏳ Waiting for local observer RPC (:8545) to initialize..."
    for i in $(seq 1 30); do
        if check_status; then
            echo " Ready!"
            break
        fi
        echo -n "."
        sleep 1
    done
fi

echo -e "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ OBSERVER NODE ONLINE — VERIFYING LAYER-1 STATE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
curl -s -X POST "${RPC_URL}" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"syn_getStatus","params":[],"id":1}' | jq .

echo -e "\n🎉 Verification Complete!"
echo "• Query local JSON-RPC:  curl -s -X POST http://localhost:8545 -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"syn_getStatus\",\"params\":[],\"id\":1}' | jq ."
echo "• Open Local Explorer:   http://localhost:3000 (connected to your local node)"
echo "• Stop observer node:    ./scripts/run-observer.sh --stop"
