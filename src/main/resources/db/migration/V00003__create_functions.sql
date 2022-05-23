DROP FUNCTION if exists trade_metrics();
DROP FUNCTION if exists trade_metrics(date, date);

CREATE OR REPLACE FUNCTION trade_metrics(datefrom date, dateto date)
  RETURNS TABLE ("date" date, "avg win $" numeric, "avg loss $" numeric, "avg win %" numeric, "avg loss %" numeric, "trade count" bigint, "win count" bigint, "loss count" bigint, "B/E count" bigint, "win %" numeric, "loss %" numeric, 
				 "B/E %" numeric,  "avg win $ per day" numeric, "avg loss $ per day" numeric, "avg $ per day" numeric, "total win $" numeric, "total loss $" numeric, "total B/E $" numeric, "total fees" numeric, "total $" numeric, "total $ inc fees" numeric)
  AS
$func$
DECLARE
    datecur record;
	trade_cnt int;
    a integer := 10;  
BEGIN
  trade_cnt := (SELECT cast(count(*) as real) from trades where exit_time >= datefrom and exit_time <= dateto);
  IF trade_cnt = 0 THEN
  	trade_cnt := 1;
  END IF;
  RETURN QUERY SELECT
  datefrom,
  /* avg win $          */  (SELECT round(AVG(pnl_dollar)::numeric,2) from trades where pnl_dollar >= 5 AND exit_time >= datefrom and exit_time <= dateto),
  /* avg loss $         */ (SELECT round(AVG(pnl_dollar)::numeric,2) from trades where pnl_dollar <= -5 AND exit_time >= datefrom and exit_time <= dateto),
  /* avg win %          */  (SELECT round(100*AVG(pnl_percent)::numeric,2) from trades where pnl_dollar >= 5 AND exit_time >= datefrom and exit_time <= dateto),
  /* avg loss %         */ (SELECT round(100*AVG(pnl_percent)::numeric,2) from trades where pnl_dollar <= -5 AND exit_time >= datefrom and exit_time <= dateto),
  /* total count        */ (SELECT count(*) from trades where  exit_time >= datefrom and exit_time <= dateto),
  /* win count          */ (SELECT count(*) from trades where pnl_dollar >= 5 AND exit_time >= datefrom and exit_time <= dateto),
  /* loss count         */ (SELECT count(*) from trades where pnl_dollar <= -5 AND exit_time >= datefrom and exit_time <= dateto),
  /* B/E count          */ (SELECT count(*) from trades where pnl_dollar < 5 and pnl_dollar > -5 AND exit_time >= datefrom and exit_time <= dateto),
  /* win %              */ (SELECT round(100*((SELECT cast(count(*) as real) from trades where pnl_dollar >= 5 AND exit_time >= datefrom and exit_time <= dateto) / trade_cnt)::numeric,2)),
  /* loss %             */ (SELECT round(100*((SELECT cast(count(*) as real) from trades where pnl_dollar <= -5 AND exit_time >= datefrom and exit_time <= dateto) / trade_cnt)::numeric,2)),
  /* B/E %              */ (SELECT round(100*((SELECT cast(count(*) as real) from trades where pnl_dollar < 5 and pnl_dollar > -5 AND exit_time >= datefrom and exit_time <= dateto) / trade_cnt)::numeric,2)),
  /* avg win $ per day  */ (SELECT round(SUM(pnl_dollar/20)::numeric,2) from trades where pnl_dollar >= 5 AND exit_time >= datefrom and exit_time <= dateto),
  /* avg loss $ per day */ (SELECT round(SUM(pnl_dollar/20)::numeric,2) from trades where pnl_dollar <= -5 AND exit_time >= datefrom and exit_time <= dateto),
  /* avg $ per day      */ (SELECT round(SUM(pnl_dollar/20)::numeric,2) from trades where exit_time >= datefrom and exit_time <= dateto),
  /* total win $        */ (SELECT round(SUM(pnl_dollar)::numeric,2) from trades where pnl_dollar >= 5 AND exit_time >= datefrom and exit_time <= dateto),
  /* total loss $       */ (SELECT round(SUM(pnl_dollar)::numeric,2) from trades where pnl_dollar <= -5 AND exit_time >= datefrom and exit_time <= dateto),
  /* total B/E $        */ (SELECT round(SUM(pnl_dollar)::numeric,2) from trades where pnl_dollar < 5 and pnl_dollar > -5 AND exit_time >= datefrom and exit_time <= dateto),
  /* fees $             */ (SELECT round(SUM(fees_total)::numeric,2) from trades where exit_time >= datefrom and exit_time <= dateto),
  /* total $            */ (SELECT round(SUM(pnl_dollar)::numeric,2) from trades where exit_time >= datefrom and exit_time <= dateto),
  /* total $ inc fees   */ (SELECT round(SUM(pnl_dollar-fees_total)::numeric,2) from trades where exit_time >= datefrom and exit_time <= dateto)
;
END;
$func$
LANGUAGE plpgsql;

select * from trade_metrics('2022-05-15', '2022-05-21') order by date desc;



DROP FUNCTION trade_metrics_all_months();
CREATE OR REPLACE FUNCTION trade_metrics_all_months()
  RETURNS TABLE ("date" date, "avg win $" numeric, "avg loss $" numeric, "avg win %" numeric, "avg loss %" numeric, "trade count" bigint, "win count" bigint, "loss count" bigint, "B/E count" bigint, "win %" numeric, "loss %" numeric, 
				 "B/E %" numeric,  "avg win $ per day" numeric, "avg loss $ per day" numeric, "avg $ per day" numeric, "total win $" numeric, "total loss $" numeric, "total B/E $" numeric, "total fees" numeric, "total $" numeric, "total $ inc fees" numeric)
  AS
$func$
DECLARE
    datecur record;
   	datefrom date;
	dateto date;
	trade_cnt int;
    a integer := 10;  
BEGIN
FOR datecur IN
	SELECT month::date FROM   generate_series(timestamp '2019-01-01', (date_trunc('month', now()) + interval '1 month - 1 day')::date, '1 month') month
LOOP
  datefrom := datecur.month;
  dateto := date_trunc('month', datecur.month) + interval '1 month - 1 day';
  return QUERY select * from trade_metrics(datefrom, dateto);
END LOOP;
END;
$func$
LANGUAGE plpgsql;

select * from trade_metrics_all_months() order by date desc;









DROP FUNCTION if exists group_metrics_pct();
DROP FUNCTION if exists group_metrics_pct(date,date);

CREATE OR REPLACE FUNCTION group_metrics_pct(datefrom date, dateto date)
  RETURNS TABLE ("date" date, "metric" text, "trade count" bigint, "% vs win/loss group" numeric, "% vs all trades" numeric, "$ PNL" numeric, "% vs all win/loss group $" numeric)
  AS
$func$
DECLARE
    datecur record;
	trade_cnt int;
	loss_cnt int;
	loss_dollar numeric;
	win_cnt int;
	win_dollar numeric;
    a integer := 10;
BEGIN
  trade_cnt := (SELECT cast(count(*) as real) from trades where exit_time >= datefrom and exit_time <= dateto);
  loss_cnt := (SELECT cast(count(*) as real) from trades where exit_time >= datefrom and exit_time <= dateto and pnl_percent < 0);
  loss_dollar := (SELECT sum(pnl_dollar) from trades where exit_time >= datefrom and exit_time <= dateto and pnl_dollar < 0);
  win_cnt := (SELECT cast(count(*) as real) from trades where exit_time >= datefrom and exit_time <= dateto and pnl_percent >= 0);
  win_dollar := (SELECT sum(pnl_dollar) from trades where exit_time >= datefrom and exit_time <= dateto and pnl_dollar >= 0);
 
  IF trade_cnt = 0 THEN
  	trade_cnt := 1;
  END IF;
  IF loss_cnt = 0 THEN
  	loss_cnt := 1;
  END IF;
  IF win_cnt = 0 THEN
  	win_cnt := 1;
  END IF;
 
 --raise INFO '% (%, %)', dateto, trade_cnt, loss_cnt;
 

  RETURN QUERY
	select 
		datefrom,
		'A) 0 => -1%',		
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.01 and pnl_percent < 0),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.01 and pnl_percent<0) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.01 and pnl_percent<0) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.01 and pnl_percent<0),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.01 and pnl_percent<0) / loss_dollar)::numeric,1))
		
	UNION
	select
		datefrom,
		'B) -1%',
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.02 and pnl_percent <= -0.01),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.02 and pnl_percent <= -0.01) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.02 and pnl_percent <= -0.01) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.02 and pnl_percent <= -0.01),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.02 and pnl_percent <= -0.01) / loss_dollar)::numeric,1))
	UNION
	select
		datefrom,
		'C) -2%',
		(SELECT count(*) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.03 and pnl_percent <= -0.02),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.03 and pnl_percent <= -0.02) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.03 and pnl_percent <= -0.02) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.03 and pnl_percent <= -0.02),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.03 and pnl_percent <= -0.02) / loss_dollar)::numeric,1))
	UNION
	select
		datefrom,
		'D) -3%',
		(SELECT count(*) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.04 and pnl_percent <= -0.03),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.04 and pnl_percent <= -0.03) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.04 and pnl_percent <= -0.03) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.04 and pnl_percent <= -0.03),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.04 and pnl_percent <= -0.03) / loss_dollar)::numeric,1))
	UNION
	select
		datefrom,
		'E) -4%',
		(SELECT count(*) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.05 and pnl_percent <= -0.04),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.05 and pnl_percent <= -0.04) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.05 and pnl_percent <= -0.04) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.05 and pnl_percent <= -0.04),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.05 and pnl_percent <= -0.04) / loss_dollar)::numeric,1))
	UNION
	select
		datefrom,
		'F) > 5%',
		(SELECT count(*) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent <= -0.05),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent <= -0.05) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent <= -0.05) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent <= -0.05),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent <= -0.05) / loss_dollar)::numeric,1))
		
	--
	union 
	select 
		datefrom,
		'G) 0%',		
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0 and pnl_percent < 0.01),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0 and pnl_percent < 0.01) / win_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0 and pnl_percent < 0.01) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0 and pnl_percent < 0.01),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0 and pnl_percent < 0.01) / win_dollar)::numeric,1))
		
	UNION
	select
		datefrom,
		'H) 1%',
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.01 and pnl_percent < 0.02),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.01 and pnl_percent < 0.02) / win_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.01 and pnl_percent < 0.02) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.01 and pnl_percent < 0.02),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.01 and pnl_percent < 0.02) / win_dollar)::numeric,1))
	UNION
	select
		datefrom,
		'I) 2%',
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.02 and pnl_percent < 0.03),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.02 and pnl_percent < 0.03) / win_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.02 and pnl_percent < 0.03) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.02 and pnl_percent < 0.03),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.02 and pnl_percent < 0.03) / win_dollar)::numeric,1))
	UNION
	select
		datefrom,
		'J) 3%',
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.03 and pnl_percent < 0.04),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.03 and pnl_percent < 0.04) / win_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.03 and pnl_percent < 0.04) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.03 and pnl_percent < 0.04),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.03 and pnl_percent < 0.04) / win_dollar)::numeric,1))
	UNION
	select
		datefrom,
		'K) 4%',
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.04 and pnl_percent < 0.05),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.04 and pnl_percent < 0.05) / win_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.04 and pnl_percent < 0.05) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.04 and pnl_percent < 0.05),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.04 and pnl_percent < 0.05) / win_dollar)::numeric,1))
	UNION
	select
		datefrom,
		'L) > 5%',
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.05),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.05) / win_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.05) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.05),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent >= 0.05) / win_dollar)::numeric,1))
	;
END;
$func$
LANGUAGE plpgsql;

select * from group_metrics_pct('2022-05-15', '2022-05-21') order by date desc, metric asc;






DROP FUNCTION if exists group_metrics_pct_all_months();

CREATE OR REPLACE FUNCTION group_metrics_pct_all_months()
  RETURNS TABLE ("date" date, "metric" text, "trade count" bigint, "% vs win/loss group" numeric, "% vs all trades" numeric, "$ PNL" numeric, "% vs all win/loss group $" numeric)
  AS
$func$
DECLARE
    datecur record;
	datefrom date;
	dateto date;
BEGIN
FOR datecur IN
		SELECT month::date FROM   generate_series(timestamp '2019-01-01', (date_trunc('month', now()) + interval '1 month - 1 day')::date, '1 month') month
LOOP
  datefrom := datecur.month;
  dateto := date_trunc('month', datecur.month) + interval '1 month - 1 day';
  
  return query 
    select * from group_metrics_pct(datefrom, dateto) order by date desc, metric asc;
 
END LOOP;
END;
$func$
LANGUAGE plpgsql;

select * from group_metrics_pct_all_months() order by date desc, metric asc;





DROP FUNCTION if exists group_metrics_dollar();
DROP FUNCTION if exists group_metrics_dollar(date,date);

CREATE OR REPLACE FUNCTION group_metrics_dollar(datefrom date, dateto date)
  RETURNS TABLE ("date" date, "metric" text, "trade count" bigint, "% vs win/loss group" numeric, "% vs all trades" numeric, "$ PNL" numeric, "% vs all win/loss group $" numeric)
  AS
$func$
DECLARE
	trade_cnt int;
	loss_cnt int;
	loss_dollar numeric;
	win_cnt int;
	win_dollar numeric;
BEGIN
  trade_cnt := (SELECT cast(count(*) as real) from trades where exit_time >= datefrom and exit_time <= dateto);
  loss_cnt := (SELECT cast(count(*) as real) from trades where exit_time >= datefrom and exit_time <= dateto and pnl_percent < 0);
  loss_dollar := (SELECT sum(pnl_dollar) from trades where exit_time >= datefrom and exit_time <= dateto and pnl_dollar < 0);
  win_cnt := (SELECT cast(count(*) as real) from trades where exit_time >= datefrom and exit_time <= dateto and pnl_percent >= 0);
  win_dollar := (SELECT sum(pnl_dollar) from trades where exit_time >= datefrom and exit_time <= dateto and pnl_dollar >= 0);
 
  IF trade_cnt = 0 THEN
  	trade_cnt := 1;
  END IF;
  IF loss_cnt = 0 THEN
  	loss_cnt := 1;
  END IF;
 IF win_cnt = 0 THEN
  	win_cnt := 1;
  END IF;
 
 --raise INFO '% (%, %)', dateto, trade_cnt, loss_cnt;
 
  RETURN QUERY
	select 
		datefrom,
		'A) 0',
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar < 0 and pnl_dollar > -50),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar < 0 and pnl_dollar > -50) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar < 0 and pnl_dollar > -50) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar < 0 and pnl_dollar > -50),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar < 0 and pnl_dollar > -50) / loss_dollar)::numeric,2))
	UNION
	select
		datefrom,
		'B) -50$ ',
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -50 and pnl_dollar > -100),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -50 and pnl_dollar > -100) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -50 and pnl_dollar > -100) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -50 and pnl_dollar > -100),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -50 and pnl_dollar > -100) / loss_dollar)::numeric,2))
	UNION
	select
		datefrom,
		'C) -100$',
		(SELECT count(*) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -100 and pnl_dollar > -200),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -100 and pnl_dollar > -200) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -100 and pnl_dollar > -200) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -100 and pnl_dollar > -200),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -100 and pnl_dollar > -200) / loss_dollar)::numeric,2))
	UNION
	select
		datefrom,
		'D) -200$',
		(SELECT count(*) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -200 and pnl_dollar > -300),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -200 and pnl_dollar > -300) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -200 and pnl_dollar > -300) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -200 and pnl_dollar > -300),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -200 and pnl_dollar > -300) / loss_dollar)::numeric,2))
	UNION
	select
		datefrom,
		'E) -300$',
		(SELECT count(*) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -300 and pnl_dollar > -400),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -300 and pnl_dollar > -400) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -300 and pnl_dollar > -400) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -300 and pnl_dollar > -400),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -300 and pnl_dollar > -400) / loss_dollar)::numeric,2))
	UNION
	select
		datefrom,
		'F) -400$',
		(SELECT count(*) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -400 and pnl_dollar > -500),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -400 and pnl_dollar > -500) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -400 and pnl_dollar > -500) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -400 and pnl_dollar > -500),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -300 and pnl_dollar > -400) / loss_dollar)::numeric,2))
	UNION
	select
		datefrom,
		'G) -500$',
		(SELECT count(*) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -500),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -500) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -500) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -500),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar <= -500) / loss_dollar)::numeric,2))
		
-- --------------------------------------
   union 
   select 
		datefrom,
		'H) 0',
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 0 and pnl_dollar < 50),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 0 and pnl_dollar < 50) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 0 and pnl_dollar < 50) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 0 and pnl_dollar < 50),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 0 and pnl_dollar < 50) / loss_dollar)::numeric,1))
	UNION
	select
		datefrom,
		'I) 50$ ',
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 50 and pnl_dollar < 100),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 50 and pnl_dollar < 100) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 50 and pnl_dollar < 100) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 50 and pnl_dollar < 100),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 50 and pnl_dollar < 100) / loss_dollar)::numeric,1))
	UNION
	select
		datefrom,
		'J) 100$',
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 100 and pnl_dollar < 200),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 100 and pnl_dollar < 200) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 100 and pnl_dollar < 200) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 100 and pnl_dollar < 200),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 100 and pnl_dollar < 200) / loss_dollar)::numeric,1))
	UNION
	select
		datefrom,
		'K) -200$',
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 200 and pnl_dollar < 300),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 200 and pnl_dollar < 300) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 200 and pnl_dollar < 300) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 200 and pnl_dollar < 300),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 200 and pnl_dollar < 300) / loss_dollar)::numeric,1))
	UNION
	select
		datefrom,
		'L) -300$',
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 300 and pnl_dollar < 400),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 300 and pnl_dollar < 400) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 300 and pnl_dollar < 400) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 300 and pnl_dollar < 400),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 300 and pnl_dollar < 400) / loss_dollar)::numeric,1))
	UNION
	select
		datefrom,
		'M) -400$',
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 400 and pnl_dollar < 500),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 400 and pnl_dollar < 500) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 400 and pnl_dollar < 500) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 400 and pnl_dollar < 500),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 400 and pnl_dollar < 500) / loss_dollar)::numeric,1))
	UNION
	select
		datefrom,
		'N) -500$',
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 500),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 500) / loss_cnt)::numeric,1)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 500) / trade_cnt)::numeric,1)),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 500),
		(SELECT round(100*((SELECT SUM(pnl_dollar) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_dollar >= 500) / loss_dollar)::numeric,1))
	;
END;
$func$
LANGUAGE plpgsql;

select * from group_metrics_dollar('2022-05-15', '2022-05-21') order by date desc, metric asc;






DROP FUNCTION if exists group_metrics_dollar_all_months();

CREATE OR REPLACE FUNCTION group_metrics_dollar_all_months()
  RETURNS TABLE ("date" date, "metric" text, "trade count" bigint, "% vs win/loss group" numeric, "% vs all trades" numeric, "$ PNL" numeric, "% vs all win/loss group $" numeric)
  AS
$func$
DECLARE
    datecur record;
	datefrom date;
	dateto date;
	trade_cnt int;
	loss_cnt int;
	loss_dollar numeric;
    a integer := 10;
BEGIN
FOR datecur IN
		SELECT month::date FROM   generate_series(timestamp '2019-01-01', (date_trunc('month', now()) + interval '1 month - 1 day')::date, '1 month') month
LOOP
  datefrom := datecur.month;
  dateto := date_trunc('month', datecur.month) + interval '1 month - 1 day';
  
  return query 
    select * from group_metrics_dollar(datefrom, dateto) order by date desc, metric asc;
 
END LOOP;
END;
$func$
LANGUAGE plpgsql;

select * from group_metrics_dollar_all_months() order by date desc, metric asc;












