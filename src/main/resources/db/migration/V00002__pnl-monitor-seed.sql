-- CREATE SEQUENCE hibernate_sequence START 1;

CREATE TABLE trades (
    id bigint NOT NULL,
    symbol VARCHAR(12) NOT NULL,
    trade_direction VARCHAR(5) NOT NULL,
    entry_time timestamp NOT NULL,
    exit_time timestamp NULL,
    qty_total integer NULL,
    price_avg_in double precision NULL,
    price_avg_out double precision NULL,
    fees_total double precision NULL,
    pnl_dollar double precision NULL,
    pnl_percent double precision NULL,
    exposure double precision NULL,
    "created" timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(id)
);

CREATE TABLE trade_executions (
    id bigint NOT NULL,
    symbol VARCHAR(12) NOT NULL,
    side VARCHAR(14) NOT NULL,
	exec_time timestamp NOT NULL,
    qty integer NULL,
    price double precision NULL,
    fees double precision NULL,
    trade_id bigint DEFAULT 0,
    "created" timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_trades1
      FOREIGN KEY(trade_id)
      REFERENCES trades(id),
	UNIQUE(id, exec_time)
);

SELECT create_hypertable('trade_executions', 'exec_time');
