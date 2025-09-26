{{ config(materialized='table') }}

-- Force dependency on sales to avoid concurrency issues
{% set _ = ref('stg_sales') %}

SELECT *

FROM {{ ref('territories') }}

