-- Create schema for TPC-H
CREATE SCHEMA IF NOT EXISTS iceberg.tpch;

-- Create external table views over CSV files
CREATE TABLE IF NOT EXISTS hive.tpch_external.customer (
    c_custkey    integer,
    c_name       varchar,
    c_address    varchar,
    c_nationkey  integer,
    c_phone      varchar,
    c_acctbal    decimal(10,2),
    c_mktsegment varchar,
    c_comment    varchar
)
WITH (
    format = 'CSV',
    external_location = 's3://lakehouse/csv/customer.csv',
    skip_header_line_count = 0
);

CREATE TABLE IF NOT EXISTS hive.tpch_external.lineitem (
    l_orderkey      integer,
    l_partkey       integer,
    l_suppkey       integer,
    l_linenumber    integer,
    l_quantity      decimal(10,2),
    l_extendedprice decimal(15,2),
    l_discount      decimal(10,2),
    l_tax           decimal(10,2),
    l_returnflag    varchar,
    l_linestatus    varchar,
    l_shipdate      date,
    l_commitdate    date,
    l_receiptdate   date,
    l_shipinstruct  varchar,
    l_shipmode      varchar,
    l_comment       varchar
)
WITH (
    format = 'CSV',
    external_location = 's3://lakehouse/csv/lineitem.csv',
    skip_header_line_count = 0
);

CREATE TABLE IF NOT EXISTS hive.tpch_external.nation (
    n_nationkey integer,
    n_name      varchar,
    n_regionkey integer,
    n_comment   varchar
)
WITH (
    format = 'CSV',
    external_location = 's3://lakehouse/csv/nation.csv',
    skip_header_line_count = 0
);

CREATE TABLE IF NOT EXISTS hive.tpch_external.orders (
    o_orderkey      integer,
    o_custkey       integer,
    o_orderstatus   varchar,
    o_totalprice    decimal(15,2),
    o_orderdate     date,
    o_orderpriority varchar,
    o_clerk         varchar,
    o_shippriority  integer,
    o_comment       varchar
)
WITH (
    format = 'CSV',
    external_location = 's3://lakehouse/csv/orders.csv',
    skip_header_line_count = 0
);

CREATE TABLE IF NOT EXISTS hive.tpch_external.part (
    p_partkey     integer,
    p_name        varchar,
    p_mfgr        varchar,
    p_brand       varchar,
    p_type        varchar,
    p_size        integer,
    p_container   varchar,
    p_retailprice decimal(15,2),
    p_comment     varchar
)
WITH (
    format = 'CSV',
    external_location = 's3://lakehouse/csv/part.csv',
    skip_header_line_count = 0
);

CREATE TABLE IF NOT EXISTS hive.tpch_external.partsupp (
    ps_partkey    integer,
    ps_suppkey    integer,
    ps_availqty   integer,
    ps_supplycost decimal(15,2),
    ps_comment    varchar
)
WITH (
    format = 'CSV',
    external_location = 's3://lakehouse/csv/partsupp.csv',
    skip_header_line_count = 0
);

CREATE TABLE IF NOT EXISTS hive.tpch_external.region (
    r_regionkey integer,
    r_name      varchar,
    r_comment   varchar
)
WITH (
    format = 'CSV',
    external_location = 's3://lakehouse/csv/region.csv',
    skip_header_line_count = 0
);

CREATE TABLE IF NOT EXISTS hive.tpch_external.supplier (
    s_suppkey     integer,
    s_name        varchar,
    s_address     varchar,
    s_nationkey   integer,
    s_phone       varchar,
    s_acctbal     decimal(15,2),
    s_comment     varchar
)
WITH (
    format = 'CSV',
    external_location = 's3://lakehouse/csv/supplier.csv',
    skip_header_line_count = 0
);

-- Create Iceberg tables
CREATE TABLE IF NOT EXISTS iceberg.tpch.customer (
    c_custkey    integer NOT NULL,
    c_name       varchar NOT NULL,
    c_address    varchar,
    c_nationkey  integer,
    c_phone      varchar,
    c_acctbal    decimal(10,2),
    c_mktsegment varchar,
    c_comment    varchar
)
WITH (
    format = 'ICEBERG',
    location = 's3://iceberg/tpch/customer/',
    partitioning = ARRAY['c_nationkey']
);

CREATE TABLE IF NOT EXISTS iceberg.tpch.lineitem (
    l_orderkey      integer NOT NULL,
    l_partkey       integer,
    l_suppkey       integer,
    l_linenumber    integer NOT NULL,
    l_quantity      decimal(10,2),
    l_extendedprice decimal(15,2),
    l_discount      decimal(10,2),
    l_tax           decimal(10,2),
    l_returnflag    varchar,
    l_linestatus    varchar,
    l_shipdate      date,
    l_commitdate    date,
    l_receiptdate   date,
    l_shipinstruct  varchar,
    l_shipmode      varchar,
    l_comment       varchar
)
WITH (
    format = 'ICEBERG',
    location = 's3://iceberg/tpch/lineitem/',
    partitioning = ARRAY['l_shipdate']
);

CREATE TABLE IF NOT EXISTS iceberg.tpch.nation (
    n_nationkey integer NOT NULL,
    n_name      varchar NOT NULL,
    n_regionkey integer,
    n_comment   varchar
)
WITH (
    format = 'ICEBERG',
    location = 's3://iceberg/tpch/nation/'
);

CREATE TABLE IF NOT EXISTS iceberg.tpch.orders (
    o_orderkey      integer NOT NULL,
    o_custkey       integer,
    o_orderstatus   varchar,
    o_totalprice    decimal(15,2),
    o_orderdate     date,
    o_orderpriority varchar,
    o_clerk         varchar,
    o_shippriority  integer,
    o_comment       varchar
)
WITH (
    format = 'ICEBERG',
    location = 's3://iceberg/tpch/orders/',
    partitioning = ARRAY['o_orderdate']
);

CREATE TABLE IF NOT EXISTS iceberg.tpch.part (
    p_partkey     integer NOT NULL,
    p_name        varchar NOT NULL,
    p_mfgr        varchar,
    p_brand       varchar,
    p_type        varchar,
    p_size        integer,
    p_container   varchar,
    p_retailprice decimal(15,2),
    p_comment     varchar
)
WITH (
    format = 'ICEBERG',
    location = 's3://iceberg/tpch/part/'
);

CREATE TABLE IF NOT EXISTS iceberg.tpch.partsupp (
    ps_partkey    integer NOT NULL,
    ps_suppkey    integer NOT NULL,
    ps_availqty   integer,
    ps_supplycost decimal(15,2),
    ps_comment    varchar
)
WITH (
    format = 'ICEBERG',
    location = 's3://iceberg/tpch/partsupp/'
);

CREATE TABLE IF NOT EXISTS iceberg.tpch.region (
    r_regionkey integer NOT NULL,
    r_name      varchar NOT NULL,
    r_comment   varchar
)
WITH (
    format = 'ICEBERG',
    location = 's3://iceberg/tpch/region/'
);

CREATE TABLE IF NOT EXISTS iceberg.tpch.supplier (
    s_suppkey     integer NOT NULL,
    s_name        varchar NOT NULL,
    s_address     varchar,
    s_nationkey   integer,
    s_phone       varchar,
    s_acctbal     decimal(15,2),
    s_comment     varchar
)
WITH (
    format = 'ICEBERG',
    location = 's3://iceberg/tpch/supplier/'
);

-- Ingest data from external tables to Iceberg
INSERT INTO iceberg.tpch.customer SELECT * FROM hive.tpch_external.customer;
INSERT INTO iceberg.tpch.lineitem SELECT * FROM hive.tpch_external.lineitem;
INSERT INTO iceberg.tpch.nation SELECT * FROM hive.tpch_external.nation;
INSERT INTO iceberg.tpch.orders SELECT * FROM hive.tpch_external.orders;
INSERT INTO iceberg.tpch.part SELECT * FROM hive.tpch_external.part;
INSERT INTO iceberg.tpch.partsupp SELECT * FROM hive.tpch_external.partsupp;
INSERT INTO iceberg.tpch.region SELECT * FROM hive.tpch_external.region;
INSERT INTO iceberg.tpch.supplier SELECT * FROM hive.tpch_external.supplier;

-- Verify data ingestion
SELECT 'customer' as table_name, COUNT(*) as row_count FROM iceberg.tpch.customer
UNION ALL
SELECT 'lineitem', COUNT(*) FROM iceberg.tpch.lineitem
UNION ALL
SELECT 'nation', COUNT(*) FROM iceberg.tpch.nation
UNION ALL
SELECT 'orders', COUNT(*) FROM iceberg.tpch.orders
UNION ALL
SELECT 'part', COUNT(*) FROM iceberg.tpch.part
UNION ALL
SELECT 'partsupp', COUNT(*) FROM iceberg.tpch.partsupp
UNION ALL
SELECT 'region', COUNT(*) FROM iceberg.tpch.region
UNION ALL
SELECT 'supplier', COUNT(*) FROM iceberg.tpch.supplier
ORDER BY table_name;
