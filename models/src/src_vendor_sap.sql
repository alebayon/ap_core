with raw as (

    select
        lifnr,
        name1,
        land1,
        ort01,
        pstlz,
        ktokk,
        loevm,
        erdat,
        is_critical,
        critical_reason
    from {{ ref('raw_vendor_sap') }}

),

renamed as (

    select
        lpad(trim(cast(lifnr as varchar)), 10, '0') as vendor_id,
        trim(name1) as vendor_name,
        trim(land1) as country_code,
        trim(ort01) as city,
        trim(pstlz) as postal_code,
        trim(ktokk) as account_group,
        nullif(trim(loevm), '') as deletion_flag,
        cast(erdat as date) as created_date,
        coalesce(
            try_to_boolean(cast(is_critical as varchar)),
            lower(trim(cast(is_critical as varchar))) = 'true'
        ) as is_critical,
        nullif(trim(cast(critical_reason as varchar)), '') as critical_reason
    from raw

)

select * from renamed