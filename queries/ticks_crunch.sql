select symbol, tick_time , close_price , sma10 from ticks t where symbol = 'ENPH' order by tick_time desc;
select count(*) from (select distinct symbol from ticks) z;

with avg10 as (
select symbol, tick_time, close_price ,
AVG(close_price) OVER(ORDER BY symbol,tick_time
      ROWS BETWEEN 9 PRECEDING AND CURRENT ROW)
    AS avg_price
  FROM ticks
  WHERE sma10 IS NULL
) 
update ticks set sma10 = avg10.avg_price from avg10
where ticks.symbol  = avg10.symbol 
and ticks.tick_time = avg10.tick_time ;




SELECT dvday.symbol, dvday.tick_time, dvday.dollar_volume, dvavg20.dvavg20 FROM (
	SELECT symbol, tick_time, ((high_price + low_price)/2) * volume / 1000000 AS dollar_volume
	FROM ticks
	WHERE ((high_price + low_price)/2) * volume / 1000000  > 1
) dvday
LEFT JOIN 
(
	SELECT * FROM (
		SELECT symbol, tick_time,
		AVG( ((high_price + low_price)/2) * volume / 1000000) OVER(ORDER BY symbol,tick_time
		      ROWS BETWEEN 19 PRECEDING AND CURRENT ROW)
		    AS dvavg20
		  FROM ticks
	) dvavg20
	WHERE dvavg20.dvavg20 > 3
) dvavg20
ON dvday.symbol = dvavg20.symbol 
AND dvday.tick_time = dvavg20.tick_time 
LEFT JOIN 
(
	SELECT * FROM (
		SELECT symbol, tick_time,
		MIN( ((high_price + low_price)/2) * volume / 1000000) OVER(ORDER BY symbol,tick_time
		      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
		    AS dvminavg3
		  FROM ticks
	) dvminavg3
	WHERE dvminavg3.dvminavg3 > 2
) dvminavg3
ON dvday.symbol = dvminavg3.symbol 
AND dvday.tick_time = dvminavg3.tick_time 
WHERE (dvavg20.dvavg20 IS NOT NULL OR dvminavg3.dvminavg3 IS NOT NULL)
;

-- TR

SELECT p1-p2 AS ATR, * FROM (
	SELECT *,
		CASE
		    WHEN high_price > prev_close THEN high_price
		    ELSE prev_close
		  END 
		  AS p1,
		  CASE
		    WHEN low_price > prev_close THEN prev_close
		    ELSE low_price
		  END 
		  AS p2	  
	FROM (
		SELECT symbol, tick_time, open_price, high_price, low_price, close_price, prev_close FROM (
			select symbol, tick_time,  open_price, high_price, low_price, close_price,
					lag(low_price, 1) OVER(ORDER BY symbol,tick_time
					      ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
					    AS prev_close
			FROM ticks
		) x
	) tmp
) atr
WHERE symbol = 'ENPH'
ORDER BY tick_time DESC
;


select
    *, ATR = iif([high] > yest_close, [high], yest_close) - iif([low] > yest_close, yest_close, [low])
from (
    select 
        *, yest_close = lag([close]) over (partition by Ticker order by [Datecol])
    from @t
) t









































