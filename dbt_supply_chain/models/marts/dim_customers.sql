{{ config(
    materialized='table',
    schema='gold'
) }}

with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

customer_metrics as (
    select
        customer_id,
        count(distinct order_id) as total_lifetime_orders,
        sum(sales_amount) as total_lifetime_spend,
        min(order_timestamp) as first_order_date,
        max(order_timestamp) as last_order_date
    from orders
    group by customer_id
)

select
    c.customer_id,
    c.customer_first_name,
    c.customer_last_name,
    c.customer_segment,
    c.customer_city,
    c.customer_state,
    c.customer_country,
    c.customer_zipcode,
    c.customer_latitude,
    c.customer_longitude,
    coalesce(m.total_lifetime_orders, 0) as total_lifetime_orders,
    coalesce(m.total_lifetime_spend, 0.00) as total_lifetime_spend,
    m.first_order_date,
    m.last_order_date
from customers c
left join customer_metrics m 
    on c.customer_id = m.customer_id
