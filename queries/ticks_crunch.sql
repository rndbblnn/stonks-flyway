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


-- DV
SELECT symbol, tick_time, 
		lag(((high_price + low_price)/2) * volume / 1000000, 0) OVER(ORDER BY symbol,tick_time
		      ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
		    AS value
FROM ticks;

-- AVGDV
SELECT symbol, tick_time, value, LAG(value,1) OVER (ORDER BY symbol,tick_time) FROM (
	select symbol, tick_time, close_price ,
	AVG(((high_price + low_price)/2) * volume / 1000000) OVER(ORDER BY symbol,tick_time
	      ROWS BETWEEN 9 PRECEDING AND CURRENT ROW)
	    AS value
	  FROM ticks
) tmp
ORDER BY symbol,tick_time  desc;


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
-- WHERE (dvavg20.dvavg20 IS NOT NULL OR dvminavg3.dvminavg3 IS NOT NULL)
;

-- TR
UPDATE ticks t SET tr = sub.tr
FROM (
	SELECT symbol, tick_time, GREATEST(high_price-low_price,high_price-prev_close,low_price-prev_close) AS tr
	FROM (
		SELECT *,
			CASE
			    WHEN high_price > low_price THEN prev_close
			    ELSE low_price
			  END 
			  AS hl,	 
			CASE
			    WHEN high_price > prev_close THEN high_price
			    ELSE prev_close
			  END 
			  AS hc,
			CASE
			    WHEN low_price > prev_close THEN prev_close
			    ELSE low_price
			  END 
			  AS lc	  
		FROM (
			SELECT symbol, tick_time, open_price, high_price, low_price, close_price, prev_low, prev_close FROM (
				select symbol, tick_time,  open_price, high_price, low_price, close_price,
						lag(close_price, 1) OVER(ORDER BY symbol,tick_time
						      ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
						    AS prev_close,
						lag(low_price, 1) OVER(ORDER BY symbol,tick_time
						      ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
						    AS prev_low
				FROM ticks
			) subq111
		) subq11
	) subq1 
) sub
WHERE t.tr IS NULL 
AND t.symbol = sub.symbol
AND t.tick_time  = sub.tick_time;


SELECT * FROM ticks WHERE symbol ='ENPH' ORDER BY tick_time DESC;
UPDATE ticks SET tr = NULL;


SELECT symbol, tick_time, value, LAG(value,1) OVER (ORDER BY symbol,tick_time) FROM (
	select symbol, tick_time, close_price ,
		AVG(tr_pct) OVER(ORDER BY symbol,tick_time ROWS BETWEEN 9 PRECEDING AND CURRENT ROW) AS value
	  FROM ticks
	 WHERE symbol = 'ENPH'
) tmp
ORDER BY tick_time  desc;




SELECT ticks.symbol, ticks.tick_time, 
ind_d_atr20.value AS ind_d_atr20,
ind_d_avgc10.value AS ind_d_avgc10,
ind_d_avgc20.value AS ind_d_avgc20,
ind_d_dv0.value AS ind_d_dv0,
ind_d_mindv5.value AS ind_d_mindv5
FROM ticks
LEFT JOIN ind_d_atr20 USING (symbol, tick_time)
LEFT JOIN ind_d_avgc10 USING (symbol, tick_time)
LEFT JOIN ind_d_avgc20 USING (symbol, tick_time)
LEFT JOIN ind_d_dv0 USING (symbol, tick_time)
LEFT JOIN ind_d_mindv5 USING (symbol, tick_time)
WHERE ticks.symbol  = 'NFLX'
ORDER BY tick_time DESC;

SELECT symbol, tick_time, AVG(close_price) OVER(ORDER BY symbol,tick_time ROWS BETWEEN 9 PRECEDING AND CURRENT ROW) AS value
            FROM ticks 
          ORDER BY symbol,tick_time desc;

SELECT * FROM (
	SELECT symbol, tick_time, LAG(value, 1) OVER(ORDER BY symbol, tick_time) AS lag_value
	FROM ind_d_avgc10
) left1
JOIN (
	SELECT symbol, tick_time, LAG(value, 1) OVER(ORDER BY symbol, tick_time) AS lag_value
	FROM ind_d_avgc20
) right1
USING (symbol, tick_time)
WHERE left1.lag_value > right1.lag_value
AND symbol ='AMD';

ORDER BY tick_time DESC;







CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;




SELECT * FROM flyway_schema_history;





