#!/bin/bash

# ElectrumSV Runner for Tails OS - Consolidated Script
# This script handles both GUI and daemon modes with all compatibility fixes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  ElectrumSV Runner for Tails OS${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to show help
show_help() {
    print_header
    echo ""
    echo "Usage: $0 [MODE] [OPTIONS]"
    echo ""
    echo "MODES:"
    echo "  gui                 Run GUI mode (default)"
    echo "  daemon              Run daemon mode"
    echo "  help                Show this help message"
    echo "  test                Run test to verify setup"
    echo ""
    echo "DAEMON COMMANDS (when in daemon mode):"
    echo "  start               Start the daemon"
    echo "  stop                Stop the daemon"
    echo "  status              Show daemon status"
    echo "  load_wallet         Load a wallet"
    echo "  close_wallet        Close current wallet"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 gui              # Run GUI mode"
    echo "  $0 daemon start     # Start daemon"
    echo "  $0 daemon status    # Check daemon status"
    echo "  $0 daemon stop      # Stop daemon"
    echo "  $0 test             # Test the setup"
    echo ""
    echo "OPTIONS:"
    echo "  --testnet           Use testnet"
    echo "  --regtest           Use regtest"
    echo "  --scaling-testnet   Use scaling testnet"
    echo "  --portable          Use portable mode"
    echo "  --help              Show this help"
    echo ""
}

# Function to check if daemon is running
check_daemon_running() {
    if [ -f "/tmp/electrum-sv-daemon" ]; then
        return 0
    else
        return 1
    fi
}

# Function to stop daemon
stop_daemon() {
    print_status "Stopping ElectrumSV daemon..."
    ./python-headless-3.10.18-linux-x86_64/bin/python3.10 run_electrumsv_final.py daemon stop
    sleep 2
    if check_daemon_running; then
        print_warning "Daemon may still be running. You can try: $0 daemon stop"
    else
        print_status "Daemon stopped successfully."
    fi
}

# Function to run test
run_test() {
    print_header
    print_status "Running ElectrumSV setup test..."
    echo ""
    
    # Test 1: Check Python
    print_status "1. Testing portable Python..."
    if ./python-headless-3.10.18-linux-x86_64/bin/python3.10 --version > /dev/null 2>&1; then
        print_status "   ✓ Portable Python working"
    else
        print_error "   ✗ Portable Python not working"
        return 1
    fi
    
    # Test 2: Check ElectrumSV help
    print_status "2. Testing ElectrumSV help..."
    if ./python-headless-3.10.18-linux-x86_64/bin/python3.10 run_electrumsv_final.py --help > /dev/null 2>&1; then
        print_status "   ✓ ElectrumSV help working"
    else
        print_error "   ✗ ElectrumSV help not working"
        return 1
    fi
    
    # Test 3: Check daemon status
    print_status "3. Testing daemon status..."
    if ./python-headless-3.10.18-linux-x86_64/bin/python3.10 run_electrumsv_final.py daemon status > /dev/null 2>&1; then
        print_status "   ✓ Daemon status working"
    else
        print_warning "   ⚠ Daemon not running (this is normal if not started)"
    fi
    
    # Test 4: Check available commands
    print_status "4. Testing available commands..."
    if ./python-headless-3.10.18-linux-x86_64/bin/python3.10 run_electrumsv_final.py commands > /dev/null 2>&1; then
        print_status "   ✓ Commands available"
    else
        print_error "   ✗ Commands not available"
        return 1
    fi
    
    echo ""
    print_status "All tests completed successfully! ElectrumSV is ready to use."
    echo ""
    print_status "Next steps:"
    echo "  • Run GUI: $0 gui"
    echo "  • Start daemon: $0 daemon start"
    echo "  • Check status: $0 daemon status"
}

# Main script logic
main() {
    # Set the working directory to the script's location
    cd "$(dirname "$0")" || exit 1
    
    # Check if Python wrapper exists
    if [ ! -f "run_electrumsv_final.py" ]; then
        print_error "Python wrapper not found. Please ensure you're in the correct directory."
        exit 1
    fi
    
    # Check if portable Python exists
    if [ ! -f "python-headless-3.10.18-linux-x86_64/bin/python3.10" ]; then
        print_error "Portable Python not found. Please ensure the setup is complete."
        exit 1
    fi
    
    # Parse arguments
    MODE="gui"
    DAEMON_CMD=""
    EXTRA_ARGS=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            gui)
                MODE="gui"
                shift
                ;;
            daemon)
                MODE="daemon"
                if [[ $# -gt 1 ]]; then
                    DAEMON_CMD="$2"
                    shift 2
                else
                    print_error "Daemon mode requires a command (start, stop, status, etc.)"
                    exit 1
                fi
                ;;
            help|--help|-h)
                show_help
                exit 0
                ;;
            test)
                run_test
                exit 0
                ;;
            --testnet|--regtest|--scaling-testnet|--portable)
                EXTRA_ARGS="$EXTRA_ARGS $1"
                shift
                ;;
            *)
                EXTRA_ARGS="$EXTRA_ARGS $1"
                shift
                ;;
        esac
    done
    
    # Handle GUI mode
    if [ "$MODE" = "gui" ]; then
        # Check if daemon is running and stop it
        if check_daemon_running; then
            print_warning "Daemon is running. Stopping it first..."
            stop_daemon
        fi
        
        print_status "Starting ElectrumSV GUI..."
        ./python-headless-3.10.18-linux-x86_64/bin/python3.10 run_electrumsv_final.py gui $EXTRA_ARGS
    fi
    
    # Handle daemon mode
    if [ "$MODE" = "daemon" ]; then
        case "$DAEMON_CMD" in
            start)
                print_status "Starting ElectrumSV daemon..."
                ./python-headless-3.10.18-linux-x86_64/bin/python3.10 run_electrumsv_final.py daemon start $EXTRA_ARGS
                ;;
            stop)
                print_status "Stopping ElectrumSV daemon..."
                ./python-headless-3.10.18-linux-x86_64/bin/python3.10 run_electrumsv_final.py daemon stop
                ;;
            status)
                print_status "Checking ElectrumSV daemon status..."
                ./python-headless-3.10.18-linux-x86_64/bin/python3.10 run_electrumsv_final.py daemon status
                ;;
            load_wallet|close_wallet)
                print_status "Running daemon command: $DAEMON_CMD"
                ./python-headless-3.10.18-linux-x86_64/bin/python3.10 run_electrumsv_final.py daemon $DAEMON_CMD $EXTRA_ARGS
                ;;
            *)
                print_error "Unknown daemon command: $DAEMON_CMD"
                print_status "Available daemon commands: start, stop, status, load_wallet, close_wallet"
                exit 1
                ;;
        esac
    fi
}

# Run main function with all arguments
main "$@" 