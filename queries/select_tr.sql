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
) subq1 ;
