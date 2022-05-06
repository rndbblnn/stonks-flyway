CREATE SEQUENCE hibernate_sequence START 1;
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

CREATE TABLE pattern_match (
    id bigint NOT NULL,
	pattern_name VARCHAR(50) NOT NULL,
    symbol VARCHAR(12) NOT NULL,
	pattern_time timestamp NOT NULL,
    "created" timestamp DEFAULT CURRENT_TIMESTAMP,
	UNIQUE(pattern_name, symbol, pattern_time)
);

CREATE TABLE ticks (
    id bigint NOT NULL,
    symbol VARCHAR(12) NOT NULL,
    timeframe VARCHAR(12) NOT NULL,
    tick_time timestamp NOT NULL,
    created TIMESTAMP NOT NULL,
      open_price double precision NULL,
      high_price double precision NULL,
      low_price double precision NULL,
      close_price double precision NULL,
      volume BIGINT NULL,
      sma6 double precision NULL,
      sma10 double precision NULL,
      sma20 double precision NULL,
      sma50 double precision NULL,
      sma100 double precision NULL,
      sma200 double precision NULL,
      dv_buying double precision NULL,
      dv_buying_sma20 double precision NULL,
      dv_selling double precision NULL,
      dv_selling_sma20 double precision NULL,
      rti3 double precision NULL,
      rti4 double precision NULL,
      rti5 double precision NULL,
      rti6 double precision NULL,
      three_inside_days double precision NULL,
      ADR double precision NULL,
      ATR20 double precision NULL,
      market_cap double precision NULL,
      shares_outstanding BIGINT,
      shares_float BIGINT,
      eps_last_qtr double precision NULL,
      iwm_close_price double precision NULL,
      iwm_sma10 double precision NULL,
      iwm_sma20 double precision NULL,
      iwm_sma50 double precision NULL,
      iwm_di_positive double precision NULL,
      iwm_di_negative double precision NULL,

    UNIQUE(symbol, tick_time)
);
CREATE INDEX ON ticks (UPPER(symbol));

SELECT create_hypertable('ticks', 'tick_time');
