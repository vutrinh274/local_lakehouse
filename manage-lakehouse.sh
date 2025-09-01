#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

start_services() {
    echo "Starting all services..."
    
    cd "$SCRIPT_DIR"
    docker compose -f docker-compose-lake.yaml up -d
    sleep 5
    
    docker compose -f docker-compose-trino.yaml up -d
    sleep 30
    
    docker compose -f docker-compose-airflow.yaml up -d
    sleep 5
    
    echo "All services started"

    init_trino
    # load_dbt_seed_data
}

init_trino() {

    docker exec -it trino-coordinator trino --catalog iceberg --file /etc/trino/init.sql
    
    echo "Schema Landing, Staging, Curated are created in Trino Iceberg Catalog"

}

load_dbt_seed_data() {
    dbt seed --project-dir ./dags/dbt_trino --profiles-dir ./dags/dbt_trino
    echo "CSV files are load to dbt at the landing project"
}



stop_services() {
    echo "Stopping all services..."
    
    cd "$SCRIPT_DIR"
    docker compose -f docker-compose-airflow.yaml down -v
    docker compose -f docker-compose-trino.yaml down -v
    docker compose -f docker-compose-lake.yaml down -v
    
    echo "All services stopped"
}

case "${1:-help}" in
    "start")
        start_services
        ;;
    "stop")
        stop_services
        ;;
    *)
        echo "Usage: $0 [start|stop]"
        echo "Examples:"
        echo "  $0 start    # Start all services"
        echo "  $0 stop     # Stop all services"
        ;;
esac
