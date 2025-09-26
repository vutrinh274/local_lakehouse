from datetime import datetime, timedelta
from airflow import DAG
from custom_operator.dbt_operator import DbtCoreOperator
from airflow import settings


DBT_PROJECT_PATH = f"{settings.DAGS_FOLDER}/dbt_trino"


default_args = {
    'owner': 'batman',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=2),
}

with DAG(
    dag_id='dbt_pipeline',
    default_args=default_args,
    description='A DAG to run dbt Core transformations.',
    schedule=timedelta(days=1),
    start_date=datetime(2025, 8, 8),
    catchup=False,
    tags=['dbt', 'data_transformation'],
) as dag:
    dbt_seed_task = DbtCoreOperator(
        task_id='dbt_seed',
        dbt_project_dir=DBT_PROJECT_PATH,
        dbt_profiles_dir=DBT_PROJECT_PATH,
        dbt_command='seed',
        full_refresh=True
    )

    # Run staging models one by one to avoid Iceberg concurrency issues
    dbt_run_stg_categories = DbtCoreOperator(
        task_id='dbt_run_stg_categories',
        dbt_project_dir=DBT_PROJECT_PATH,
        dbt_profiles_dir=DBT_PROJECT_PATH,
        dbt_command='run',
        select='stg_product_categories',
        full_refresh=True
    )

    dbt_run_stg_subcategories = DbtCoreOperator(
        task_id='dbt_run_stg_subcategories',
        dbt_project_dir=DBT_PROJECT_PATH,
        dbt_profiles_dir=DBT_PROJECT_PATH,
        dbt_command='run',
        select='stg_product_subcategories',
        full_refresh=True
    )

    dbt_run_stg_products = DbtCoreOperator(
        task_id='dbt_run_stg_products',
        dbt_project_dir=DBT_PROJECT_PATH,
        dbt_profiles_dir=DBT_PROJECT_PATH,
        dbt_command='run',
        select='stg_products',
        full_refresh=True
    )

    dbt_run_stg_sales = DbtCoreOperator(
        task_id='dbt_run_stg_sales',
        dbt_project_dir=DBT_PROJECT_PATH,
        dbt_profiles_dir=DBT_PROJECT_PATH,
        dbt_command='run',
        select='stg_sales',
        full_refresh=True
    )

    dbt_run_stg_territories = DbtCoreOperator(
        task_id='dbt_run_stg_territories',
        dbt_project_dir=DBT_PROJECT_PATH,
        dbt_profiles_dir=DBT_PROJECT_PATH,
        dbt_command='run',
        select='stg_territories',
        full_refresh=True
    )

    # Run curated models after all staging models
    dbt_run_curated_task = DbtCoreOperator(
        task_id='dbt_run_curated',
        dbt_project_dir=DBT_PROJECT_PATH,
        dbt_profiles_dir=DBT_PROJECT_PATH,
        dbt_command='run',
        select='tag:curated',
        full_refresh=True
    )

    
    # Define the task dependencies - sequential execution to avoid Iceberg conflicts
    dbt_seed_task >> dbt_run_stg_categories >> dbt_run_stg_subcategories >> dbt_run_stg_products >> dbt_run_stg_sales >> dbt_run_stg_territories >> dbt_run_curated_task
