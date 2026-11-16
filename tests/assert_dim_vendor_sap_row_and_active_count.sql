-- 9 vendors total; 8 active (0000100005 LOEVM=X retained; 0000100009 Finanzamt)
select count(*) as vendor_count
from {{ ref('dim_vendor_sap') }}
having count(*) != 9

union all

select count(*) as active_count
from {{ ref('dim_vendor_sap') }}
where is_active
having count(*) != 8