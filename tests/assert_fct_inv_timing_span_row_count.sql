-- ownership only: 32 invoices x 2 phases (v0.1.2 OTP heroes); SAP-only rows are payment-measured only
select
    total_rows,
    measured_rows
from (
    select
        count(*) as total_rows,
        count(case when span_status = 'measured' then 1 end) as measured_rows
    from {{ ref('fct_inv_timing_span') }}
    where phase_level = 'ownership'
)
where total_rows != 64
   or measured_rows != 55