-- configuration
/*--POLAR_ENABLE_PX*/
set polar_enable_px = on;
-- make sure 'polar_px_enable_check_workers' is disabled
alter system set polar_px_enable_check_workers = off;
select pg_reload_conf();
select pg_sleep(1);




-- 
-- range partition
-- 
set client_min_messages to 'warning';
drop table if exists t1_range;
reset client_min_messages;
create table t1_range(id int, val int) partition by range(id);
    create table t1_range_p1 partition OF t1_range FOR values from (1) to (10);
    create table t1_range_p2 partition OF t1_range FOR values from (10) to (100);
    create table t1_range_p3 partition OF t1_range DEFAULT partition by range(id);
        create table t1_range_p3_p1 partition OF t1_range_p3 FOR values from (100) to (200);
        create table t1_range_p3_p2 partition OF t1_range_p3 DEFAULT;

insert into t1_range select generate_series(1, 500, 2);

-- test alter table on a heap table
-- 
alter table t1_range_p3_p1 set (px_workers = 1);
-- only 'px_workers' of t1_range_p3_p1 should be 1
select   relname, reloptions
from     pg_class
where    relname like 't1_range%'
order by relname;

-- test alter table on a partitioned table
-- 
alter table t1_range_p3 set (px_workers = 2);
-- 'px_workers' of t1_range_p3* should all be 2
select   relname, reloptions
from     pg_class
where    relname like 't1_range%'
order by relname;

-- test alter table on a multi-level partitioned table
-- 
alter table t1_range set (px_workers = 3);
-- 'px_workers' should ALL be 3
select   relname, reloptions
from     pg_class
where    relname like 't1_range%'
order by relname;

-- test GUC controls setting reloptions recursively
-- 
set polar_partition_recursive_reloptions = '';
alter table t1_range set (px_workers = 2);
-- only 'px_workers' of t1_range should be 2
select   relname, reloptions
from     pg_class
where    relname like 't1_range%'
order by relname;
reset polar_partition_recursive_reloptions;

-- test whether a query can use PX
-- 
alter table t1_range_p3_p1 set (px_workers = -1);

-- SHOULD NOT use PX because 'px_workers' set to -1
explain (costs off) select * from t1_range_p3_p1;
-- SHOULD use PX because 'px_workers' remains 3
explain (costs off) select * from t1_range_p3_p2;
-- SHOULD NOT use PX because 'px_workers' of one child partition set to -1
explain (costs off) select * from t1_range_p3;
-- SHOULD use PX because it has no child partitions
explain (costs off) select * from t1_range_p2;
-- should NOT use PX because 'px_workers' of one descendant partition set to -1
explain (costs off) select * from t1_range;

-- check the effectiveness of 'polar_px_enable_check_workers'
--
-- SHOULD use PX because 'polar_px_enable_check_workers' is disabled
-- although 'px_workers' of one descendant partition is not set
alter table t1_range_p3_p1 set (px_workers = 0);
explain (costs off) select * from t1_range_p3;
-- 
alter system set polar_px_enable_check_workers = on;
select pg_reload_conf();
select pg_sleep(1);
-- SHOULD NOT use PX bacause 'px_workers' of one descendant partition set to 0
-- while 'polar_px_enable_check_workers' is enabledx
explain (costs off) select * from t1_range_p3;
-- SHOULD use PX bacause 'px_workers' of all descendant partitions > 0
alter table t1_range_p3_p1 set (px_workers = 1);
explain (costs off) select * from t1_range_p3;
-- 
alter system set polar_px_enable_check_workers = off;
select pg_reload_conf();
select pg_sleep(1);




-- 
-- hash partition
-- 
set client_min_messages to 'warning';
drop table if exists t2_hash;
reset client_min_messages;
create table t2_hash(id int, val int) partition by hash(id);
    create table t2_hash_p1 partition of t2_hash for values with (modulus 3, remainder 0);
    create table t2_hash_p2 partition of t2_hash for values with (modulus 3, remainder 1);
    create table t2_hash_p3 partition of t2_hash for values with (modulus 3, remainder 2) partition by hash(val);
        create table t2_hash_p3_p1 partition of t2_hash_p3 for values with (modulus 4, remainder 0);
        create table t2_hash_p3_p2 partition of t2_hash_p3 for values with (modulus 4, remainder 1);
        create table t2_hash_p3_p3 partition of t2_hash_p3 for values with (modulus 4, remainder 2);
        create table t2_hash_p3_p4 partition of t2_hash_p3 for values with (modulus 4, remainder 3);

insert into t2_hash select generate_series(1,1000), generate_series(1,1000);

-- test alter table on a heap table
-- 
alter table t2_hash_p3_p4 set (px_workers = 1);
-- only 'px_workers' of t2_hash_p3_p4 should be 1
select   relname, reloptions
from     pg_class
where    relname like 't2_hash%'
order by relname;

-- test alter table on a partitioned table
-- 
alter table t2_hash_p3 set (px_workers = 2);
-- 'px_workers' of t2_hash_p3* should all be 2
select   relname, reloptions
from     pg_class
where    relname like 't2_hash%'
order by relname;

-- test alter table on a multi-level partitioned table
-- 
alter table t2_hash set (px_workers = 3);
-- 'px_workers' should ALL be 3
select   relname, reloptions
from     pg_class
where    relname like 't2_hash%'
order by relname;

-- test GUC controls setting reloptions recursively
-- 
set polar_partition_recursive_reloptions = '';
alter table t2_hash set (px_workers = 2);
-- only 'px_workers' of t2_hash should be 2
select   relname, reloptions
from     pg_class
where    relname like 't2_hash%'
order by relname;
reset polar_partition_recursive_reloptions;

-- test whether a query can use PX
-- 
alter table t2_hash_p3_p2 set (px_workers = -1);

-- SHOULD NOT use PX because 'px_workers' set to -1
explain (costs off) select * from t2_hash_p3_p2;
-- SHOULD use PX because 'px_workers' remains 3
explain (costs off) select * from t2_hash_p3_p1;
-- SHOULD NOT use PX because 'px_workers' of one child partition set to -1
explain (costs off) select * from t2_hash_p3;
-- SHOULD use PX because it has no child partitions
explain (costs off) select * from t2_hash_p2;
-- SHOULD NOT use PX because 'px_workers' of one descendant partition set to -1
explain (costs off) select * from t2_hash;

-- check the effectiveness of 'polar_px_enable_check_workers'
-- 
-- SHOULD use PX because 'polar_px_enable_check_workers' is disabled
-- although 'px_workers' of one descendant partition is not set
alter table t2_hash_p3_p2 set (px_workers = 0);
explain (costs off) select * from t2_hash_p3;
-- 
alter system set polar_px_enable_check_workers = on;
select pg_reload_conf();
select pg_sleep(1);
-- SHOULD NOT use PX bacause 'px_workers' of one descendant partition set to 0
-- while 'polar_px_enable_check_workers' is enabled
explain (costs off) select * from t2_hash_p3;
-- SHOULD use PX bacause 'px_workers' of all descendant partitions > 0
alter table t2_hash_p3_p2 set (px_workers = 1);
explain (costs off) select * from t2_hash_p3;
-- 
alter system set polar_px_enable_check_workers = off;
select pg_reload_conf();
select pg_sleep(1);




-- 
-- list partition
-- 
set client_min_messages to 'warning';
drop table if exists t3_list;
reset client_min_messages;
create table t3_list(id int, val int) partition by list(id);
    create table t3_list_p1 partition of t3_list for values in (1, 2, 3, 4, 5, 6, 7, 8, 9);
    create table t3_list_p2 partition of t3_list for values in (11, 12, 13, 14, 15, 16, 17, 18, 19);
    create table t3_list_p3 partition of t3_list default partition by list(id);
        create table t3_list_p3_p1 partition of t3_list_p3 for values in (21, 22, 23, 24);
        create table t3_list_p3_p2 partition of t3_list_p3 for values in (25, 26, 27, 28);
        create table t3_list_p3_p3 partition of t3_list_p3 for values in (29, 30, 31, 32);
        create table t3_list_p3_p4 partition of t3_list_p3 default;

insert into t3_list select generate_series(1,1000), generate_series(1,1000);

-- test alter table on a heap table
-- 
alter table t3_list_p3_p3 set (px_workers = 1);
-- only 'px_workers' of t3_list_p3_p3 should be 1
select   relname, reloptions
from     pg_class
where    relname like 't3_list%'
order by relname;

-- test alter table on a partitioned table
-- 
alter table t3_list_p3 set (px_workers = 2);
-- 'px_workers' of t3_list_p3* should all be 2
select   relname, reloptions
from     pg_class
where    relname like 't3_list%'
order by relname;

-- test alter table on a multi-level partitioned table
-- 
alter table t3_list set (px_workers = 3);
-- 'px_workers' should ALL be 3
select   relname, reloptions
from     pg_class
where    relname like 't3_list%'
order by relname;

-- test GUC controls setting reloptions recursively
-- 
set polar_partition_recursive_reloptions = '';
alter table t3_list set (px_workers = 2);
-- only 'px_workers' of t3_list should be 2
select   relname, reloptions
from     pg_class
where    relname like 't3_list%'
order by relname;
reset polar_partition_recursive_reloptions;

-- test whether a query can use PX
-- 
alter table t3_list_p3_p4 set (px_workers = -1);

-- SHOULD NOT use PX because 'px_workers' set to -1
explain (costs off) select * from t3_list_p3_p4;
-- SHOULD use PX because 'px_workers' remains 3
explain (costs off) select * from t3_list_p3_p3;
-- SHOULD NOT use PX because 'px_workers' of one child partition set to -1
explain (costs off) select * from t3_list_p3;
-- SHOULD use PX because it has no child partitions
explain (costs off) select * from t3_list_p2;
-- SHOULD NOT use PX because 'px_workers' of one descendant partition set to -1
explain (costs off) select * from t3_list;

-- check the effectiveness of 'polar_px_enable_check_workers'
-- 
-- SHOULD use PX because 'polar_px_enable_check_workers' is disabled
-- although 'px_workers' of one descendant partition is not set
alter table t3_list_p3_p4 set (px_workers = 0);
explain (costs off) select * from t3_list_p3;
-- 
alter system set polar_px_enable_check_workers = on;
select pg_reload_conf();
select pg_sleep(1);
-- SHOULD NOT use PX bacause 'px_workers' of one descendant partition set to 0
-- while 'polar_px_enable_check_workers' is enabled
explain (costs off) select * from t3_list_p3;
-- SHOULD use PX bacause 'px_workers' of all descendant partitions > 0
alter table t3_list_p3_p4 set (px_workers = 1);
explain (costs off) select * from t3_list_p3;
-- 
alter system set polar_px_enable_check_workers = off;
select pg_reload_conf();
select pg_sleep(1);
