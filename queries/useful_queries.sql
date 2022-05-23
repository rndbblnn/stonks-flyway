select * from trade_metrics('2022-05-15', '2022-05-21') order by date desc;
select * from group_metrics_pct('2022-05-15', '2022-05-21') order by date desc, metric asc;
select * from group_metrics_dollar('2022-05-15', '2022-05-21') order by date desc, metric asc;


-- top 10 $ winners
select * from trades
where exit_time >= '2022-05-15' and exit_time <= '2022-05-21' 
and pnl_dollar > 0
order by pnl_dollar desc, exit_time desc
limit 10;

-- top 10 $ losers
select * from trades
where exit_time >= '2022-05-15' and exit_time <= '2022-05-21' 
and pnl_dollar < 0
order by pnl_dollar asc, exit_time desc
limit 10;

-- top 10 % losers
select * from trades
where exit_time >= '2022-05-15' and exit_time <= '2022-05-21' 
and pnl_percent  < 0
order by pnl_percent asc, exit_time desc
limit 10;