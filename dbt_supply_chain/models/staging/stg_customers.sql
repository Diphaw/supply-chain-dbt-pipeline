{{ config(materialized='view') }}

with source_data as (
    select * from {{ source('bronze', 'raw_supply_chain') }}
),

deduped_customers as (
    select
        order_customer_id::bigint as customer_id,
        trim(customer_fname) as customer_first_name,
        trim(customer_lname) as customer_last_name,
        lower(trim(customer_segment)) as customer_segment,
        trim(customer_city) as customer_city,
        trim(customer_state) as customer_state,
        trim(customer_country) as customer_country,
        customer_zipcode::text as customer_zipcode,
        trim(customer_street) as customer_street,
        latitude::numeric(10, 6) as customer_latitude,
        longitude::numeric(10, 6) as customer_longitude,
        row_number() over (
            partition by order_customer_id 
            order by to_timestamp(order_date_dateorders, 'MM/DD/YYYY HH24:MI') desc
        ) as rn
    from source_data
    where order_customer_id is not null
)

select
    customer_id,
    customer_first_name,
    customer_last_name,
    customer_segment,
    customer_city,
    customer_state,
    customer_country,
    customer_zipcode,
    customer_street,
    customer_latitude,
    customer_longitude
from deduped_customers
where rn = 1
