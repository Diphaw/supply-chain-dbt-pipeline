{{ config(
    materialized='table',
    schema='gold'
) }}

select
    product_id,
    product_name,
    category_id,
    category_name,
    department_id,
    department_name,
    product_price,
    product_status
from {{ ref('stg_products') }}
