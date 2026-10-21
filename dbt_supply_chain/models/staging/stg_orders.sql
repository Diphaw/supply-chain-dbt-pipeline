{{ config(materialized='view') }}

with source_data as (
    select * from {{ source('bronze', 'raw_supply_chain') }}
),

renamed_and_cast as (
    select
        -- Primary & Foreign Keys
        order_item_id::bigint as order_item_id,
        order_id::bigint as order_id,
        order_customer_id::bigint as customer_id,
        department_id::int as department_id,
        category_id::int as category_id,
        product_card_id::bigint as product_id,

        -- Dates & Timestamps
        to_timestamp(order_date_dateorders, 'MM/DD/YYYY HH24:MI')::timestamp as order_timestamp,
        to_timestamp(shipping_date_dateorders, 'MM/DD/YYYY HH24:MI')::timestamp as shipping_timestamp,

        -- Order & Shipping Attributes
        lower(trim(order_status)) as order_status,
        lower(trim(type)) as payment_type,
        lower(trim(shipping_mode)) as shipping_mode,
        lower(trim(delivery_status)) as delivery_status,
        days_for_shipping_real::int as actual_shipping_days,
        days_for_shipment_scheduled::int as scheduled_shipping_days,
        late_delivery_risk::int as late_delivery_risk_flag,

        -- Financial Metrics
        order_item_quantity::int as order_item_quantity,
        order_item_product_price::numeric(10, 2) as product_unit_price,
        order_item_total::numeric(10, 2) as item_total_amount,
        order_item_discount::numeric(10, 2) as discount_amount,
        order_item_discount_rate::numeric(5, 4) as discount_rate,
        order_item_profit_ratio::numeric(6, 4) as profit_ratio,
        sales::numeric(10, 2) as sales_amount,

        -- Audit Metadata
        _ingested_at

    from source_data
)

select * from renamed_and_cast
