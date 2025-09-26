{{ config(materialized='table') }}

-- Force dependency on product_categories to avoid concurrency issues
{% set _ = ref('stg_product_categories') %}

SELECT *

FROM {{ ref('product_subcategories') }}