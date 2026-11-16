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
        trim(lifnr) as vendor_id,
        trim(name1) as vendor_name,
        trim(land1) as country_code,
        trim(ort01) as city,
        trim(pstlz) as postal_code,
        trim(ktokk) as account_group,
        nullif(trim(loevm), '') as deletion_flag,
        cast(erdat as date) as created_date,
        lower(trim(is_critical)) = 'true' as is_critical,
        nullif(trim(critical_reason), '') as critical_reason
    from raw

)

select * from renamed