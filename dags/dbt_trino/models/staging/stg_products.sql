{{ config(materialized='table') }}

SELECT *

FROM {{ ref('products') }}