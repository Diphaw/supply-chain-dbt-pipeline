{{ config(
    materialized='table',
    schema='gold'
) }}

with orders as (
    select * from {{ ref('stg_orders') }}
)

select
    order_item_id,
    order_id,
    customer_id,
    product_id,
    category_id,
    department_id,
    order_timestamp,
    shipping_timestamp,
    cast(order_timestamp as date) as order_date,
    cast(shipping_timestamp as date) as shipping_date,
    order_status,
    payment_type,
    shipping_mode,
    delivery_status,
    late_delivery_risk_flag,
    actual_shipping_days,
    scheduled_shipping_days,
    (actual_shipping_days - scheduled_shipping_days) as shipping_delay_days,
    case 
        when actual_shipping_days > scheduled_shipping_days then 1 
        else 0 
    end as is_delayed,
    order_item_quantity,
    product_unit_price,
    item_total_amount,
    discount_amount,
    discount_rate,
    sales_amount,
    round((sales_amount * profit_ratio), 2) as estimated_profit_amount,
    profit_ratio
from orders
