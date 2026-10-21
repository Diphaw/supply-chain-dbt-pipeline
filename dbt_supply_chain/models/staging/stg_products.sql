{{ config(materialized='view') }}

with source_data as (
    select * from {{ source('bronze', 'raw_supply_chain') }}
),

deduped_products as (
    select
        product_card_id::bigint as product_id,
        trim(product_name) as product_name,
        category_id::int as category_id,
        trim(category_name) as category_name,
        department_id::int as department_id,
        trim(department_name) as department_name,
        product_price::numeric(10, 2) as product_price,
        product_status::int as product_status,
        row_number() over (
            partition by product_card_id 
            order by _ingested_at desc
        ) as rn
    from source_data
    where product_card_id is not null
)

select
    product_id,
    product_name,
    category_id,
    category_name,
    department_id,
    department_name,
    product_price,
    product_status
from deduped_products
where rn = 1
