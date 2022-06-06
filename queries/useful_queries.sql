-- truncate table trades cascade;
-- truncate table trade_executions cascade;
select * from trade_metrics_all_months() order by date desc;

select * from trade_metrics('2022-05-29', '2022-06-04') order by date desc;
select * from group_metrics_pct('2022-05-29', '2022-06-04') order by date desc, metric asc;
select * from group_metrics_dollar('2022-05-29', '2022-06-04') order by date desc, metric asc;


-- top 10 $ winners
select symbol, trade_direction, exit_time, qty_total, pnl_dollar - fees_total as "pnl_dollar_inc_fees", pnl_percent
from trades
where exit_time >= '2022-05-29' and exit_time <= '2022-06-04'
and pnl_dollar > 0
order by pnl_dollar desc, exit_time desc
limit 10;

-- top 10 $ losers
select symbol, trade_direction, exit_time, qty_total, pnl_dollar - fees_total as "pnl_dollar_inc_fees", pnl_percent
from trades
where exit_time >= '2022-05-29' and exit_time <= '2022-06-04'
and pnl_dollar < 0
order by pnl_dollar asc, exit_time desc
limit 10;

-- top 10 % losers
select symbol, trade_direction, exit_time, qty_total, pnl_dollar - fees_total as "pnl_dollar_inc_fees", pnl_percent
from trades
where exit_time >= '2022-05-29' and exit_time <= '2022-06-04'
and pnl_percent  < 0
order by pnl_percent asc, exit_time desc
limit 10;