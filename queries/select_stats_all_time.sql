select metric, round(val::numeric,2) FROM (
	select '01: Average win % ' AS "metric", 100*AVG(pnl_percent) AS "val" from trades where pnl_dollar >= 5
	union
	select '02: Average loss %' AS "metric", 100*AVG(pnl_percent)  from trades where pnl_dollar <= -5
	union
	select '03: win count ' AS "metric", count(*) AS "val" from trades where pnl_percent > 0.003
	union
	select '04: loss count' AS "metric", count(*) AS "val" from trades where pnl_percent < -0.003
	union
	select '05: B/E count' AS "metric", count(*) AS "val" from trades where pnl_percent > -0.003 AND pnl_percent < 0.003
	union
	select '06: win % ' AS "metric", ((SELECT cast(count(*) as real) from trades where pnl_dollar >= 5) / (SELECT cast(count(*) as real) from trades))
	union
	select '07: loss % ' AS "metric", ((SELECT cast(count(*) as real) from trades where pnl_dollar <= -5) / (SELECT cast(count(*) as real) from trades)) 
	union
	select '08: B/E % ' AS "metric", ((SELECT cast(count(*) as real) from trades where pnl_dollar < 5 and pnl_dollar > -5) / (SELECT cast(count(*) as real) from trades)) 
	UNION
	select '09: win total $' AS "metric", SUM(pnl_dollar) from trades where pnl_dollar >= 5
	UNION
	select '10: loss total $' AS "metric", SUM(pnl_dollar) from trades where pnl_dollar <= -5
	UNION
	select '11: B/E total $' AS "metric", SUM(pnl_dollar) from trades where pnl_dollar < 5 and pnl_dollar > -5
) tmp
ORDER BY 1 ASC
;


select * from loss_metrics_pct_all_months() order by date desc, metric asc;

select * from loss_metrics_dollar_all_months() order by date desc, metric asc;

select * from trades order by exit_time desc;