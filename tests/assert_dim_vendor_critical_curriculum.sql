-- SAP: exactly two critical vendors
select 'sap_critical_count' as violation
from {{ ref('dim_vendor_sap') }}
where is_critical
having count(*) != 2

union all

select vendor_id
from {{ ref('dim_vendor_sap') }}
where is_critical
  and vendor_id not in ('0000100004', '0000100009')

union all

select vendor_id
from {{ ref('dim_vendor_sap') }}
where is_critical
  and (critical_reason is null or trim(critical_reason) = '')

union all

-- Coupa: exactly two critical suppliers
select 'coupa_critical_count' as violation
from {{ ref('dim_vendor_coupa') }}
where is_critical
having count(*) != 2

union all

select vendor_id
from {{ ref('dim_vendor_coupa') }}
where is_critical
  and vendor_id not in ('9000004', '9000009')

union all

select vendor_id
from {{ ref('dim_vendor_coupa') }}
where is_critical
  and (critical_reason is null or trim(critical_reason) = '')