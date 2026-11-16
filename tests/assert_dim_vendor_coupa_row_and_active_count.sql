-- 8 suppliers total; 7 active (9000005 inactive retained; 9000009 Finanzamt)
select count(*) as supplier_count
from {{ ref('dim_vendor_coupa') }}
having count(*) != 8

union all

select count(*) as active_count
from {{ ref('dim_vendor_coupa') }}
where is_active
having count(*) != 7