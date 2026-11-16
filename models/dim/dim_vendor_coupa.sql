with src as (

    select
        vendor_id,
        vendor_name,
        country_code,
        city,
        postal_code,
        status,
        created_at,
        is_critical,
        critical_reason
    from {{ ref('src_vendor_coupa') }}

),

deduped as (

    select
        vendor_id,
        vendor_name,
        country_code,
        city,
        postal_code,
        status,
        created_at,
        is_critical,
        critical_reason
    from src
    qualify row_number() over (
        partition by vendor_id
        order by created_at desc
    ) = 1

),

final as (

    select
        vendor_id,
        vendor_name,
        country_code,
        city,
        postal_code,
        status,
        created_at,
        status = 'active' as is_active,
        coalesce(is_critical, false) as is_critical,
        case
            when coalesce(is_critical, false)
            then critical_reason
        end as critical_reason
    from deduped

)

select
    vendor_id,
    vendor_name,
    country_code,
    city,
    postal_code,
    status,
    created_at,
    is_active,
    is_critical,
    critical_reason
from final