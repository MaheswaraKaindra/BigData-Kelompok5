-- Create schema for TPC-H
CREATE SCHEMA IF NOT EXISTS iceberg.tpch;

-- Create schema for external CSV views in Hive catalog
CREATE SCHEMA IF NOT EXISTS hive.tpch_external;

-- Create external table views over CSV files
CREATE TABLE IF NOT EXISTS hive.tpch_external.customer (
    c_custkey    varchar,
    c_name       varchar,
    c_address    varchar,
    c_nationkey  varchar,
    c_phone      varchar,
    c_acctbal    varchar,
    c_mktsegment varchar,
    c_comment    varchar
)
WITH (
    format = 'CSV',
    external_location = 's3://lakehouse/csv/customer/',
    skip_header_line_count = 0
);

CREATE TABLE IF NOT EXISTS hive.tpch_external.lineitem (
    l_orderkey      varchar,
    l_partkey       varchar,
    l_suppkey       varchar,
    l_linenumber    varchar,
    l_quantity      varchar,
    l_extendedprice varchar,
    l_discount      varchar,
    l_tax           varchar,
    l_returnflag    varchar,
    l_linestatus    varchar,
    l_shipdate      varchar,
    l_commitdate    varchar,
    l_receiptdate   varchar,
    l_shipinstruct  varchar,
    l_shipmode      varchar,
    l_comment       varchar
)
WITH (
    format = 'CSV',
    external_location = 's3://lakehouse/csv/lineitem/',
    skip_header_line_count = 0
);

CREATE TABLE IF NOT EXISTS hive.tpch_external.nation (
    n_nationkey varchar,
    n_name      varchar,
    n_regionkey varchar,
    n_comment   varchar
)
WITH (
    format = 'CSV',
    external_location = 's3://lakehouse/csv/nation/',
    skip_header_line_count = 0
);

CREATE TABLE IF NOT EXISTS hive.tpch_external.orders (
    o_orderkey      varchar,
    o_custkey       varchar,
    o_orderstatus   varchar,
    o_totalprice    varchar,
    o_orderdate     varchar,
    o_orderpriority varchar,
    o_clerk         varchar,
    o_shippriority  varchar,
    o_comment       varchar
)
WITH (
    format = 'CSV',
    external_location = 's3://lakehouse/csv/orders/',
    skip_header_line_count = 0
);

CREATE TABLE IF NOT EXISTS hive.tpch_external.part (
    p_partkey     varchar,
    p_name        varchar,
    p_mfgr        varchar,
    p_brand       varchar,
    p_type        varchar,
    p_size        varchar,
    p_container   varchar,
    p_retailprice varchar,
    p_comment     varchar
)
WITH (
    format = 'CSV',
    external_location = 's3://lakehouse/csv/part/',
    skip_header_line_count = 0
);

CREATE TABLE IF NOT EXISTS hive.tpch_external.partsupp (
    ps_partkey    varchar,
    ps_suppkey    varchar,
    ps_availqty   varchar,
    ps_supplycost varchar,
    ps_comment    varchar
)
WITH (
    format = 'CSV',
    external_location = 's3://lakehouse/csv/partsupp/',
    skip_header_line_count = 0
);

CREATE TABLE IF NOT EXISTS hive.tpch_external.region (
    r_regionkey varchar,
    r_name      varchar,
    r_comment   varchar
)
WITH (
    format = 'CSV',
    external_location = 's3://lakehouse/csv/region/',
    skip_header_line_count = 0
);

CREATE TABLE IF NOT EXISTS hive.tpch_external.supplier (
    s_suppkey     varchar,
    s_name        varchar,
    s_address     varchar,
    s_nationkey   varchar,
    s_phone       varchar,
    s_acctbal     varchar,
    s_comment     varchar
)
WITH (
    format = 'CSV',
    external_location = 's3://lakehouse/csv/supplier/',
    skip_header_line_count = 0
);

-- Drop existing Iceberg tables to reset metadata catalog
DROP TABLE IF EXISTS iceberg.tpch.customer;
DROP TABLE IF EXISTS iceberg.tpch.lineitem;
DROP TABLE IF EXISTS iceberg.tpch.nation;
DROP TABLE IF EXISTS iceberg.tpch.orders;
DROP TABLE IF EXISTS iceberg.tpch.part;
DROP TABLE IF EXISTS iceberg.tpch.partsupp;
DROP TABLE IF EXISTS iceberg.tpch.region;
DROP TABLE IF EXISTS iceberg.tpch.supplier;

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
    location = 's3://iceberg/tpch/lineitem/',
    partitioning = ARRAY['month(l_shipdate)']
);

CREATE TABLE IF NOT EXISTS iceberg.tpch.nation (
    n_nationkey integer NOT NULL,
    n_name      varchar NOT NULL,
    n_regionkey integer,
    n_comment   varchar
)
WITH (
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
    location = 's3://iceberg/tpch/orders/',
    partitioning = ARRAY['month(o_orderdate)']
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
    location = 's3://iceberg/tpch/partsupp/'
);

CREATE TABLE IF NOT EXISTS iceberg.tpch.region (
    r_regionkey integer NOT NULL,
    r_name      varchar NOT NULL,
    r_comment   varchar
)
WITH (
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
    location = 's3://iceberg/tpch/supplier/'
);

-- Ingest data from external tables to Iceberg
INSERT INTO iceberg.tpch.customer
SELECT
    CAST(c_custkey AS integer),
    c_name,
    c_address,
    CAST(c_nationkey AS integer),
    c_phone,
    CAST(c_acctbal AS decimal(10,2)),
    c_mktsegment,
    c_comment
FROM hive.tpch_external.customer;

INSERT INTO iceberg.tpch.lineitem
SELECT
        CAST(l_orderkey AS integer),
        CAST(l_partkey AS integer),
        CAST(l_suppkey AS integer),
        CAST(l_linenumber AS integer),
        CAST(l_quantity AS decimal(10,2)),
        CAST(l_extendedprice AS decimal(15,2)),
        CAST(l_discount AS decimal(10,2)),
        CAST(l_tax AS decimal(10,2)),
        l_returnflag,
        l_linestatus,
        CAST(l_shipdate AS date),
        CAST(l_commitdate AS date),
        CAST(l_receiptdate AS date),
        l_shipinstruct,
        l_shipmode,
        l_comment
FROM hive.tpch_external.lineitem
WHERE CAST(l_shipdate AS date) >= DATE '1992-01-01'
    AND CAST(l_shipdate AS date) <  DATE '1993-01-01';

INSERT INTO iceberg.tpch.lineitem
SELECT
        CAST(l_orderkey AS integer),
        CAST(l_partkey AS integer),
        CAST(l_suppkey AS integer),
        CAST(l_linenumber AS integer),
        CAST(l_quantity AS decimal(10,2)),
        CAST(l_extendedprice AS decimal(15,2)),
        CAST(l_discount AS decimal(10,2)),
        CAST(l_tax AS decimal(10,2)),
        l_returnflag,
        l_linestatus,
        CAST(l_shipdate AS date),
        CAST(l_commitdate AS date),
        CAST(l_receiptdate AS date),
        l_shipinstruct,
        l_shipmode,
        l_comment
FROM hive.tpch_external.lineitem
WHERE CAST(l_shipdate AS date) >= DATE '1993-01-01'
    AND CAST(l_shipdate AS date) <  DATE '1994-01-01';

INSERT INTO iceberg.tpch.lineitem
SELECT
        CAST(l_orderkey AS integer),
        CAST(l_partkey AS integer),
        CAST(l_suppkey AS integer),
        CAST(l_linenumber AS integer),
        CAST(l_quantity AS decimal(10,2)),
        CAST(l_extendedprice AS decimal(15,2)),
        CAST(l_discount AS decimal(10,2)),
        CAST(l_tax AS decimal(10,2)),
        l_returnflag,
        l_linestatus,
        CAST(l_shipdate AS date),
        CAST(l_commitdate AS date),
        CAST(l_receiptdate AS date),
        l_shipinstruct,
        l_shipmode,
        l_comment
FROM hive.tpch_external.lineitem
WHERE CAST(l_shipdate AS date) >= DATE '1994-01-01'
    AND CAST(l_shipdate AS date) <  DATE '1995-01-01';

INSERT INTO iceberg.tpch.lineitem
SELECT
        CAST(l_orderkey AS integer),
        CAST(l_partkey AS integer),
        CAST(l_suppkey AS integer),
        CAST(l_linenumber AS integer),
        CAST(l_quantity AS decimal(10,2)),
        CAST(l_extendedprice AS decimal(15,2)),
        CAST(l_discount AS decimal(10,2)),
        CAST(l_tax AS decimal(10,2)),
        l_returnflag,
        l_linestatus,
        CAST(l_shipdate AS date),
        CAST(l_commitdate AS date),
        CAST(l_receiptdate AS date),
        l_shipinstruct,
        l_shipmode,
        l_comment
FROM hive.tpch_external.lineitem
WHERE CAST(l_shipdate AS date) >= DATE '1995-01-01'
    AND CAST(l_shipdate AS date) <  DATE '1996-01-01';

INSERT INTO iceberg.tpch.lineitem
SELECT
        CAST(l_orderkey AS integer),
        CAST(l_partkey AS integer),
        CAST(l_suppkey AS integer),
        CAST(l_linenumber AS integer),
        CAST(l_quantity AS decimal(10,2)),
        CAST(l_extendedprice AS decimal(15,2)),
        CAST(l_discount AS decimal(10,2)),
        CAST(l_tax AS decimal(10,2)),
        l_returnflag,
        l_linestatus,
        CAST(l_shipdate AS date),
        CAST(l_commitdate AS date),
        CAST(l_receiptdate AS date),
        l_shipinstruct,
        l_shipmode,
        l_comment
FROM hive.tpch_external.lineitem
WHERE CAST(l_shipdate AS date) >= DATE '1996-01-01'
    AND CAST(l_shipdate AS date) <  DATE '1997-01-01';

INSERT INTO iceberg.tpch.lineitem
SELECT
        CAST(l_orderkey AS integer),
        CAST(l_partkey AS integer),
        CAST(l_suppkey AS integer),
        CAST(l_linenumber AS integer),
        CAST(l_quantity AS decimal(10,2)),
        CAST(l_extendedprice AS decimal(15,2)),
        CAST(l_discount AS decimal(10,2)),
        CAST(l_tax AS decimal(10,2)),
        l_returnflag,
        l_linestatus,
        CAST(l_shipdate AS date),
        CAST(l_commitdate AS date),
        CAST(l_receiptdate AS date),
        l_shipinstruct,
        l_shipmode,
        l_comment
FROM hive.tpch_external.lineitem
WHERE CAST(l_shipdate AS date) >= DATE '1997-01-01'
    AND CAST(l_shipdate AS date) <  DATE '1998-01-01';

INSERT INTO iceberg.tpch.lineitem
SELECT
        CAST(l_orderkey AS integer),
        CAST(l_partkey AS integer),
        CAST(l_suppkey AS integer),
        CAST(l_linenumber AS integer),
        CAST(l_quantity AS decimal(10,2)),
        CAST(l_extendedprice AS decimal(15,2)),
        CAST(l_discount AS decimal(10,2)),
        CAST(l_tax AS decimal(10,2)),
        l_returnflag,
        l_linestatus,
        CAST(l_shipdate AS date),
        CAST(l_commitdate AS date),
        CAST(l_receiptdate AS date),
        l_shipinstruct,
        l_shipmode,
        l_comment
FROM hive.tpch_external.lineitem
WHERE CAST(l_shipdate AS date) >= DATE '1998-01-01'
    AND CAST(l_shipdate AS date) <  DATE '1999-01-01';

INSERT INTO iceberg.tpch.nation
SELECT
    CAST(n_nationkey AS integer),
    n_name,
    CAST(n_regionkey AS integer),
    n_comment
FROM hive.tpch_external.nation;

INSERT INTO iceberg.tpch.orders
SELECT
        CAST(o_orderkey AS integer),
        CAST(o_custkey AS integer),
        o_orderstatus,
        CAST(o_totalprice AS decimal(15,2)),
        CAST(o_orderdate AS date),
        o_orderpriority,
        o_clerk,
        CAST(o_shippriority AS integer),
        o_comment
FROM hive.tpch_external.orders
WHERE CAST(o_orderdate AS date) >= DATE '1992-01-01'
    AND CAST(o_orderdate AS date) <  DATE '1993-01-01';

INSERT INTO iceberg.tpch.orders
SELECT
        CAST(o_orderkey AS integer),
        CAST(o_custkey AS integer),
        o_orderstatus,
        CAST(o_totalprice AS decimal(15,2)),
        CAST(o_orderdate AS date),
        o_orderpriority,
        o_clerk,
        CAST(o_shippriority AS integer),
        o_comment
FROM hive.tpch_external.orders
WHERE CAST(o_orderdate AS date) >= DATE '1993-01-01'
    AND CAST(o_orderdate AS date) <  DATE '1994-01-01';

INSERT INTO iceberg.tpch.orders
SELECT
        CAST(o_orderkey AS integer),
        CAST(o_custkey AS integer),
        o_orderstatus,
        CAST(o_totalprice AS decimal(15,2)),
        CAST(o_orderdate AS date),
        o_orderpriority,
        o_clerk,
        CAST(o_shippriority AS integer),
        o_comment
FROM hive.tpch_external.orders
WHERE CAST(o_orderdate AS date) >= DATE '1994-01-01'
    AND CAST(o_orderdate AS date) <  DATE '1995-01-01';

INSERT INTO iceberg.tpch.orders
SELECT
        CAST(o_orderkey AS integer),
        CAST(o_custkey AS integer),
        o_orderstatus,
        CAST(o_totalprice AS decimal(15,2)),
        CAST(o_orderdate AS date),
        o_orderpriority,
        o_clerk,
        CAST(o_shippriority AS integer),
        o_comment
FROM hive.tpch_external.orders
WHERE CAST(o_orderdate AS date) >= DATE '1995-01-01'
    AND CAST(o_orderdate AS date) <  DATE '1996-01-01';

INSERT INTO iceberg.tpch.orders
SELECT
        CAST(o_orderkey AS integer),
        CAST(o_custkey AS integer),
        o_orderstatus,
        CAST(o_totalprice AS decimal(15,2)),
        CAST(o_orderdate AS date),
        o_orderpriority,
        o_clerk,
        CAST(o_shippriority AS integer),
        o_comment
FROM hive.tpch_external.orders
WHERE CAST(o_orderdate AS date) >= DATE '1996-01-01'
    AND CAST(o_orderdate AS date) <  DATE '1997-01-01';

INSERT INTO iceberg.tpch.orders
SELECT
        CAST(o_orderkey AS integer),
        CAST(o_custkey AS integer),
        o_orderstatus,
        CAST(o_totalprice AS decimal(15,2)),
        CAST(o_orderdate AS date),
        o_orderpriority,
        o_clerk,
        CAST(o_shippriority AS integer),
        o_comment
FROM hive.tpch_external.orders
WHERE CAST(o_orderdate AS date) >= DATE '1997-01-01'
    AND CAST(o_orderdate AS date) <  DATE '1998-01-01';

INSERT INTO iceberg.tpch.orders
SELECT
        CAST(o_orderkey AS integer),
        CAST(o_custkey AS integer),
        o_orderstatus,
        CAST(o_totalprice AS decimal(15,2)),
        CAST(o_orderdate AS date),
        o_orderpriority,
        o_clerk,
        CAST(o_shippriority AS integer),
        o_comment
FROM hive.tpch_external.orders
WHERE CAST(o_orderdate AS date) >= DATE '1998-01-01'
    AND CAST(o_orderdate AS date) <  DATE '1999-01-01';

INSERT INTO iceberg.tpch.part
SELECT
    CAST(p_partkey AS integer),
    p_name,
    p_mfgr,
    p_brand,
    p_type,
    CAST(p_size AS integer),
    p_container,
    CAST(p_retailprice AS decimal(15,2)),
    p_comment
FROM hive.tpch_external.part;

INSERT INTO iceberg.tpch.partsupp
SELECT
    CAST(ps_partkey AS integer),
    CAST(ps_suppkey AS integer),
    CAST(ps_availqty AS integer),
    CAST(ps_supplycost AS decimal(15,2)),
    ps_comment
FROM hive.tpch_external.partsupp;

INSERT INTO iceberg.tpch.region
SELECT
    CAST(r_regionkey AS integer),
    r_name,
    r_comment
FROM hive.tpch_external.region;

INSERT INTO iceberg.tpch.supplier
SELECT
    CAST(s_suppkey AS integer),
    s_name,
    s_address,
    CAST(s_nationkey AS integer),
    s_phone,
    CAST(s_acctbal AS decimal(15,2)),
    s_comment
FROM hive.tpch_external.supplier;

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
