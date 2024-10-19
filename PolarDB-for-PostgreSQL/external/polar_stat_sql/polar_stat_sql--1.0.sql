-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION polar_stat_sql" to load this file. \quit

SET client_encoding = 'UTF8';

CREATE FUNCTION polar_stat_sql(
    OUT queryid bigint,
    OUT userid      oid,
    OUT dbid        oid,
    OUT reads       bigint,             /* total reads, in bytes */
    OUT writes      bigint,             /* total writes, in bytes */
    OUT user_time   double precision,   /* total user CPU time used */
    OUT system_time double precision,   /* total system CPU time used */
    OUT minflts     bigint,             /* total page reclaims (soft page faults) */
    OUT majflts     bigint,             /* total page faults (hard page faults) */
    OUT nswaps      bigint,             /* total swaps */
    OUT msgsnds     bigint,             /* total IPC messages sent */
    OUT msgrcvs     bigint,             /* total IPC messages received */
    OUT nsignals    bigint,             /* total signals received */
    OUT nvcsws      bigint,             /* total voluntary context switches */
    OUT nivcsws     bigint,             /* total involuntary context switches */
    OUT scan_rows   double precision,   /* total rows for scan nodes */
    OUT scan_time   double precision,   /* total time for scan nodes */
    OUT scan_count  bigint,             /* total count for scan nodes */
    OUT join_rows   double precision,   /* total rows for join nodes */
    OUT join_time   double precision,   /* total time for join nodes */
    OUT join_count  bigint,             /* total count for join nodes */
    OUT sort_rows   double precision,   /* total rows for sort nodes */
    OUT sort_time   double precision,   /* total time for sert nodes */
    OUT sort_count  bigint,             /* total count for sort nodes */
    OUT group_rows  double precision,   /* total rows for group nodes */
    OUT group_time  double precision,   /* total time for group nodes */
    OUT group_count bigint,             /* total count for group nodes */
    OUT hash_rows   double precision,   /* total rows for hash nodes */
    OUT hash_memory bigint,             /* total memory for hash nodes */
    OUT hash_count  bigint              /* total count for hash nodes */
)
RETURNS SETOF record
LANGUAGE c COST 1000
AS '$libdir/polar_stat_sql', 'polar_stat_sql_1_0';
GRANT ALL ON FUNCTION polar_stat_sql() TO public;

CREATE FUNCTION polar_stat_sql_reset()
    RETURNS void
    LANGUAGE c COST 1000
    AS '$libdir/polar_stat_sql', 'polar_stat_sql_reset';
REVOKE ALL ON FUNCTION polar_stat_sql_reset() FROM public;

CREATE VIEW polar_stat_sql AS
SELECT s.query, d.datname, r.rolname,
       k.user_time,
       k.system_time,
       k.minflts,
       k.majflts,
       k.nswaps,
       k.reads AS reads,
       k.reads/(current_setting('block_size')::integer) AS reads_blks,
       k.writes AS writes,
       k.writes/(current_setting('block_size')::integer) AS writes_blks,
       k.msgsnds,
       k.msgrcvs,
       k.nsignals,
       k.nvcsws,
       k.nivcsws,
       k.scan_rows,
       k.scan_time,
       k.scan_count,
       k.join_rows,
       k.join_time,
       k.join_count,
       k.sort_rows,
       k.sort_time,
       k.sort_count,
       k.group_rows,
       k.group_time,
       k.group_count,
       k.hash_rows,
       k.hash_memory,
       k.hash_count
  FROM polar_stat_sql() k
  JOIN pg_stat_statements s
    ON k.queryid = s.queryid AND k.dbid = s.dbid AND k.userid = s.userid
  JOIN pg_database d
    ON  d.oid = s.dbid
  JOIN pg_roles r
    ON r.oid = s.userid;
GRANT SELECT ON polar_stat_sql TO public;

CREATE FUNCTION polar_stat_query_count(
    OUT sqltype text,
    OUT cmdtype text,
    OUT count int8
)
RETURNS SETOF record
AS 'MODULE_PATHNAME', 'polar_stat_query_count'
LANGUAGE C STRICT VOLATILE PARALLEL SAFE;
CREATE VIEW polar_stat_query_count AS
  SELECT * FROM polar_stat_query_count();
GRANT SELECT ON polar_stat_query_count TO PUBLIC;