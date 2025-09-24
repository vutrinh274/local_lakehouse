#!/bin/bash
# Local Lakehouse Management Script
# 
# This script orchestrates the startup and shutdown of a complete data lakehouse stack:
# - MinIO (S3-compatible object storage)
# - Nessie (Git-like data catalog for Iceberg)
# - Trino (Distributed SQL query engine)
# - Airflow (Workflow orchestration)
#
# Usage: ./manage-lakehouse.sh [start|stop]

set -e  # Exit immediately if any command fails

# Get the absolute path of the script directory to ensure relative paths work correctly
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to start all lakehouse services in the correct order
start_services() {
    echo "Starting Local Lakehouse services..."
    
    # Change to script directory to ensure docker-compose files are found
    cd "$SCRIPT_DIR"
    
    # Step 1: Start the data lake infrastructure (MinIO + Nessie)
    echo "Starting data lake services (MinIO + Nessie)..."
    docker compose -f docker-compose-lake.yaml up -d
    sleep 5  # Allow services to initialize
    
    # Step 2: Start Trino query engine (coordinator + workers)
    echo "Starting Trino query engine..."
    docker compose -f docker-compose-trino.yaml up -d
    sleep 30  # Trino needs more time to fully initialize and connect to catalog
    
    # Step 3: Start Airflow orchestration services
    echo "Starting Airflow orchestration services..."
    docker compose -f docker-compose-airflow.yaml up -d
    sleep 5
    
    echo "All services started successfully."
    echo ""
    echo "Service Access Information:"
    echo "  - MinIO Console: http://localhost:9001 (admin/password)"
    echo "  - Trino Web UI: http://localhost:8080"
    echo "  - Airflow Web UI: http://localhost:8081 (airflow/airflow)"
    echo "  - Nessie API: http://localhost:19120"
    echo ""

    # Initialize Trino with required schemas
    init_trino
    
    # Uncomment the line below if you want to automatically load seed data on startup
    # load_dbt_seed_data
}

# Function to initialize Trino with the required database schemas
init_trino() {
    echo "Initializing Trino schemas..."
    
    # Execute the init.sql file inside the Trino coordinator container
    # This creates the landing, staging, and curated schemas in the Iceberg catalog
    docker exec -it trino-coordinator trino --catalog iceberg --file /etc/trino/init.sql
    
    echo "Schemas (landing, staging, curated) created in Trino Iceberg Catalog."
    echo ""
}

# Function to load CSV seed data into the lakehouse using dbt
# This is optional and can be run manually or via Airflow DAGs
load_dbt_seed_data() {
    echo "Loading CSV seed data via dbt..."
    
    # Run dbt seed command to load CSV files from seeds/ directory into Iceberg tables
    dbt seed --project-dir ./dags/dbt_trino --profiles-dir ./dags/dbt_trino
    
    echo "CSV files loaded to landing schema via dbt."
    echo ""
}

# Function to stop all lakehouse services and clean up resources
stop_services() {
    echo "Stopping Local Lakehouse services..."
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Stop services in reverse order (Airflow -> Trino -> Lake)
    # The -v flag removes associated volumes to ensure clean shutdown
    echo "Stopping Airflow services..."
    docker compose -f docker-compose-airflow.yaml down -v
    
    echo "Stopping Trino services..."
    docker compose -f docker-compose-trino.yaml down -v
    
    echo "Stopping data lake services..."
    docker compose -f docker-compose-lake.yaml down -v
    
    echo "All services stopped and volumes cleaned up."
    echo ""
}

# Main script logic - handle command line arguments
case "${1:-help}" in
    "start")
        start_services
        ;;
    "stop")
        stop_services
        ;;
    *)
        echo "Local Lakehouse Management Script"
        echo ""
        echo "Usage: $0 [start|stop]"
        echo ""
        echo "Commands:"
        echo "  start    Start all lakehouse services (MinIO, Nessie, Trino, Airflow)"
        echo "  stop     Stop all services and clean up volumes"
        echo ""
        echo "Examples:"
        echo "  $0 start    # Start the complete lakehouse stack"
        echo "  $0 stop     # Stop all services and clean up"
        echo ""
        echo "After starting, you can access:"
        echo "  - MinIO Console: http://localhost:9001"
        echo "  - Trino Web UI: http://localhost:8080" 
        echo "  - Airflow Web UI: http://localhost:8081"
        ;;
esac
