
# Local Lakehouse

We will set up a lake house with MinIO as the backend storage, Iceberg as the table format, Project Nessie as the catalog for Iceberg, Trino as the query engine, dbt as the abstraction for SQL transformation, and finally, Airflow to glue everything together. For the sample data, we will use five input tables from the AdventureWorks sample dataset: product, product_category, product_subcategory, sale, and territories.
<img width="986" height="624" alt="image" src="https://github.com/user-attachments/assets/802f9857-0112-4296-a13a-d2e2c5fdb697" />

# Tech Stacks

## **1. MinIO (Object Storage Layer)**

* **What it is:** MinIO is an open-source, high-performance, S3-compatible object storage system.
* **What it does**

  * Serves as the **storage backend**.
  * Stores raw and transformed data files (Parquet, ORC, Avro, JSON, etc.).
  * Provides S3 APIs for Iceberg, Nessie, Trino, and other tools to interact seamlessly.
* **Think of it as:** the **data lake foundation**, where all your raw and curated datasets live.

---

## **2. Apache Iceberg (Table Format)**

* **What it is:** Iceberg is an **open table format** that adds structure and transactional guarantees on top of object storage.
* **What it does**

  * Defines tables on MinIO files.
  * Manages schemas, partitions, and snapshots.
  * Supports **ACID transactions** and **time travel**.
  * Handles **schema evolution** without breaking queries.
* **Think of it as:** the **table layer** that makes your lake behave like a database.

---

## **3. Project Nessie (Catalog / Git-like Control for Iceberg)**

* **What it is:** Nessie is a **versioned catalog for Iceberg tables**, similar to Git but for data.
* **What it does**

  * Tracks metadata pointers for Iceberg tables.
  * Enables **branching, tagging, commits** for your data lake.
  * Allows experimentation (branches) and reproducibility (pinning to commits).
* **Think of it as:** the **metadata brain** for your Iceberg tables in MinIO.

---

## **4. Trino (Query Engine)**

* **What it is:** Trino is a **distributed SQL query engine** for fast, interactive analytics.
* **What it does**

  * Connects to Nessie/Iceberg to discover tables.
  * Executes SQL directly on MinIO data.
  * Joins Iceberg tables with external sources (Postgres, Kafka, Elastic, etc.).
  * Scales out with workers for parallel processing.
* **Think of it as:** the **query engine** that powers analytics over your lakehouse.

---

## **5. dbt (SQL Transformation Layer)**

* **What it is:** dbt (data build tool) is a **SQL-based transformation framework**.
* **What it does**

  * Lets you write **modular SQL models** that are version-controlled.
  * Compiles SQL transformations and executes them in Trino.
  * Supports testing, documentation, and lineage tracking.
  * Turns raw Iceberg tables into **curated, analytics-ready models**.
* **Think of it as:** the **analytics engineering layer** where transformations and business logic live.

---

## **6. Apache Airflow (Orchestration Layer)**

* **What it is:** Airflow is a **workflow orchestrator** for managing data pipelines.
* **What it does**

  * Schedules and runs workflows (DAGs).
  * Automates the flow: ingestion → transformation → analytics.
  * Orchestrates MinIO (ingestion), Iceberg (tables), dbt (transformations), and Trino (queries).
  * Provides monitoring, retries, and alerting.
* **Think of it as:** the **glue** that coordinates all components into repeatable pipelines.

---

## **How They Work Together (Big Picture)**

1. **MinIO** → stores raw data files.
2. **Iceberg** → defines tables over those files.
3. **Nessie** → manages table metadata and versioning.
4. **Trino** → queries Iceberg tables in MinIO.
5. **dbt** → defines and runs SQL transformations inside Trino.
6. **Airflow** → orchestrates ingestion, transformations, and queries into reliable workflows.

### **Flow:**

User / Pipeline → **Airflow** (DAGs) → **dbt** (SQL transformations) → **Trino** (query execution) → **Nessie** (catalog) → **Iceberg** (table format) → **MinIO** (storage).
Would you like me to also **sketch an architecture diagram** of this full stack (with arrows showing the flow) so you can visualize how dbt and Airflow fit into the lakehouse?

I'll analyze the project structure and provide a comprehensive tree with explanations for each component.

[9 tools called]

Now let me read a few more key files to complete the picture:

[4 tools called]

Perfect! Now I have a comprehensive understanding of the project structure. Let me create a detailed project structure tree with explanations.

# Project Structure Tree

```
local_lakehouse/
├── 📋 manage-lakehouse.sh                 # Main orchestration script to start/stop all services
├── 🐳 docker-compose-airflow.yaml         # Airflow orchestration services (scheduler, worker, webserver, etc.)
├── 🐳 docker-compose-lake.yaml            # Data lake infrastructure (MinIO + Nessie)
├── 🐳 docker-compose-trino.yaml           # Trino query engine (coordinator + workers)
├── 🐳 Dockerfile                          # Custom Airflow image with dbt dependencies
├── 📄 requirements-airflow.txt            # Airflow dependencies
├── 📄 requirements-dbt.txt                # dbt dependencies (dbt-trino, dbt-core)
├── 📖 README.md                           # Project documentation and architecture overview
│
├── 🎯 dags/                               # Airflow DAGs and workflows
│   ├── 🔧 custom_operator/
│   │   ├── __pycache__/                   # Python bytecode cache
│   │   └── dbt_operator.py                # Custom Airflow operator for dbt Core execution
│   ├── dbt_dag.py                         # Main Airflow DAG orchestrating dbt pipeline
│   │
│   └── 🏗️ dbt_trino/                      # dbt project for data transformations
│       ├── dbt_project.yml                # dbt project configuration
│       ├── profiles.yml                   # dbt connection profiles (Trino connection)
│       ├── README.md                      # dbt project documentation
│       │
│       ├── 📊 seeds/                      # Raw CSV data files (source data)
│       │   ├── product_categories.csv     # Product category reference data
│       │   ├── product_subcategories.csv  # Product subcategory reference data
│       │   ├── products.csv               # Product master data
│       │   ├── sales.csv                  # Sales transaction data
│       │   └── territories.csv            # Territory reference data
│       │
│       ├── 🔄 models/                     # dbt transformation models
│       │   ├── staging/                   # Staging layer (cleaned, standardized data)
│       │   │   ├── stg_product_categories.sql
│       │   │   ├── stg_product_subcategories.sql
│       │   │   ├── stg_products.sql
│       │   │   ├── stg_sales.sql
│       │   │   └── stg_territories.sql
│       │   │
│       │   └── curated/                   # Curated layer (business logic, analytics-ready)
│       │       ├── dim_country.sql        # Country dimension table
│       │       ├── dim_product.sql        # Product dimension table
│       │       ├── fact_sale.sql          # Sales fact table
│       │       └── schema.yml             # dbt model documentation and tests
│       │
│       ├── 🔍 analyses/                   # Ad-hoc SQL analysis files
│       ├── 🧪 tests/                      # Custom dbt tests
│       ├── 📸 snapshots/                  # dbt snapshots for slowly changing dimensions
│       └── 🔧 macros/                     # dbt macros and reusable SQL functions
│           └── adjust_schema_name.sql     # Custom macro for schema naming
│
└── ⚙️ trino_config/                       # Trino query engine configuration
    ├── coordinator/                       # Trino coordinator configuration
    │   ├── config.properties              # Coordinator settings
    │   └── init.sql                       # Initial schema creation (landing, staging, curated)
    ├── worker/                            # Trino worker configuration
    │   └── config.properties              # Worker settings
    └── catalog/                           # Data catalog configuration
        └── iceberg.properties             # Iceberg catalog config (connects to Nessie + MinIO)
```

## Component Explanations

### **Infrastructure & Orchestration**

* **`manage-lakehouse.sh`**: Master control script that starts services in proper order (lake → trino → airflow) and initializes Trino schemas

* **Docker Compose Files**: Separate service definitions for clean separation of concerns
  * `docker-compose-lake.yaml`: MinIO (S3-compatible storage) + Nessie (Git-like data catalog)
  * `docker-compose-trino.yaml`: Distributed query engine (1 coordinator + 2 workers)
  * `docker-compose-airflow.yaml`: Full Airflow setup with Celery executor, Redis, PostgreSQL

### **Data Pipeline (dbt)**

* **`dbt_trino/`**: Complete dbt project implementing medallion architecture
  * **Seeds**: Raw CSV files loaded as Iceberg tables in `landing` schema
  * **Staging Models**: Data cleaning and standardization in `staging` schema
  * **Curated Models**: Business logic and dimensional modeling in `curated` schema
  * **Configuration**: Connects to Trino using `profiles.yml`, schema routing via `dbt_project.yml`

### **Workflow Orchestration (Airflow)**

* **`dags/dbt_dag.py`**: Main pipeline DAG that runs `dbt seed` → `dbt run` daily

* **`custom_operator/dbt_operator.py`**: Custom Airflow operator wrapping dbt Core CLI for native execution
* **Custom Dockerfile**: Extends official Airflow image with dbt dependencies

### **Query Engine Configuration (Trino)**

* **`trino_config/`**: Complete Trino cluster configuration
  * **Iceberg Catalog**: Connects to Nessie catalog with MinIO as storage backend
  * **Coordinator**: Query planning and coordination
  * **Workers**: Distributed query execution
  * **Init SQL**: Creates the three-layer schema structure (landing/staging/curated)

### **Data Architecture Pattern**

This implements a **Medallion Architecture**:

1. **Bronze/Landing**: Raw CSV data loaded via dbt seeds into Iceberg tables
2. **Silver/Staging**: Cleaned, standardized data with consistent naming and types  
3. **Gold/Curated**: Business-ready dimensional model (facts + dimensions) for analytics

The entire stack provides a production-like lakehouse with:

* **ACID transactions** (Iceberg)
* **Schema evolution** (Iceberg + Nessie)
* **Version control for data** (Nessie branching)
* **Distributed SQL processing** (Trino)
* **Workflow orchestration** (Airflow)
* **SQL-based transformations** (dbt)

Run

```
./manage-lakehouse.sh start
```
