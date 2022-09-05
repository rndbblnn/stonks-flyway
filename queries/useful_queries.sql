-- truncate table trades cascade;
-- truncate table trade_executions cascade;
select * from trade_metrics_all_months() order by date desc;

select * from trade_metrics('2022-06-12', '2022-06-19') order by date desc;
select * from group_metrics_pct('2022-06-12', '2022-06-19') order by date desc, metric asc;
select * from group_metrics_dollar('2022-06-12', '2022-06-19') order by date desc, metric asc;


-- top 10 $ winners
select * 
from (
	select symbol, trade_direction, sum(qty_total) as "qty_total", sum(pnl_dollar) - sum(fees_total) as "pnl_dollar_inc_fees", sum(pnl_percent)*100 as "pnl_percent" 
	from trades 
	where exit_time >= '2022-06-12' and exit_time <= '2022-06-19'
	and pnl_dollar > 0
	group by symbol, trade_direction
) tmp
order by pnl_dollar_inc_fees desc
limit 10;

-- top 10 $ losers
select * 
from (
	select symbol, trade_direction, sum(qty_total) as "qty_total", sum(pnl_dollar) - sum(fees_total) as "pnl_dollar_inc_fees", sum(pnl_percent)*100 as "pnl_percent" 
	from trades 
	where exit_time >= '2022-06-12' and exit_time <= '2022-06-19'
	and pnl_dollar < 0
	group by symbol, trade_direction
) tmp
order by pnl_dollar_inc_fees asc
limit 10;

-- top 10 % losers
select * 
from (
	select symbol, trade_direction, sum(qty_total) as "qty_total", sum(pnl_dollar) - sum(fees_total) as "pnl_dollar_inc_fees", sum(pnl_percent)*100 as "pnl_percent" 
	from trades 
	where exit_time >= '2022-06-12' and exit_time <= '2022-06-19'
	and pnl_percent < 0
	group by symbol, trade_direction
) tmp
order by pnl_percent asc
limit 10;