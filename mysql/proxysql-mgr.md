# 环境信息
|hostname|IP|port|role|comm|
|-|-|-|-|-|
|ms81|192.168.188.81|3399|master||
|ms82|192.168.188.82|3399|slave||
|ms83|192.168.188.83|3399|slave||
|ms84|192.168.188.84|6033|proxysql&sysbench||

- ProxySQL version 2.0.11-124-g971c15e, codename Truls
- MySQL 8.0.19 x86_64
- mysqlsh 8.0.20
- CentOS 7.8.2003 on Docker


# 配置MySQL
## 通过MySQL Shell配置singlePrimary模式MGR

## 配置用户
```
mysql> set global super_read_only=0;

mysql> create user mgr@'192.168.188.%' identified by 'mgr';

mysql> grant all privileges on *.* to mgr@'192.168.188.%' with grant option;

mysql> create user kk@'192.168.188.%' identified by 'kk';

mysql> grant all privileges on *.* to kk@'192.168.188.%';

mysql> create user proxy@'192.168.188.%' identified with mysql_native_password by 'proxy';

mysql> grant all privileges on *.* to proxy@'192.168.188.%';

mysql> create user monitor@'192.168.188.%' identified with mysql_native_password by 'monitor';

mysql> grant replication client on *.* to monitor@'192.168.188.%';

mysql> reset master;

mysql> create database kk;
```

## 运行proxysql需要的脚本
``` shell
[13:46:00] root@ms81:/ofiles # mysql -S /data/mysql/mysql3399/tmp/mysql.sock  < addition_to_sys8.sql 

#记得授权！
mysql> grant select on sys.gr_member_routing_candidate_status to 'monitor'@'192.168.188.%';
Query OK, 0 rows affected (0.12 sec)

```

# 配置ProxySQL

## 定义并配置proxysql的HostGroups
|gid|hostgroup|
|-|-|
|100|read|
|111|write|
|122|backup_write|
|404|offline|
``` shell
mysql> show create table mysql_group_replication_hostgroups\G
*************************** 1. row ***************************
       table: mysql_group_replication_hostgroups
Create Table: CREATE TABLE mysql_group_replication_hostgroups (
    writer_hostgroup INT CHECK (writer_hostgroup>=0) NOT NULL PRIMARY KEY,
    backup_writer_hostgroup INT CHECK (backup_writer_hostgroup>=0 AND backup_writer_hostgroup<>writer_hostgroup) NOT NULL,
    reader_hostgroup INT NOT NULL CHECK (reader_hostgroup<>writer_hostgroup AND backup_writer_hostgroup<>reader_hostgroup AND reader_hostgroup>0),
    offline_hostgroup INT NOT NULL CHECK (offline_hostgroup<>writer_hostgroup AND offline_hostgroup<>reader_hostgroup AND backup_writer_hostgroup<>offline_hostgroup AND offline_hostgroup>=0),
    active INT CHECK (active IN (0,1)) NOT NULL DEFAULT 1,
    max_writers INT NOT NULL CHECK (max_writers >= 0) DEFAULT 1,
    writer_is_also_reader INT CHECK (writer_is_also_reader IN (0,1,2)) NOT NULL DEFAULT 0,
    max_transactions_behind INT CHECK (max_transactions_behind>=0) NOT NULL DEFAULT 0,
    comment VARCHAR,
    UNIQUE (reader_hostgroup),
    UNIQUE (offline_hostgroup),
    UNIQUE (backup_writer_hostgroup))
1 row in set (0.00 sec)


# 这里没修改  max_writers ，默认为1。 不建议增加，即使是multiPromary模式，proxysql也建议使用单写。
mysql> insert into mysql_group_replication_hostgroups(writer_hostgroup,backup_writer_hostgroup,reader_hostgroup,offline_hostgroup,active) values (111,122,100,404,1);
Query OK, 1 row affected (0.00 sec)

mysql> select * from mysql_group_replication_hostgroups;
+------------------+-------------------------+------------------+-------------------+--------+-------------+-----------------------+-------------------------+---------+
| writer_hostgroup | backup_writer_hostgroup | reader_hostgroup | offline_hostgroup | active | max_writers | writer_is_also_reader | max_transactions_behind | comment |
+------------------+-------------------------+------------------+-------------------+--------+-------------+-----------------------+-------------------------+---------+
| 111              | 122                     | 100              | 404               | 1      | 1           | 0                     | 0                       | NULL    |
+------------------+-------------------------+------------------+-------------------+--------+-------------+-----------------------+-------------------------+---------+
1 row in set (0.00 sec)

```

## 添加servers
``` shell
mysql> show create table mysql_servers\G
*************************** 1. row ***************************
       table: mysql_servers
Create Table: CREATE TABLE mysql_servers (
    hostgroup_id INT CHECK (hostgroup_id>=0) NOT NULL DEFAULT 0,
    hostname VARCHAR NOT NULL,
    port INT CHECK (port >= 0 AND port <= 65535) NOT NULL DEFAULT 3306,
    gtid_port INT CHECK ((gtid_port <> port OR gtid_port=0) AND gtid_port >= 0 AND gtid_port <= 65535) NOT NULL DEFAULT 0,
    status VARCHAR CHECK (UPPER(status) IN ('ONLINE','SHUNNED','OFFLINE_SOFT', 'OFFLINE_HARD')) NOT NULL DEFAULT 'ONLINE',
    weight INT CHECK (weight >= 0 AND weight <=10000000) NOT NULL DEFAULT 1,
    compression INT CHECK (compression IN(0,1)) NOT NULL DEFAULT 0,
    max_connections INT CHECK (max_connections >=0) NOT NULL DEFAULT 1000,
    max_replication_lag INT CHECK (max_replication_lag >= 0 AND max_replication_lag <= 126144000) NOT NULL DEFAULT 0,
    use_ssl INT CHECK (use_ssl IN(0,1)) NOT NULL DEFAULT 0,
    max_latency_ms INT UNSIGNED CHECK (max_latency_ms>=0) NOT NULL DEFAULT 0,
    comment VARCHAR NOT NULL DEFAULT '',
    PRIMARY KEY (hostgroup_id, hostname, port) )
1 row in set (0.00 sec)

mysql> insert into mysql_servers(hostgroup_id,hostname,port,max_connections) values (100,'192.168.188.81',3399,200);
Query OK, 1 row affected (0.00 sec)

mysql> insert into mysql_servers(hostgroup_id,hostname,port,max_connections) values (100,'192.168.188.82',3399,200);
Query OK, 1 row affected (0.00 sec)

mysql> insert into mysql_servers(hostgroup_id,hostname,port,max_connections) values (100,'192.168.188.83',3399,200);
Query OK, 1 row affected (0.00 sec)

mysql> select hostgroup_id,hostname,port,max_connections from mysql_servers;
+--------------+----------------+------+-----------------+
| hostgroup_id | hostname       | port | max_connections |
+--------------+----------------+------+-----------------+
| 100          | 192.168.188.81 | 3399 | 200             |
| 100          | 192.168.188.82 | 3399 | 200             |
| 100          | 192.168.188.83 | 3399 | 200             |
+--------------+----------------+------+-----------------+
3 rows in set (0.00 sec)

mysql> load mysql servers to run;
Query OK, 0 rows affected (0.01 sec)

mysql> save mysql servers to disk;
Query OK, 0 rows affected (0.83 sec)

```

## 添加user

```
mysql> show create table mysql_users\G
*************************** 1. row ***************************
       table: mysql_users
Create Table: CREATE TABLE mysql_users (
    username VARCHAR NOT NULL,
    password VARCHAR,
    active INT CHECK (active IN (0,1)) NOT NULL DEFAULT 1,
    use_ssl INT CHECK (use_ssl IN (0,1)) NOT NULL DEFAULT 0,
    default_hostgroup INT NOT NULL DEFAULT 0,
    default_schema VARCHAR,
    schema_locked INT CHECK (schema_locked IN (0,1)) NOT NULL DEFAULT 0,
    transaction_persistent INT CHECK (transaction_persistent IN (0,1)) NOT NULL DEFAULT 1,
    fast_forward INT CHECK (fast_forward IN (0,1)) NOT NULL DEFAULT 0,
    backend INT CHECK (backend IN (0,1)) NOT NULL DEFAULT 1,
    frontend INT CHECK (frontend IN (0,1)) NOT NULL DEFAULT 1,
    max_connections INT CHECK (max_connections >=0) NOT NULL DEFAULT 10000,
    comment VARCHAR NOT NULL DEFAULT '',
    PRIMARY KEY (username, backend),
    UNIQUE (username, frontend))
1 row in set (0.00 sec)

mysql> insert into mysql_users(username,password,active,default_hostgroup,default_schema) values ('proxy','proxy',1,100,'kk');
Query OK, 1 row affected (0.00 sec)

mysql> insert into mysql_users(username,password,active,default_hostgroup,default_schema) values ('kk','kk',1,100,'kk');
Query OK, 1 row affected (0.00 sec)

mysql> select * from mysql_users;
+----------+----------+--------+---------+-------------------+----------------+---------------+------------------------+--------------+---------+----------+-----------------+---------+
| username | password | active | use_ssl | default_hostgroup | default_schema | schema_locked | transaction_persistent | fast_forward | backend | frontend | max_connections | comment |
+----------+----------+--------+---------+-------------------+----------------+---------------+------------------------+--------------+---------+----------+-----------------+---------+
| proxy    | proxy    | 1      | 0       | 100               | kk             | 0             | 1                      | 0            | 1       | 1        | 10000           |         |
| kk       | kk       | 1      | 0       | 100               | kk             | 0             | 1                      | 0            | 1       | 1        | 10000           |         |
+----------+----------+--------+---------+-------------------+----------------+---------------+------------------------+--------------+---------+----------+-----------------+---------+
2 rows in set (0.00 sec)

mysql> load mysql users to run;
Query OK, 0 rows affected (0.00 sec)

mysql> save mysql users to disk;
Query OK, 0 rows affected (0.36 sec)

```
## 检查一下，可以看到已经根据节点状态进行分组
```

mysql> select * from monitor.mysql_server_group_replication_log;

mysql> select * from runtime_mysql_servers;
+--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
| hostgroup_id | hostname       | port | gtid_port | status | weight | compression | max_connections | max_replication_lag | use_ssl | max_latency_ms | comment |
+--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
| 100          | 192.168.188.82 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
| 111          | 192.168.188.81 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
| 100          | 192.168.188.83 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
+--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
3 rows in set (0.01 sec)

```
## 添加规则前做一次性能测试
```
[15:37:26] root@ms84:~ # sysbench /usr/share/sysbench/oltp_read_write.lua  --db-driver=mysql --mysql-host=192.168.188.84 --mysql-port=6033  --mysql-user=kk --mysql-password=kk --mysql-db=kk --table-size=50000 prepare
sysbench 1.0.17 (using system LuaJIT 2.0.4)

Creating table 'sbtest1'...
FATAL: mysql_drv_query() returned error 1290 (The MySQL server is running with the --super-read-only option so it cannot execute this statement) for query 'CREATE TABLE sbtest1(
  id INTEGER NOT NULL AUTO_INCREMENT,
  k INTEGER DEFAULT '0' NOT NULL,
  c CHAR(120) DEFAULT '' NOT NULL,
  pad CHAR(60) DEFAULT '' NOT NULL,
  PRIMARY KEY (id)
) /*! ENGINE = innodb */ '
FATAL: `sysbench.cmdline.call_command' function failed: /usr/share/sysbench/oltp_common.lua:197: SQL error, errno = 1290, state = 'HY000': The MySQL server is running with the --super-read-only option so it cannot execute this statement

看来需要修改一下，不然找不到rw服务器…… 默认都发给只读组了。

# 这块实验中发现了个问题，sysbench通过proxysql的服务端口连接后，无法进行任何操作：
# mysql> show tables;
# ERROR 1045 (28000): Access denied for user 'kk'@'ms84.net188' (using password: YES)
# 可以发现，用户被解析成proxysql的域名来源了，而实际上对kk用户的授权做的是 kk@'192.168.188.%',
# 查看了一下MySQL的参数文件，原因为：
# mysql> show global variables like '%reso%';
# +-------------------+-------+
# | Variable_name     | Value |
# +-------------------+-------+
# | skip_name_resolve | OFF   |
# +-------------------+-------+
# 1 row in set (0.01 sec)
# 可以设置为1， 或重新建立用户 kk@'%' ，在本次实验里，由于设计的是所有访问通过proxysql，proxysql以kk用户与MySQL MGR通信
# 因此在这里我另外建立了用户'kk'@'ms84.net188'，并授权。
# 再次通过其它IP使用proxysql的服务端口登录后，查看当前用户为：
# mysql> select current_user();
# +----------------+
# | current_user() |
# +----------------+
# | kk@ms84.net188 |
# +----------------+
# 1 row in set (0.00 sec)
# 可以看到，无论发起连接请求的client在哪里，current_user 都是proxysql的domain，这也验证了前面的猜测。




proxysql修改：
mysql> update mysql_users set default_hostgroup=111 where username='kk';
Query OK, 1 row affected (0.00 sec)

mysql> load mysql users to run;
Query OK, 0 rows affected (0.00 sec)

[15:39:01] root@ms84:~ # sysbench /usr/share/sysbench/oltp_read_write.lua  --db-driver=mysql --mysql-host=192.168.188.84 --mysql-port=6033  --mysql-user=kk --mysql-password=kk --mysql-db=kk --table-size=50000 prepare
sysbench 1.0.17 (using system LuaJIT 2.0.4)

Creating table 'sbtest1'...
Inserting 50000 records into 'sbtest1'
Creating a secondary index on 'sbtest1'...

[15:40:57] root@ms84:~ # sysbench /usr/share/sysbench/oltp_read_write.lua  --db-driver=mysql --mysql-host=192.168.188.84 --mysql-port=6033  --mysql-user=kk --mysql-password=kk --mysql-db=kk --table-size=50000 run   
sysbench 1.0.17 (using system LuaJIT 2.0.4)

Running the test with following options:
Number of threads: 1
Initializing random number generator from current time


Initializing worker threads...

Threads started!

SQL statistics:
    queries performed:
        read:                            714
        write:                           204
        other:                           102
        total:                           1020
    transactions:                        51     (5.00 per sec.)
    queries:                             1020   (100.03 per sec.)
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          10.1929s
    total number of events:              51

Latency (ms):
         min:                                  104.38
         avg:                                  199.83
         max:                                  444.15
         95th percentile:                      297.92
         sum:                                10191.23

Threads fairness:
    events (avg/stddev):           51.0000/0.00
    execution time (avg/stddev):   10.1912/0.00


mysql> select hostgroup,digest, digest_text,count_star from stats.stats_mysql_query_digest;
+-----------+--------------------+--------------------------------------------------------------------+------------+
| hostgroup | digest             | digest_text                                                        | count_star |
+-----------+--------------------+--------------------------------------------------------------------+------------+
| 111       | 0xE52A0A0210634DAC | INSERT INTO sbtest1 (id, k, c, pad) VALUES (?, ?, ?, ?)            | 52         |
| 111       | 0xE365BEB555319B9E | DELETE FROM sbtest1 WHERE id=?                                     | 52         |
| 111       | 0xFB239BC95A23CA36 | UPDATE sbtest1 SET c=? WHERE id=?                                  | 52         |
| 111       | 0xC19480748AE79B4B | SELECT DISTINCT c FROM sbtest1 WHERE id BETWEEN ? AND ? ORDER BY c | 52         |
| 111       | 0xAC80A5EA0101522E | SELECT c FROM sbtest1 WHERE id BETWEEN ? AND ? ORDER BY c          | 52         |
| 111       | 0xC198E52BCCB481C7 | UPDATE sbtest1 SET k=k+? WHERE id=?                                | 52         |
| 111       | 0xDBF868B2AA296BC5 | SELECT SUM(k) FROM sbtest1 WHERE id BETWEEN ? AND ?                | 52         |
| 111       | 0x290B92FD743826DA | SELECT c FROM sbtest1 WHERE id BETWEEN ? AND ?                     | 52         |
| 111       | 0xBF001A0C13781C1D | SELECT c FROM sbtest1 WHERE id=?                                   | 511        |
| 111       | 0x695FBF255DBEB0DD | COMMIT                                                             | 52         |
| 111       | 0xFAD1519E4760CBDE | BEGIN                                                              | 52         |
+-----------+--------------------+--------------------------------------------------------------------+------------+
11 rows in set (0.01 sec)



```
## 做完全的读写分离规则
    在这里做完全的读写分离.
    可以看出来在一台物理server上这样搞是有损失的，哈哈
```
mysql> insert into mysql_query_rules(rule_id,active,match_pattern,destination_hostgroup,apply) values (1,1,'^SELECT.*FOR UPDATE$',111,1);
Query OK, 1 row affected (0.00 sec)

mysql> insert into mysql_query_rules(rule_id,active,match_pattern,destination_hostgroup,apply) values (2,1,'^SELECT.*',100,1);
Query OK, 1 row affected (0.00 sec)

mysql> select * from mysql_query_rules;
+---------+--------+----------+------------+--------+-------------+------------+------------+--------+--------------+----------------------+----------------------+--------------+---------+-----------------+-----------------------+-----------+--------------------+---------------+-----------+---------+---------+-------+-------------------+----------------+------------------+-----------+--------+-------------+-----------+---------------------+-----+-------+---------+
| rule_id | active | username | schemaname | flagIN | client_addr | proxy_addr | proxy_port | digest | match_digest | match_pattern        | negate_match_pattern | re_modifiers | flagOUT | replace_pattern | destination_hostgroup | cache_ttl | cache_empty_result | cache_timeout | reconnect | timeout | retries | delay | next_query_flagIN | mirror_flagOUT | mirror_hostgroup | error_msg | OK_msg | sticky_conn | multiplex | gtid_from_hostgroup | log | apply | comment |
+---------+--------+----------+------------+--------+-------------+------------+------------+--------+--------------+----------------------+----------------------+--------------+---------+-----------------+-----------------------+-----------+--------------------+---------------+-----------+---------+---------+-------+-------------------+----------------+------------------+-----------+--------+-------------+-----------+---------------------+-----+-------+---------+
| 1       | 1      | NULL     | NULL       | 0      | NULL        | NULL       | NULL       | NULL   | NULL         | ^SELECT.*FOR UPDATE$ | 0                    | CASELESS     | NULL    | NULL            | 111                   | NULL      | NULL               | NULL          | NULL      | NULL    | NULL    | NULL  | NULL              | NULL           | NULL             | NULL      | NULL   | NULL        | NULL      | NULL                | NULL | 1     | NULL    |
| 2       | 1      | NULL     | NULL       | 0      | NULL        | NULL       | NULL       | NULL   | NULL         | ^SELECT.*            | 0                    | CASELESS     | NULL    | NULL            | 100                   | NULL      | NULL               | NULL          | NULL      | NULL    | NULL    | NULL  | NULL              | NULL           | NULL             | NULL      | NULL   | NULL        | NULL      | NULL                | NULL | 1     | NULL    |
+---------+--------+----------+------------+--------+-------------+------------+------------+--------+--------------+----------------------+----------------------+--------------+---------+-----------------+-----------------------+-----------+--------------------+---------------+-----------+---------+---------+-------+-------------------+----------------+------------------+-----------+--------+-------------+-----------+---------------------+-----+-------+---------+
2 rows in set (0.00 sec)

mysql> load mysql query rules to run;
Query OK, 0 rows affected (0.00 sec)

mysql> save mysql query rules to disk;
Query OK, 0 rows affected (0.47 sec)

mysql> select hostgroup,digest, digest_text,count_star from stats.stats_mysql_query_digest_reset;

[15:51:54] root@ms84:~ # sysbench /usr/share/sysbench/oltp_read_write.lua  --db-driver=mysql --mysql-host=192.168.188.84 --mysql-port=6033  --mysql-user=kk --mysql-password=kk --mysql-db=kk --table-size=50000 run
sysbench 1.0.17 (using system LuaJIT 2.0.4)

Running the test with following options:
Number of threads: 1
Initializing random number generator from current time


Initializing worker threads...

Threads started!

SQL statistics:
    queries performed:
        read:                            672
        write:                           192
        other:                           96
        total:                           960
    transactions:                        48     (4.79 per sec.)
    queries:                             960    (95.87 per sec.)
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          10.0099s
    total number of events:              48

Latency (ms):
         min:                                  104.58
         avg:                                  208.51
         max:                                  458.81
         95th percentile:                      331.91
         sum:                                10008.26

Threads fairness:
    events (avg/stddev):           48.0000/0.00
    execution time (avg/stddev):   10.0083/0.00


mysql> select hostgroup,digest, digest_text,count_star from stats.stats_mysql_query_digest;
+-----------+--------------------+--------------------------------------------------------------------+------------+
| hostgroup | digest             | digest_text                                                        | count_star |
+-----------+--------------------+--------------------------------------------------------------------+------------+
| 111       | 0xE52A0A0210634DAC | INSERT INTO sbtest1 (id, k, c, pad) VALUES (?, ?, ?, ?)            | 49         |
| 111       | 0xFB239BC95A23CA36 | UPDATE sbtest1 SET c=? WHERE id=?                                  | 49         |
| 111       | 0xC198E52BCCB481C7 | UPDATE sbtest1 SET k=k+? WHERE id=?                                | 49         |
| 100       | 0xC19480748AE79B4B | SELECT DISTINCT c FROM sbtest1 WHERE id BETWEEN ? AND ? ORDER BY c | 49         |
| 100       | 0xAC80A5EA0101522E | SELECT c FROM sbtest1 WHERE id BETWEEN ? AND ? ORDER BY c          | 49         |
| 111       | 0xE365BEB555319B9E | DELETE FROM sbtest1 WHERE id=?                                     | 49         |
| 100       | 0x290B92FD743826DA | SELECT c FROM sbtest1 WHERE id BETWEEN ? AND ?                     | 49         |
| 100       | 0xBF001A0C13781C1D | SELECT c FROM sbtest1 WHERE id=?                                   | 481        |
| 100       | 0xDBF868B2AA296BC5 | SELECT SUM(k) FROM sbtest1 WHERE id BETWEEN ? AND ?                | 49         |
| 111       | 0x695FBF255DBEB0DD | COMMIT                                                             | 49         |
| 111       | 0xFAD1519E4760CBDE | BEGIN                                                              | 49         |
+-----------+--------------------+--------------------------------------------------------------------+------------+
11 rows in set (0.01 sec)


```

# 看一下MGR做failover时，proxysql的状态。
- 当前MGR状态
```
 MySQL  192.168.188.81:3399 ssl  JS > cl.status()
{
    "clusterName": "kk", 
    "defaultReplicaSet": {
        "name": "default", 
        "primary": "ms81:3399", 
        "ssl": "REQUIRED", 
        "status": "OK", 
        "statusText": "Cluster is ONLINE and can tolerate up to ONE failure.", 
        "topology": {
            "ms81:3399": {
                "address": "ms81:3399", 
                "mode": "R/W", 
                "readReplicas": {}, 
                "replicationLag": null, 
                "role": "HA", 
                "status": "ONLINE", 
                "version": "8.0.19"
            }, 
            "ms82:3399": {
                "address": "ms82:3399", 
                "mode": "R/O", 
                "readReplicas": {}, 
                "replicationLag": "00:00:00.317335", 
                "role": "HA", 
                "status": "ONLINE", 
                "version": "8.0.19"
            }, 
            "ms83:3399": {
                "address": "ms83:3399", 
                "mode": "R/O", 
                "readReplicas": {}, 
                "replicationLag": "00:00:00.227030", 
                "role": "HA", 
                "status": "ONLINE", 
                "version": "8.0.19"
            }
        }, 
        "topologyMode": "Single-Primary"
    }, 
    "groupInformationSourceMember": "ms81:3399"
}


```
- 当前proxysql mysql_servers状态
```
mysql>  select * from runtime_mysql_servers;
+--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
| hostgroup_id | hostname       | port | gtid_port | status | weight | compression | max_connections | max_replication_lag | use_ssl | max_latency_ms | comment |
+--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
| 100          | 192.168.188.83 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
| 111          | 192.168.188.81 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
| 100          | 192.168.188.82 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
+--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
3 rows in set (0.01 sec)


```

- 将当前master重启，再查看proxysql mysql_servers
```
master:
mysql> shutdown ;
Query OK, 0 rows affected (0.00 sec)


mysql> mysql>  select * from runtime_mysql_servers;
+--------------+----------------+------+-----------+---------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
| hostgroup_id | hostname       | port | gtid_port | status  | weight | compression | max_connections | max_replication_lag | use_ssl | max_latency_ms | comment |
+--------------+----------------+------+-----------+---------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
| 100          | 192.168.188.83 | 3399 | 0         | ONLINE  | 1      | 0           | 200             | 0                   | 0       | 0              |         |
| 404          | 192.168.188.81 | 3399 | 0         | SHUNNED | 1      | 0           | 200             | 0                   | 0       | 0              |         |
| 111          | 192.168.188.82 | 3399 | 0         | ONLINE  | 1      | 0           | 200             | 0                   | 0       | 0              |         |
+--------------+----------------+------+-----------+---------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
3 rows in set (0.00 sec)


```

- 重启master ，再查看
```
master
[16:12:33] root@ms81:~ # mysqld --defaults-file=/data/mysql/mysql3399/my3399.cnf &

使用MySQL shell构建的MGR ，在节点重启后会自动启动GR

mysql>  select * from runtime_mysql_servers;
+--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
| hostgroup_id | hostname       | port | gtid_port | status | weight | compression | max_connections | max_replication_lag | use_ssl | max_latency_ms | comment |
+--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
| 100          | 192.168.188.83 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
| 111          | 192.168.188.82 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
| 100          | 192.168.188.81 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
+--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
3 rows in set (0.00 sec)

```








