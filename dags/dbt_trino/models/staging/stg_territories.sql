{{ config(materialized='table') }}

SELECT *

FROM {{ ref('territories') }}

