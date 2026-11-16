with src as (

    select
        vendor_id,
        vendor_name,
        country_code,
        city,
        postal_code,
        account_group,
        deletion_flag,
        created_date,
        is_critical,
        critical_reason
    from {{ ref('src_vendor_sap') }}

),

deduped as (

    select
        vendor_id,
        vendor_name,
        country_code,
        city,
        postal_code,
        account_group,
        deletion_flag,
        created_date,
        is_critical,
        critical_reason
    from src
    qualify row_number() over (
        partition by vendor_id
        order by created_date desc
    ) = 1

),

final as (

    select
        vendor_id,
        vendor_name,
        country_code,
        city,
        postal_code,
        account_group,
        deletion_flag,
        created_date,
        deletion_flag is null as is_active,
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
    account_group,
    deletion_flag,
    created_date,
    is_active,
    is_critical,
    critical_reason
from final