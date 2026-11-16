-- subprocess rows for 32 KR curriculum (+ v0.1.2 OTP heroes)
select count(*) as row_count
from {{ ref('fct_inv_timing_span') }}
where phase_level = 'subprocess'
having count(*) != 164