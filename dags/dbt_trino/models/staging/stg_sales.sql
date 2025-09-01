{{ config(materialized='table') }}

SELECT 
    date_parse(order_date, '%m/%d/%Y') AS order_date,
    date_parse(stock_date, '%m/%d/%Y') AS stock_date,
    order_number,
    product_key,
    customer_key,
    territory_key,
    order_quantity
FROM {{ ref('sales') }}
