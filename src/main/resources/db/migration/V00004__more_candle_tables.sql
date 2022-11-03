CREATE TABLE candle_d (
    id bigint NOT NULL,
    symbol VARCHAR(12) NOT NULL,
    tick_time timestamp NOT NULL,
    created TIMESTAMP NOT NULL,
      open_price double precision NULL,
      high_price double precision NULL,
      low_price double precision NULL,
      close_price double precision NULL,
      volume BIGINT NULL,
      tr double precision NULL,
      tr_pct double precision NULL,
    UNIQUE(symbol, tick_time)
);
CREATE INDEX ON candle_d (UPPER(symbol));
SELECT create_hypertable('candle_d', 'tick_time');

CREATE TABLE candle_1h (
    id bigint NOT NULL,
    symbol VARCHAR(12) NOT NULL,
    tick_time timestamp NOT NULL,
    created TIMESTAMP NOT NULL,
      open_price double precision NULL,
      high_price double precision NULL,
      low_price double precision NULL,
      close_price double precision NULL,
      volume BIGINT NULL,
      tr double precision NULL,
      tr_pct double precision NULL,
    UNIQUE(symbol, tick_time)
);
CREATE INDEX ON candle_1h (UPPER(symbol));
SELECT create_hypertable('candle_1h', 'tick_time');

CREATE TABLE candle_1m (
    id bigint NOT NULL,
    symbol VARCHAR(12) NOT NULL,
    tick_time timestamp NOT NULL,
    created TIMESTAMP NOT NULL,
      open_price double precision NULL,
      high_price double precision NULL,
      low_price double precision NULL,
      close_price double precision NULL,
      volume BIGINT NULL,
      tr double precision NULL,
      tr_pct double precision NULL,
    UNIQUE(symbol, tick_time)
);
CREATE INDEX ON candle_1m (UPPER(symbol));
SELECT create_hypertable('candle_1m', 'tick_time');

CREATE TABLE candle_3m (
    id bigint NOT NULL,
    symbol VARCHAR(12) NOT NULL,
    tick_time timestamp NOT NULL,
    created TIMESTAMP NOT NULL,
      open_price double precision NULL,
      high_price double precision NULL,
      low_price double precision NULL,
      close_price double precision NULL,
      volume BIGINT NULL,
      tr double precision NULL,
      tr_pct double precision NULL,
    UNIQUE(symbol, tick_time)
);
CREATE INDEX ON candle_3m (UPPER(symbol));
SELECT create_hypertable('candle_3m', 'tick_time');

CREATE TABLE candle_5m (
    id bigint NOT NULL,
    symbol VARCHAR(12) NOT NULL,
    tick_time timestamp NOT NULL,
    created TIMESTAMP NOT NULL,
      open_price double precision NULL,
      high_price double precision NULL,
      low_price double precision NULL,
      close_price double precision NULL,
      volume BIGINT NULL,
      tr double precision NULL,
      tr_pct double precision NULL,
    UNIQUE(symbol, tick_time)
);
CREATE INDEX ON candle_5m (UPPER(symbol));
SELECT create_hypertable('candle_5m', 'tick_time');

CREATE TABLE candle_15m (
    id bigint NOT NULL,
    symbol VARCHAR(12) NOT NULL,
    tick_time timestamp NOT NULL,
    created TIMESTAMP NOT NULL,
      open_price double precision NULL,
      high_price double precision NULL,
      low_price double precision NULL,
      close_price double precision NULL,
      volume BIGINT NULL,
      tr double precision NULL,
      tr_pct double precision NULL,
    UNIQUE(symbol, tick_time)
);
CREATE INDEX ON candle_15m (UPPER(symbol));
SELECT create_hypertable('candle_15m', 'tick_time');

CREATE TABLE candle_1h (
    id bigint NOT NULL,
    symbol VARCHAR(12) NOT NULL,
    tick_time timestamp NOT NULL,
    created TIMESTAMP NOT NULL,
      open_price double precision NULL,
      high_price double precision NULL,
      low_price double precision NULL,
      close_price double precision NULL,
      volume BIGINT NULL,
      tr double precision NULL,
      tr_pct double precision NULL,
    UNIQUE(symbol, tick_time)
);
CREATE INDEX ON candle_1h (UPPER(symbol));
SELECT create_hypertable('candle_1h', 'tick_time');

CREATE TABLE candle_1w (
    id bigint NOT NULL,
    symbol VARCHAR(12) NOT NULL,
    tick_time timestamp NOT NULL,
    created TIMESTAMP NOT NULL,
      open_price double precision NULL,
      high_price double precision NULL,
      low_price double precision NULL,
      close_price double precision NULL,
      volume BIGINT NULL,
      tr double precision NULL,
      tr_pct double precision NULL,
    UNIQUE(symbol, tick_time)
);
CREATE INDEX ON candle_1w (UPPER(symbol));
SELECT create_hypertable('candle_1w', 'tick_time');

CREATE TABLE candle_4w (
    id bigint NOT NULL,
    symbol VARCHAR(12) NOT NULL,
    tick_time timestamp NOT NULL,
    created TIMESTAMP NOT NULL,
      open_price double precision NULL,
      high_price double precision NULL,
      low_price double precision NULL,
      close_price double precision NULL,
      volume BIGINT NULL,
      tr double precision NULL,
      tr_pct double precision NULL,
    UNIQUE(symbol, tick_time)
);
CREATE INDEX ON candle_4w (UPPER(symbol));
SELECT create_hypertable('candle_4w', 'tick_time');

