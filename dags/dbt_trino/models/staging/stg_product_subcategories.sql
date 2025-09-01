{{ config(materialized='table') }}

SELECT *

FROM {{ ref('product_subcategories') }}