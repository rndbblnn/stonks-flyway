-- DROP FUNCTION trade_metrics();
CREATE OR REPLACE FUNCTION trade_metrics()
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
END LOOP;
END;
$func$
LANGUAGE plpgsql;

select * from trade_metrics() order by date desc;

 --DROP FUNCTION loss_metrics_v1();
CREATE OR REPLACE FUNCTION loss_metrics_v1()
  RETURNS TABLE ("%" text, "avg win $" bigint, "avg loss $" numeric, "avg win %" numeric, "avg loss %" numeric)
  AS
$func$
DECLARE
    datecur record;
	datefrom date;
	dateto date;
	trade_cnt int;
	loss_cnt int;
    a integer := 10;
BEGIN
FOR datecur IN
	SELECT (date_trunc('month', now()) + interval '1 month - 1 day')::date as month
LOOP
  datefrom := datecur.month;
  dateto := date_trunc('month', datecur.month) + interval '1 month - 1 day';
  trade_cnt := (SELECT cast(count(*) as real) from trades where exit_time >= datefrom and exit_time <= dateto);
  loss_cnt := (SELECT cast(count(*) as real) from trades where pnl_percent < 0 and exit_time >= datefrom and exit_time <= dateto);
  IF trade_cnt = 0 THEN
  	trade_cnt := 1;
  END IF;
  IF loss_cnt = 0 THEN
  	loss_cnt := 1;
  END IF;
  RETURN QUERY
	SELECT
		'> -1%',
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.01 and pnl_percent<0),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.01 and pnl_percent<0),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.01 and pnl_percent<0) / loss_cnt)::numeric,2)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.01 and pnl_percent<0) / trade_cnt)::numeric,2))
	UNION
	SELECT
		'> -2%',
		(SELECT count(*) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.02 and pnl_percent <= 0.01),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where  exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.02 and pnl_percent <= 0.01),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.02 and pnl_percent <= 0.01) / loss_cnt)::numeric,2)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.02 and pnl_percent <= 0.01) / trade_cnt)::numeric,2))
	UNION
	SELECT
		'-1 -> -2%',
		(SELECT count(*) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.02 and pnl_percent<= -0.01),
		(SELECT round(SUM(pnl_dollar)::numeric,2) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.02 and pnl_percent<= -0.01),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.02 and pnl_percent<= -0.01) / loss_cnt)::numeric,2)),
		(SELECT round(100*((SELECT cast(count(*) as real) from trades where exit_time >= datefrom AND exit_time <= dateto and pnl_percent > -0.02 and pnl_percent<= -0.01) / trade_cnt)::numeric,2))
	;
END LOOP;
END;
$func$
LANGUAGE plpgsql;

select * from loss_metrics_v1() ;
