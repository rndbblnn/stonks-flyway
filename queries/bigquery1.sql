

-- inside day
SET statement_timeout = 600000;
select L1.symbol, L1.tick_time from 
(
	select * from 
			(select symbol, tick_time, low_price,
			lag(low_price, 1) OVER(ORDER BY symbol,tick_time
			      ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
			    AS value
			  FROM ticks) L1
	where L1.low_price > L1.value
) L1
join 
(
	select * from 
			(select symbol, tick_time, high_price,
			lag(high_price, 1) OVER(ORDER BY symbol,tick_time
			      ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
			    AS value
			  FROM ticks) H1
	where H1.high_price < H1.value
) H1
ON L1.symbol = H1.symbol 
AND L1.tick_time = H1.tick_time 
-- AVG10
JOIN (
	SELECT * FROM (
		SELECT symbol, tick_time, close_price ,
		AVG(close_price) OVER(ORDER BY symbol,tick_time
		      ROWS BETWEEN 9 PRECEDING AND CURRENT ROW)
		    AS value
		  FROM ticks
	) avg10
	WHERE avg10.close_price >= avg10.value
) avg10
ON L1.symbol = avg10.symbol 
AND L1.tick_time = avg10.tick_time 
-- AVG20
JOIN (
	SELECT * FROM (
		SELECT symbol, tick_time, close_price ,
		AVG(close_price) OVER(ORDER BY symbol,tick_time
		      ROWS BETWEEN 19 PRECEDING AND CURRENT ROW)
		    AS value
		  FROM ticks
	) avg20
	WHERE avg20.close_price >= avg20.value
) avg20
ON L1.symbol = avg20.symbol 
AND L1.tick_time = avg20.tick_time 
-- DV group
JOIN (
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
) DV
ON L1.symbol = DV.symbol 
AND L1.tick_time = DV.tick_time 
;