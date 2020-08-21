# 环境信息
|IP|port|role|info|
|-|-|-|-|
|192.168.188.51|4000|node1|master|
|192.168.188.52|4000|node2|slave1|
|192.168.188.53|4000|node3|slave2|

- CentOS Linux release 7.8.2003 (Core)
- mysql-5.7.30-linux-glibc2.12-x86_64


# 软件位置
在三个节点上部署好MySQL

# 搭建复制环境，并开启增强半同步
- 所有节点配置
``` shell
mysql> set global super_read_only=0;
Query OK, 0 rows affected (0.00 sec)

mysql> create user 'rep'@'192.168.188.%' identified by 'rep';
Query OK, 0 rows affected (0.03 sec)

mysql> grant replication slave on *.* to 'rep'@'192.168.188.%';
Query OK, 0 rows affected (0.12 sec)

mysql> install plugin rpl_semi_sync_slave soname 'semisync_slave.so';
Query OK, 0 rows affected (0.04 sec)

mysql> install plugin rpl_semi_sync_master soname 'semisync_master.so';
Query OK, 0 rows affected (0.07 sec)
```


- master节点配置
``` shell
mysql> set global rpl_semi_sync_master_enabled=ON;
Query OK, 0 rows affected (0.00 sec)

mysql> show global variables like '%semi%';
+-------------------------------------------+------------+
| Variable_name                             | Value      |
+-------------------------------------------+------------+
| rpl_semi_sync_master_enabled              | ON         |
| rpl_semi_sync_master_timeout              | 10000      |
| rpl_semi_sync_master_trace_level          | 32         |
| rpl_semi_sync_master_wait_for_slave_count | 1          |
| rpl_semi_sync_master_wait_no_slave        | ON         |
| rpl_semi_sync_master_wait_point           | AFTER_SYNC |
| rpl_semi_sync_slave_enabled               | OFF        |
| rpl_semi_sync_slave_trace_level           | 32         |
+-------------------------------------------+------------+
8 rows in set (0.05 sec)

mysql> reset master;
Query OK, 0 rows affected (0.14 sec)
```

- slave节点配置
``` shell
mysql> set global rpl_semi_sync_slave_enabled=ON;
Query OK, 0 rows affected (0.00 sec)

mysql> change master to master_host='192.168.188.51',master_port=4000,master_user='rep',master_password='rep',master_auto_position=1;
Query OK, 0 rows affected, 2 warnings (0.64 sec)

mysql> reset master;
Query OK, 0 rows affected (0.23 sec)
```

- slave 启动复制
``` shell
mysql>  start slave;
Query OK, 0 rows affected, 1 warning (0.00 sec)
```

- master查看半同步状态
``` shell
mysql> show global status like '%semi%';
+--------------------------------------------+-------+
| Variable_name                              | Value |
+--------------------------------------------+-------+
| Rpl_semi_sync_master_clients               | 2     |
| Rpl_semi_sync_master_net_avg_wait_time     | 0     |
| Rpl_semi_sync_master_net_wait_time         | 0     |
| Rpl_semi_sync_master_net_waits             | 0     |
| Rpl_semi_sync_master_no_times              | 0     |
| Rpl_semi_sync_master_no_tx                 | 0     |
| Rpl_semi_sync_master_status                | ON    |
| Rpl_semi_sync_master_timefunc_failures     | 0     |
| Rpl_semi_sync_master_tx_avg_wait_time      | 0     |
| Rpl_semi_sync_master_tx_wait_time          | 0     |
| Rpl_semi_sync_master_tx_waits              | 0     |
| Rpl_semi_sync_master_wait_pos_backtraverse | 0     |
| Rpl_semi_sync_master_wait_sessions         | 0     |
| Rpl_semi_sync_master_yes_tx                | 0     |
| Rpl_semi_sync_slave_status                 | OFF   |
+--------------------------------------------+-------+
15 rows in set (0.00 sec)

```


# 模拟业务，使用脚本产生事务

- 建表
``` sql
mysql> create database kk;
Query OK, 1 row affected (0.12 sec)

mysql> use kk
Database changed
mysql> create table k1 ( id int auto_increment primary key , dtl varchar(20) default 'abc');
Query OK, 0 rows affected (0.51 sec)
```
- 开启一个session，运行脚本产生事务
``` shell
[14:13:16] root@ms51:~ # while :; do  echo "insert into kk.k1(dtl) values('duangduangduang');" | mysql -S /data/mysql/mysql4000/tmp/mysql.sock; sleep 1;done
```

# 手动配置MGR
## 配置Master，将Master转为MGR
- 配置参数
```
mysql> install plugin group_replication soname 'group_replication.so';
Query OK, 0 rows affected (0.15 sec)

mysql> set global binlog_checksum=NONE;
Query OK, 0 rows affected (0.18 sec)

mysql> set global transaction_write_set_extraction=XXHASH64;
Query OK, 0 rows affected (0.00 sec)

mysql> select uuid();
+--------------------------------------+
| uuid()                               |
+--------------------------------------+
| a3e8c286-e375-11ea-868b-0242c0a8bc33 |
+--------------------------------------+
1 row in set (0.01 sec)

mysql> set global group_replication_group_name='a3e8c286-e375-11ea-868b-0242c0a8bc33';
Query OK, 0 rows affected (0.00 sec)

mysql> set global group_replication_local_address="192.168.188.51:13306"
    -> ;
Query OK, 0 rows affected (0.00 sec)

mysql> set global group_replication_group_seeds="192.168.188.51:13306,192.168.188.52:13306,192.168.188.53:13306";
Query OK, 0 rows affected (0.01 sec)

mysql> set global group_replication_start_on_boot=off;
Query OK, 0 rows affected (0.00 sec)

mysql> set global group_replication_bootstrap_group=on;
Query OK, 0 rows affected (0.00 sec)

mysql> start group_replication;
Query OK, 0 rows affected (2.82 sec)

mysql> set global group_replication_bootstrap_group=off;
Query OK, 0 rows affected (0.00 sec)

mysql> select * from performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE |
+---------------------------+--------------------------------------+-------------+-------------+--------------+
| group_replication_applier | e630ab09-e372-11ea-8a64-0242c0a8bc33 | ms51        |        4000 | ONLINE       |
+---------------------------+--------------------------------------+-------------+-------------+--------------+
1 row in set (0.00 sec)

补充，还有这关键的一步（原因见文末）：
mysql> change master to master_user='rep',master_password='rep' for channel 'group_replication_recovery';
Query OK, 0 rows affected, 2 warnings (0.05 sec)
```

**由于MySQL 5.7 不支持参数持久化语法 set persist，因此MGR相关的参数我们要手动合并到master实例的my.cnf文件**
```
binlog_checksum=NONE
transaction_write_set_extraction=XXHASH64
loose-group_replication_group_name='a3e8c286-e375-11ea-868b-0242c0a8bc33'
loose-group_replication_local_address="192.168.188.51:13306"
loose-group_replication_group_seeds="192.168.188.51:13306,192.168.188.52:13306,192.168.188.53:13306"
loose-group_replication_bootstrap_group=off
loose-group_replication_start_on_boot=off
```

## 去配置slave1 ，转换为MGR
```
mysql> install plugin group_replication soname 'group_replication.so';
Query OK, 0 rows affected (0.04 sec)

mysql>  set global binlog_checksum=NONE;
Query OK, 0 rows affected (0.23 sec)

mysql>  set global transaction_write_set_extraction=XXHASH64;
Query OK, 0 rows affected (0.00 sec)

mysql>  set global group_replication_group_name='a3e8c286-e375-11ea-868b-0242c0a8bc33';
Query OK, 0 rows affected (0.00 sec)

mysql> set global group_replication_local_address="192.168.188.52:13306";
Query OK, 0 rows affected (0.00 sec)

mysql>  set global group_replication_group_seeds="192.168.188.51:13306,192.168.188.52:13306,192.168.188.53:13306";
Query OK, 0 rows affected (0.01 sec)

mysql> change master to master_user='rep',master_password='rep' for channel 'group_replication_recovery';
Query OK, 0 rows affected, 2 warnings (0.47 sec)

mysql> start group_replication;
ERROR 3092 (HY000): The server is not configured properly to be an active member of the group. Please see more details on error log.
mysql> exit

```
启动MGR失败，按照提示去检查errorlog，原来复制进行时无法启动MGR
```
[14:50:50] root@ms52:~ # less /data/mysql/mysql4000/logs/error.log 
...
2020-08-21T14:50:43.791879+08:00 2 [Note] Plugin group_replication reported: 'Member configuration: member_id: 524000; member_uuid: "aee85149-e379-11ea-8c01-0242c0a8bc34"; single-primary mode: "true"; group_replication_auto_increment_increment: 7; '
2020-08-21T14:50:43.791901+08:00 2 [ERROR] Plugin group_replication reported: 'Can't start group replication on secondary member with single primary-mode while asynchronous replication channels are running.'
2020-08-21T14:50:43.791930+08:00 2 [Note] Plugin group_replication reported: 'Requesting to leave the group despite of not being a member'
2020-08-21T14:50:43.791944+08:00 2 [ERROR] Plugin group_replication reported: '[GCS] The member is leaving a group without being on one.'
```
停止复制，启动MGR便成功了，稍等片刻，节点状态便ONLINE了。

```
[14:51:32] root@ms52:~ # mysql -S /data/mysql/mysql4000/tmp/mysql.sock

mysql> stop slave;
Query OK, 0 rows affected (0.09 sec)

mysql> start group_replication;
Query OK, 0 rows affected (6.61 sec)

mysql> select * from performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE |
+---------------------------+--------------------------------------+-------------+-------------+--------------+
| group_replication_applier | ab726fa8-e379-11ea-a4c2-0242c0a8bc33 | ms51        |        4000 | ONLINE       |
| group_replication_applier | aee85149-e379-11ea-8c01-0242c0a8bc34 | ms52        |        4000 | ONLINE       |
+---------------------------+--------------------------------------+-------------+-------------+--------------+
2 rows in set (0.00 sec)

```
**同样的，由于MySQL 5.7不支持参数直接持久化保存，需要手动将原slave1的相关参数补充到slave1实例的my.cnf文件中**

```
binlog_checksum=NONE
transaction_write_set_extraction=XXHASH64
loose-group_replication_group_name='a3e8c286-e375-11ea-868b-0242c0a8bc33'
loose-group_replication_local_address="192.168.188.52:13306"
loose-group_replication_group_seeds="192.168.188.51:13306,192.168.188.52:13306,192.168.188.53:13306"
loose-group_replication_bootstrap_group=off
loose-group_replication_start_on_boot=off
```

同理，将slave2转换为MGR成员，步骤略，记得保存参数到实例的my.cnf文件。

- 最终转换完成后，三个节点都顺利ONLINE。
```
mysql> select * from performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE |
+---------------------------+--------------------------------------+-------------+-------------+--------------+
| group_replication_applier | ab726fa8-e379-11ea-a4c2-0242c0a8bc33 | ms51        |        4000 | ONLINE       |
| group_replication_applier | aee85149-e379-11ea-8c01-0242c0a8bc34 | ms52        |        4000 | ONLINE       |
| group_replication_applier | b24d5bc3-e379-11ea-8eae-0242c0a8bc35 | ms53        |        4000 | ONLINE       |
+---------------------------+--------------------------------------+-------------+-------------+--------------+
3 rows in set (0.00 sec)
```


# MGR冷启动
- 将三节点全部关掉
```
mysql > shutdown ;

```

- 启动第一个节点(slave2)
```
[15:02:58] root@ms53:~ # mysqld --defaults-file=/data/mysql/mysql4000/my4000.cnf &
[1] 604
[15:04:51] root@ms53:~ # mysql -S /data/mysql/mysql4000/tmp/mysql.sock

mysql> set global group_replication_bootstrap_group=ON;
Query OK, 0 rows affected (0.00 sec)

mysql> start group_replication;
Query OK, 0 rows affected (2.53 sec)

mysql> set global group_replication_bootstrap_group=OFF;
Query OK, 0 rows affected (0.00 sec)

mysql> select * from performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE |
+---------------------------+--------------------------------------+-------------+-------------+--------------+
| group_replication_applier | b24d5bc3-e379-11ea-8eae-0242c0a8bc35 | ms53        |        4000 | ONLINE       |
+---------------------------+--------------------------------------+-------------+-------------+--------------+
1 row in set (0.00 sec)
```

- 启动第二个节点(slave1)
```
[15:03:20] root@ms52:~ # mysqld --defaults-file=/data/mysql/mysql4000/my4000.cnf &
[1] 593
[15:04:47] root@ms52:~ # mysql -S /data/mysql/mysql4000/tmp/mysql.sock

mysql> start group_replication;
Query OK, 0 rows affected (6.37 sec)

mysql> select * from performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE |
+---------------------------+--------------------------------------+-------------+-------------+--------------+
| group_replication_applier | aee85149-e379-11ea-8c01-0242c0a8bc34 | ms52        |        4000 | ONLINE       |
| group_replication_applier | b24d5bc3-e379-11ea-8eae-0242c0a8bc35 | ms53        |        4000 | ONLINE       |
+---------------------------+--------------------------------------+-------------+-------------+--------------+
2 rows in set (0.00 sec)
```

- 启动第三个节点(master)，踩了个坑

```
[15:04:33] root@ms51:~ # mysqld --defaults-file=/data/mysql/mysql4000/my4000.cnf &
[1] 7410
[15:04:43] root@ms51:~ # mysql -S /data/mysql/mysql4000/tmp/mysql.sock

mysql> start group_replication;
Query OK, 0 rows affected (5.98 sec)

mysql> select * from performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE |
+---------------------------+--------------------------------------+-------------+-------------+--------------+
| group_replication_applier | ab726fa8-e379-11ea-a4c2-0242c0a8bc33 | ms51        |        4000 | RECOVERING   |
| group_replication_applier | aee85149-e379-11ea-8c01-0242c0a8bc34 | ms52        |        4000 | ONLINE       |
| group_replication_applier | b24d5bc3-e379-11ea-8eae-0242c0a8bc35 | ms53        |        4000 | ONLINE       |
+---------------------------+--------------------------------------+-------------+-------------+--------------+
3 rows in set (0.00 sec)
```
原master节点长时间处于recovering，查看status后猛然想起，先前转换MGR时，只对slave1、slave2做了change master for channel，把master给忘记了。
（该步骤已重新补充到master转换的操作步骤中。）
```
mysql> change master to master_user='rep',master_password='rep' for channel 'group_replication_recovery';
Query OK, 0 rows affected, 2 warnings (0.05 sec)

mysql> stop group_replication;
Query OK, 0 rows affected (10.65 sec)

mysql> start group_replication;
Query OK, 0 rows affected (3.27 sec)

mysql> select * from performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE |
+---------------------------+--------------------------------------+-------------+-------------+--------------+
| group_replication_applier | ab726fa8-e379-11ea-a4c2-0242c0a8bc33 | ms51        |        4000 | ONLINE       |
| group_replication_applier | aee85149-e379-11ea-8c01-0242c0a8bc34 | ms52        |        4000 | ONLINE       |
| group_replication_applier | b24d5bc3-e379-11ea-8eae-0242c0a8bc35 | ms53        |        4000 | ONLINE       |
+---------------------------+--------------------------------------+-------------+-------------+--------------+
3 rows in set (0.00 sec)

```

噢，忘了检查事务情况。 三节点结果一样，转换全面成功。
```
mysql> select count(*) from kk.k1;
+----------+
| count(*) |
+----------+
|      277 |
+----------+
1 row in set (0.02 sec)

mysql> show master status;
+------------------+----------+--------------+------------------+---------------------------------------------------------------------------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                                                                     |
+------------------+----------+--------------+------------------+---------------------------------------------------------------------------------------+
| mysql-bin.000003 |     1686 |              |                  | a3e8c286-e375-11ea-868b-0242c0a8bc33:1-240,
ab726fa8-e379-11ea-a4c2-0242c0a8bc33:1-46 |
+------------------+----------+--------------+------------------+---------------------------------------------------------------------------------------+
1 row in set (0.00 sec)


```