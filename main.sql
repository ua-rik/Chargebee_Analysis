with
    subs_coupons_ads as (
    select
        s.id        as subs_id
    ,   c.id        as coupon_id
    ,   c_a.value   as addon_id
    from cb_upfluence.subscriptions s
        -- join addons
    left join cb_upfluence.subscriptions__coupons s_c on s.id=s_c._sdc_source_key_id
    left join cb_upfluence.coupons c on  s_c.coupon_id = c.id
    left join cb_upfluence.coupons__addon_ids c_a on c.id = c_a._sdc_source_key_id

),
    subs_ads_coupons as (
        select
            s_a._sdc_source_key_id as subs_is
        ,   s_a.id as addon_id
        ,   sca.coupon_id
        from cb_upfluence.subscriptions__addons s_a
        left join subs_coupons_ads sca on s_a._sdc_source_key_id = sca.subs_id and s_a.id = sca.addon_id
    )




select
-- subs
    "upflu" as source_name
,   s.id
,   s.customer_id
,   s.activated_at
,   s.billing_period
,   s.billing_period_unit
,   s.coupon
,   s.current_term_start
,   s.current_term_end
,   s.due_since
,   s.mrr
,   s.plan_amount
,   s.plan_id
,   s.remaining_billing_cycles
-- adds
,   a.id AS addon_id
,   a.price AS price
,   a.currency_code
,   case
        when a.currency_code = "EUR" then  a.price * 1.1
        else a.price
    end as price_USD
-- coupons
,   c.id as coupon_id
,   c.currency_code as discount_currency
,   c.discount_amount
,   c.discount_percentage
,   c.discount_type
    -- Calculated fields
,   CASE -- %
        when
            c.discount_percentage IS NOT NULL
        then (case
                when a.currency_code = "EUR" then  a.price * 1.1
                else a.price
            end) * c.discount_percentage / 100
        -- not %
        ELSE (case  --
                when c.currency_code= "EUR" then  COALESCE(c.discount_amount, 0)  * 1.1
                else COALESCE(c.discount_amount, 0)
            end)
    END AS discount_amount_USD
,   (case
        when a.currency_code = "EUR" then  a.price * 1.1
        else a.price
    end) - (CASE -- %
        when
            c.discount_percentage IS NOT NULL
        then (case
                when a.currency_code = "EUR" then  a.price * 1.1
                else a.price
            end) * c.discount_percentage / 100
        -- not %
        ELSE (case  --
                when c.currency_code= "EUR" then  COALESCE(c.discount_amount, 0)  * 1.1
                else COALESCE(c.discount_amount, 0)
            end)
    END) AS final_price_USD


from cb_upfluence.subscriptions s
    -- join addons_coupons id
left join subs_ads_coupons s_a_c on s.id = s_a_c.subs_is
    -- join facts and *dimentions
    -- addons
left join cb_upfluence.addons a on  s_a_c.addon_id = a.id
    -- coupons
left join cb_upfluence.coupons c on  s_a_c.coupon_id = c.id

order by s.id
limit 100;

