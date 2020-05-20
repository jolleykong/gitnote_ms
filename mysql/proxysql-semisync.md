# 环境信息
|hostname|IP|port|role|comm|
|-|-|-|-|-|
|ms81|192.168.188.81|3399|master||
|ms82|192.168.188.82|3399|slave||
|ms83|192.168.188.83|3399|slave||
|ms84|192.168.188.84|6033|proxysql&sysbench||

- ProxySQL version 2.0.11-124-g971c15e, codename Truls
- MySQL 8.0.19 x86_64
- CentOS 7.8.2003 on Docker

# 配置半同步
- ms81 配置环境  
    ``` shell
    [10:46:55] root@ms81:~ # ./mysql_onekey_3.2.1.sh /opt/mysql-8.0.19-linux-glibc2.12-x86_64 3399

    ##ms81
    [10:51:30] root@ms81:~ # mysql -S /data/mysql/mysql3399/tmp/mysql.sock
    mysql> set global super_read_only=0;
    Query OK, 0 rows affected (0.00 sec)

    mysql> create user 'rep'@'192.168.188.%' identified by 'rep';
    Query OK, 0 rows affected (0.02 sec)

    mysql> grant replication slave on *.* to 'rep'@'192.168.188.%';
    Query OK, 0 rows affected (0.02 sec)

    mysql> create user 'proxy'@'192.168.188.%' identified with mysql_native_password by 'proxy';
    Query OK, 0 rows affected (0.02 sec)

    mysql> grant replication client on *.* to 'proxy'@'192.168.188.%';
    Query OK, 0 rows affected (0.02 sec)

    mysql> create user 'monitor'@'192.168.188.%' identified with mysql_native_password by 'monitor';
    Query OK, 0 rows affected (10.02 sec)

    mysql> grant replication client on *.*  to 'monitor'@'192.168.188.%';
    Query OK, 0 rows affected (0.02 sec)

    mysql> install plugin rpl_semi_sync_master soname 'semisync_master.so';
    Query OK, 0 rows affected (0.02 sec)

    mysql> install plugin rpl_semi_sync_slave soname 'semisync_slave.so';
    Query OK, 0 rows affected (0.02 sec)

    mysql> set global  rpl_semi_sync_master_enabled =1;
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
    8 rows in set (0.00 sec)

    mysql> reset master;
    Query OK, 0 rows affected (0.05 sec)

    mysql> show master status;
    +------------------+----------+--------------+------------------+-------------------+
    | File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
    +------------------+----------+--------------+------------------+-------------------+
    | mysql-bin.000001 |      155 |              |                  |                   |
    +------------------+----------+--------------+------------------+-------------------+
    1 row in set (0.00 sec)


    ```

- ms82 配置环境  
    ``` shell
    [10:51:32] root@ms82:~ # ./mysql_onekey_3.2.1.sh /opt/mysql-8.0.19-linux-glibc2.12-x86_64 3399

    ##ms82
    [10:51:39] root@ms82:~ #  mysql -S /data/mysql/mysql3399/tmp/mysql.sock

    mysql> set global super_read_only=0;
    Query OK, 0 rows affected (0.00 sec)

    mysql>  create user 'rep'@'192.168.188.%' identified by 'rep';
    Query OK, 0 rows affected (0.02 sec)

    mysql>  grant replication slave on *.* to 'rep'@'192.168.188.%';
    Query OK, 0 rows affected (0.02 sec)

    mysql> create user 'proxy'@'192.168.188.%' identified with mysql_native_password by 'proxy';
    Query OK, 0 rows affected (0.01 sec)

    mysql> grant replication client on *.* to 'proxy'@'192.168.188.%';
    Query OK, 0 rows affected (0.01 sec)

    mysql> create user 'monitor'@'192.168.188.%' identified with mysql_native_password by 'monitor';
    Query OK, 0 rows affected (0.01 sec)

    mysql> grant replication client on *.*  to 'monitor'@'192.168.188.%';
    Query OK, 0 rows affected (0.01 sec)

    mysql> install plugin rpl_semi_sync_master soname 'semisync_master.so';
    Query OK, 0 rows affected (0.01 sec)

    mysql> install plugin rpl_semi_sync_slave soname 'semisync_slave.so';
    Query OK, 0 rows affected (0.01 sec)

    mysql> set global  rpl_semi_sync_slave_enabled =1;
    Query OK, 0 rows affected (0.00 sec)

    mysql>  show global variables like '%semi%';
    +-------------------------------------------+------------+
    | Variable_name                             | Value      |
    +-------------------------------------------+------------+
    | rpl_semi_sync_master_enabled              | OFF        |
    | rpl_semi_sync_master_timeout              | 10000      |
    | rpl_semi_sync_master_trace_level          | 32         |
    | rpl_semi_sync_master_wait_for_slave_count | 1          |
    | rpl_semi_sync_master_wait_no_slave        | ON         |
    | rpl_semi_sync_master_wait_point           | AFTER_SYNC |
    | rpl_semi_sync_slave_enabled               | ON         |
    | rpl_semi_sync_slave_trace_level           | 32         |
    +-------------------------------------------+------------+
    8 rows in set (0.00 sec)

    mysql> reset master;
    Query OK, 0 rows affected (0.03 sec)

    mysql> change master to master_host='192.168.188.81',master_port=3399,master_user='rep',master_password='rep',master_auto_position=1,get_master_public_key=1;
    Query OK, 0 rows affected, 2 warnings (0.07 sec)

    mysql> start slave;
    Query OK, 0 rows affected (0.03 sec)


    ```

- ms83 配置环境  
    ``` shell
    [10:51:35] root@ms83:~ # ./mysql_onekey_3.2.1.sh /opt/mysql-8.0.19-linux-glibc2.12-x86_64 3399

    ##ms83  
    同ms82一样，略。
    ```

- master 查看状态  
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

# 配置ProxySQL  
- 安装  
    ```
    [11:08:20] root@ms84:/ofiles # yum localinstall -y proxysql-2.0.11-1-centos7.x86_64.rpm
    [11:19:53] root@ms84:/ofiles # rpm -ql proxysql
    /etc/logrotate.d/proxysql
    /etc/proxysql.cnf
    /etc/systemd/system/proxysql-initial.service
    /etc/systemd/system/proxysql.service
    /usr/bin/proxysql
    /usr/share/proxysql/tools/proxysql_galera_checker.sh
    /usr/share/proxysql/tools/proxysql_galera_writer.pl
    ```
- 启动服务  
    由于在docker运行，无法使用systemctl，所以在这里查看一下service文件，找到命令行，手动执行。  
    ``` shell
    [11:21:16] root@ms84:/ofiles # cat /etc/systemd/system/proxysql.service
    ...
    ...
    [Service]
    Type=forking
    RuntimeDirectory=proxysql
    #PermissionsStartOnly=true
    #ExecStartPre=/usr/bin/mkdir -p /var/run/proxysql /var/run/proxysql
    #ExecStartPre=/usr/bin/chown -R proxysql: /var/run/proxysql/
    ExecStart=/usr/bin/proxysql --idle-threads -c /etc/proxysql.cnf
    PIDFile=/var/lib/proxysql/proxysql.pid
    #StandardError=null  # all output is in stderr
    SyslogIdentifier=proxysql
    Restart=no
    User=proxysql
    Group=proxysql
    ...
    ...

    [11:23:25] root@ms84:/ofiles # /usr/bin/proxysql --idle-threads -c /etc/proxysql.cnf
    2020-05-19 11:23:26 [INFO] Using config file /etc/proxysql.cnf
    2020-05-19 11:23:26 [INFO] Using OpenSSL version: OpenSSL 1.1.1d  10 Sep 2019
    2020-05-19 11:23:26 [INFO] No SSL keys/certificates found in datadir (/var/lib/proxysql). Generating new keys/certificates.

    [11:23:26] root@ms84:/ofiles # ps -ef
    UID        PID  PPID  C STIME TTY          TIME CMD
    root         1     0  0 10:38 ?        00:00:00 /usr/sbin/sshd -D
    root         6     1  0 10:38 ?        00:00:00 sshd: root@pts/0
    root         8     6  0 10:38 pts/0    00:00:00 -zsh
    root       338     1  0 11:23 ?        00:00:00 /usr/bin/proxysql --idle-threads -c /etc/proxysql.cnf
    root       339   338  3 11:23 ?        00:00:00 /usr/bin/proxysql --idle-threads -c /etc/proxysql.cnf
    root       368     8  0 11:23 pts/0    00:00:00 ps -ef

    [11:23:40] root@ms84:/ofiles # ss -antulp|grep proxy
    tcp    LISTEN     0  128  *:6032    *:*     users:(("proxysql",pid=339,fd=40))
    tcp    LISTEN     0  128  *:6033    *:*     users:(("proxysql",pid=339,fd=36))
    tcp    LISTEN     0  128  *:6033    *:*     users:(("proxysql",pid=339,fd=35))
    tcp    LISTEN     0  128  *:6033    *:*     users:(("proxysql",pid=339,fd=34))
    tcp    LISTEN     0  128  *:6033    *:*     users:(("proxysql",pid=339,fd=32))

    ```

- 配置ProxySQL  
    - 通过管理端口登录ProxySQL的sqlite  
        ``` shell
        [11:23:48] root@ms84:/ofiles # mysql -h 127.0.0.1 -P 6032 -uadmin -padmin
        ```
    - 查看一下sqlite的结构  
        ``` shell
        mysql> show tables;
        +----------------------------------------------------+
        | tables                                             |
        +----------------------------------------------------+
        | global_variables                                   |
        | mysql_aws_aurora_hostgroups                        |
        | mysql_collations                                   |
        | mysql_firewall_whitelist_rules                     |
        | mysql_firewall_whitelist_sqli_fingerprints         |
        | mysql_firewall_whitelist_users                     |
        | mysql_galera_hostgroups                            |
        | mysql_group_replication_hostgroups                 |
        | mysql_query_rules                                  |
        | mysql_query_rules_fast_routing                     |
        | mysql_replication_hostgroups                       |
        | mysql_servers                                      |
        | mysql_users                                        |
        | proxysql_servers                                   |
        | restapi_routes                                     |
        | runtime_checksums_values                           |
        | runtime_global_variables                           |
        | runtime_mysql_aws_aurora_hostgroups                |
        | runtime_mysql_firewall_whitelist_rules             |
        | runtime_mysql_firewall_whitelist_sqli_fingerprints |
        | runtime_mysql_firewall_whitelist_users             |
        | runtime_mysql_galera_hostgroups                    |
        | runtime_mysql_group_replication_hostgroups         |
        | runtime_mysql_query_rules                          |
        | runtime_mysql_query_rules_fast_routing             |
        | runtime_mysql_replication_hostgroups               |
        | runtime_mysql_servers                              |
        | runtime_mysql_users                                |
        | runtime_proxysql_servers                           |
        | runtime_restapi_routes                             |
        | runtime_scheduler                                  |
        | scheduler                                          |
        +----------------------------------------------------+
        32 rows in set (0.00 sec)

        mysql> select database();
        +------------+
        | DATABASE() |
        +------------+
        | admin      |
        +------------+
        1 row in set (0.00 sec)

        mysql> show databases;
        +-----+---------------+-------------------------------------+
        | seq | name          | file                                |
        +-----+---------------+-------------------------------------+
        | 0   | main          |                                     |
        | 2   | disk          | /var/lib/proxysql/proxysql.db       |
        | 3   | stats         |                                     |
        | 4   | monitor       |                                     |
        | 5   | stats_history | /var/lib/proxysql/proxysql_stats.db |
        +-----+---------------+-------------------------------------+
        5 rows in set (0.00 sec)

        ```
    - 配置读写组  
        ``` shell
        mysql> use main;

        mysql> show create table mysql_replication_hostgroups\G
        *************************** 1. row ***************************
            table: mysql_replication_hostgroups
        Create Table: CREATE TABLE mysql_replication_hostgroups (
            writer_hostgroup INT CHECK (writer_hostgroup>=0) NOT NULL PRIMARY KEY,
            reader_hostgroup INT NOT NULL CHECK (reader_hostgroup<>writer_hostgroup AND reader_hostgroup>=0),
            check_type VARCHAR CHECK (LOWER(check_type) IN ('read_only','innodb_read_only','super_read_only','read_only|innodb_read_only','read_only&innodb_read_only')) NOT NULL DEFAULT 'read_only',
            comment VARCHAR NOT NULL DEFAULT '', UNIQUE (reader_hostgroup))
        1 row in set (0.00 sec)

        mysql> insert into mysql_replication_hostgroups(writer_hostgroup, reader_hostgroup,comment) values (100,101,'proxy');
        Query OK, 1 row affected (0.00 sec)

        mysql> select * from mysql_replication_hostgroups;
        +------------------+------------------+------------+---------+
        | writer_hostgroup | reader_hostgroup | check_type | comment |
        +------------------+------------------+------------+---------+
        | 100              | 101              | read_only  | proxy   |
        +------------------+------------------+------------+---------+
        1 row in set (0.00 sec)


        ```
    - 添加成员  
        ```
        mysql> show create table mysql_servers \G
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

        mysql> insert into mysql_servers(hostgroup_id,hostname,port,max_connections) values (101,'192.168.188.82',3399,200);
        Query OK, 1 row affected (0.00 sec)

        mysql> insert into mysql_servers(hostgroup_id,hostname,port,max_connections) values (101,'192.168.188.83',3399,200);
        Query OK, 1 row affected (0.00 sec)

        mysql> mysql> select * from mysql_servers;
        +--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
        | hostgroup_id | hostname       | port | gtid_port | status | weight | compression | max_connections | max_replication_lag | use_ssl | max_latency_ms | comment |
        +--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
        | 100          | 192.168.188.81 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
        | 101          | 192.168.188.82 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
        | 101          | 192.168.188.83 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
        +--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
        3 rows in set (0.00 sec)

        ```
    - 配置ProxySQL User  
        ``` shell
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

        mysql> insert into mysql_users(username,password,default_hostgroup,default_schema,max_connections) values ('proxy','proxy',100,'kk',1000);
        Query OK, 1 row affected (0.00 sec)

        此时查看monitor.mysql_server_ping_log，可以发现已经通了  

        mysql> select * from monitor.mysql_server_ping_log;
        +----------------+------+------------------+----------------------+------------+
        | hostname       | port | time_start_us    | ping_success_time_us | ping_error |
        +----------------+------+------------------+----------------------+------------+
        | 192.168.188.81 | 3399 | 1589859157227913 | 350                  | NULL       |
        | 192.168.188.81 | 3399 | 1589859166912107 | 376                  | NULL       |
        | 192.168.188.82 | 3399 | 1589859167034376 | 415                  | NULL       |
        | 192.168.188.83 | 3399 | 1589859167157356 | 235                  | NULL       |
        | 192.168.188.81 | 3399 | 1589859176911261 | 449                  | NULL       |
        | 192.168.188.82 | 3399 | 1589859177009697 | 565                  | NULL       |
        | 192.168.188.83 | 3399 | 1589859177108172 | 377                  | NULL       |
        | 192.168.188.82 | 3399 | 1589859186911860 | 625                  | NULL       |
        ...
        ...
        +----------------+------+------------------+----------------------+------------+
        154 rows in set (0.00 sec)

        在master和slave上也能看到monitor@ms84连接信息了  
        
        mysql> show processlist;
        +----+-----------------+-------------------+------+------------------+------+---------------------------------------------------------------+------------------+
        | Id | User            | Host              | db   | Command          | Time | State                                                         | Info             |
        +----+-----------------+-------------------+------+------------------+------+---------------------------------------------------------------+------------------+
        |  4 | event_scheduler | localhost         | NULL | Daemon           | 3071 | Waiting on empty queue                                        | NULL             |
        |  8 | root            | localhost         | NULL | Query            |    0 | starting                                                      | show processlist |
        |  9 | rep             | ms82.net188:52954 | NULL | Binlog Dump GTID | 2289 | Master has sent all binlog to slave; waiting for more updates | NULL             |
        | 10 | rep             | ms83.net188:43038 | NULL | Binlog Dump GTID | 2158 | Master has sent all binlog to slave; waiting for more updates | NULL             |
        | 11 | monitor         | ms84.net188:55902 | NULL | Sleep            |    6 |                                                               | NULL             |
        +----+-----------------+-------------------+------+------------------+------+---------------------------------------------------------------+------------------+
        5 rows in set (0.00 sec)

        这一步要注意，mysql_users里的用户，是通过ProxySQL登录的用户，对应的在MySQL层面，也要配置相应的权限，做到前后端一致。  
        mysql> grant all privileges on kk.* to 'proxy'@'192.168.188.%';
        Query OK, 0 rows affected (0.02 sec)

        ```


- 加载配置到runtime  
    ``` shell
    mysql> load mysql users to run;
    Query OK, 0 rows affected (0.00 sec)

    mysql> load mysql servers to run;
    Query OK, 0 rows affected (0.00 sec)

    mysql> load mysql variables to run;
    Query OK, 0 rows affected (0.00 sec)

    mysql> save mysql users to disk;
    Query OK, 0 rows affected (0.02 sec)

    mysql> save mysql servers to disk;
    Query OK, 0 rows affected (0.11 sec)

    mysql> save mysql variables to disk;
    Query OK, 152 rows affected (0.03 sec)

    ```
- 读写组的切换实践  
    - 此时查看mysql servers，会发现三个节点的Hg都变成了101  
        因为三个节点都是read_only=1，monitor发现状态后，根据mysql_replication_hostgroups 读写组的配置规则，检测read_only的状态后，将变更到只读组。  
        ``` shell
        mysql> select * from mysql_servers;
        +--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
        | hostgroup_id | hostname       | port | gtid_port | status | weight | compression | max_connections | max_replication_lag | use_ssl | max_latency_ms | comment |
        +--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
        | 101          | 192.168.188.81 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
        | 101          | 192.168.188.83 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
        | 101          | 192.168.188.82 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
        +--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
        3 rows in set (0.00 sec)
        ```

    - 将master节点改为读写，然后去ProxySQL查看mysql servers表  
        可以看到，随着master节点转为读写模式，ProxySQL检测到状态变更后，自动将ms81加入到读写组101。  
        ``` shell
        master：mysql> set global read_only=0;
        Query OK, 0 rows affected (0.00 sec)

        mysql> select * from mysql_servers;
        +--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
        | hostgroup_id | hostname       | port | gtid_port | status | weight | compression | max_connections | max_replication_lag | use_ssl | max_latency_ms | comment |
        +--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
        | 101          | 192.168.188.82 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
        | 100          | 192.168.188.81 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
        | 101          | 192.168.188.83 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
        | 101          | 192.168.188.81 | 3399 | 0         | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
        +--------------+----------------+------+-----------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
        4 rows in set (0.01 sec)

        ```
    - 默认的，读写节点也会同时存在于只读组  
        如果想禁止这个特性，可以调整参数后，**重启生效**  
        ``` shell
        #为false则读写节点不会存在于只读组  
        mysql> show variables like '%also%';
        +-------------------------------------+-------+
        | Variable_name                       | Value |
        +-------------------------------------+-------+
        | mysql-monitor_writer_is_also_reader | true  |
        +-------------------------------------+-------+
        1 row in set (0.00 sec)
        ```
    - 用sysbench创建结构  
        ``` shell
        [13:37:29] root@ms84:~ # sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-host=192.168.188.84 --mysql-port=6033 --mysql-user=proxy --mysql-password=proxy --db-driver=mysql --mysql-db=kk --table-size=5000 prepare
        sysbench 1.0.17 (using system LuaJIT 2.0.4)

        Creating table 'sbtest1'...
        Inserting 5000 records into 'sbtest1'
        Creating a secondary index on 'sbtest1'...
        [13:37:46] root@ms84:~ # sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-host=192.168.188.84 --mysql-port=6033 --mysql-user=proxy --mysql-password=proxy --db-driver=mysql --mysql-db=kk --table-size=5000 run   
        sysbench 1.0.17 (using system LuaJIT 2.0.4)

        Running the test with following options:
        Number of threads: 1
        Initializing random number generator from current time

        ```
    - 查看ProxySQL  
        可以看到，所有的请求都运行在100组（读写组）  
        ``` shell
        mysql> select hostgroup, digest, digest_text, count_star, first_seen, last_seen from stats.stats_mysql_query_digest;
        +-----------+--------------------+--------------------------------------------------------------------+------------+------------+------------+
        | hostgroup | digest             | digest_text                                                        | count_star | first_seen | last_seen  |
        +-----------+--------------------+--------------------------------------------------------------------+------------+------------+------------+
        | 100       | 0xE52A0A0210634DAC | INSERT INTO sbtest1 (id, k, c, pad) VALUES (?, ?, ?, ?)            | 651        | 1589866799 | 1589866809 |
        | 100       | 0xE365BEB555319B9E | DELETE FROM sbtest1 WHERE id=?                                     | 651        | 1589866799 | 1589866809 |
        | 100       | 0xFB239BC95A23CA36 | UPDATE sbtest1 SET c=? WHERE id=?                                  | 651        | 1589866799 | 1589866809 |
        | 100       | 0xC198E52BCCB481C7 | UPDATE sbtest1 SET k=k+? WHERE id=?                                | 651        | 1589866799 | 1589866809 |
        | 100       | 0xDBF868B2AA296BC5 | SELECT SUM(k) FROM sbtest1 WHERE id BETWEEN ? AND ?                | 651        | 1589866799 | 1589866809 |
        | 100       | 0x290B92FD743826DA | SELECT c FROM sbtest1 WHERE id BETWEEN ? AND ?                     | 651        | 1589866799 | 1589866809 |
        | 100       | 0xC19480748AE79B4B | SELECT DISTINCT c FROM sbtest1 WHERE id BETWEEN ? AND ? ORDER BY c | 651        | 1589866799 | 1589866809 |
        | 100       | 0xBF001A0C13781C1D | SELECT c FROM sbtest1 WHERE id=?                                   | 6501       | 1589866799 | 1589866809 |
        | 100       | 0x695FBF255DBEB0DD | COMMIT                                                             | 651        | 1589866799 | 1589866809 |
        | 100       | 0xAC80A5EA0101522E | SELECT c FROM sbtest1 WHERE id BETWEEN ? AND ? ORDER BY c          | 651        | 1589866799 | 1589866809 |
        | 100       | 0xFAD1519E4760CBDE | BEGIN                                                              | 651        | 1589866799 | 1589866809 |
        +-----------+--------------------+--------------------------------------------------------------------+------------+------------+------------+
        11 rows in set (0.00 sec)

        ```
- 配置读写分离  
    - 先查看一下规则表的表结构  
        ``` shell
        # https://github.com/sysown/proxysql/wiki/Main-(runtime)#mysql_query_rules
        mysql> show create table mysql_query_rules\G
        *************************** 1. row ***************************
            table: mysql_query_rules
        Create Table: CREATE TABLE mysql_query_rules (
            rule_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,    --规则id
            active INT CHECK (active IN (0,1)) NOT NULL DEFAULT 0,  --查询处理模块将仅考虑active = 1的规则，并且仅将active规则加载到运行时。
            username VARCHAR,                                       --匹配用户名的过滤条件。 如果为非NULL，则仅当使用正确的用户名建立连接时，查询才会匹配。
            schemaname VARCHAR,                                     --符合标准名称的过滤条件。 如果为非NULL，则仅当连接使用schemaname作为默认架构时查询才匹配
            flagIN INT CHECK (flagIN >= 0) NOT NULL DEFAULT 0,      --flagIN，flagOUT，应用-这些使我们能够创建一个“规则链”，一个接一个地应用。 输入标志值设置为0，并且仅在开始时考虑flagIN = 0的规则。 当为特定查询找到匹配规则时，将评估flagOUT，如果NOT NULL，则将在flagOUT中使用指定的标志来标记查询。 如果flagOUT与flagIN不同，则查询将退出当前链，并输入具有flagIN作为新输入标志的新规则链。 如果flagOUT与flagIN匹配，则将针对带有该flagIN的第一条规则再次重新评估查询。 直到不再有匹配的规则，或者将apply设置为1时，这才发生（这意味着这是最后一个要应用的规则）
            client_addr VARCHAR,                                    --match traffic from a specific source，匹配特定来源。
            proxy_addr VARCHAR,                                     --match incoming traffic on a specific local IP，匹配特定本地IP的入口。
            proxy_port INT CHECK (proxy_port >= 0 AND proxy_port <= 65535),   --匹配特定本地端口 
            digest VARCHAR,                         --match queries with a specific digest, as returned by stats_mysql_query_digest.digest。
            match_digest VARCHAR,                                   --通过正则表达式匹配digest
            match_pattern VARCHAR,                                  --通过正则表达式匹配sql文本
            negate_match_pattern INT CHECK (negate_match_pattern IN (0,1)) NOT NULL DEFAULT 0, --如果为1，则只有与sql文本不匹配的查询才被视为匹配项。 在与match_pattern或match_digest匹配的正则表达式前面，这充当NOT运算符
            re_modifiers VARCHAR DEFAULT 'CASELESS',                --看起来很复杂的样子。
            flagOUT INT CHECK (flagOUT >= 0), replace_pattern VARCHAR CHECK(CASE WHEN replace_pattern IS NULL THEN 1 WHEN replace_pattern IS NOT NULL AND match_pattern IS NOT NULL THEN 1 ELSE 0 END),
            destination_hostgroup INT DEFAULT NULL,                 --将匹配的查询路由到该主机组。 除非存在已启动的事务，并且已登录的用户将transaction_persistent标志设置为1（请参见mysql_users表），否则将发生这种情况。
            cache_ttl INT CHECK(cache_ttl > 0),                     --the number of milliseconds for which to cache the result of the query. Note: in ProxySQL 1.1 cache_ttl was in seconds
            cache_empty_result INT CHECK (cache_empty_result IN (0,1)) DEFAULT NULL,
            cache_timeout INT CHECK(cache_timeout >= 0),            --
            reconnect INT CHECK (reconnect IN (0,1)) DEFAULT NULL,
            timeout INT UNSIGNED CHECK (timeout >= 0),              --执行匹配或重写查询的最大超时（以毫秒为单位）。 如果查询的运行时间超过特定阈值，则会自动终止该查询。 如果未指定超时，则应用全局变量mysql-default_query_timeout。
            retries INT CHECK (retries>=0 AND retries <=1000),      --在执行查询期间检测到失败的情况下，需要重新执行查询的最大次数。 如果未指定重试，则应用全局变量mysql-query_retries_on_failure
            delay INT UNSIGNED CHECK (delay >=0),                   --延迟查询执行的毫秒数。是一种限制机制和QoS，允许优先处理某些查询而不是其他查询。 该值被添加到适用于所有查询的mysql-default_query_delay全局变量中。 未来版本的ProxySQL将提供更高级的限制机制。
            next_query_flagIN INT UNSIGNED,
            mirror_flagOUT INT UNSIGNED,
            mirror_hostgroup INT UNSIGNED,
            error_msg VARCHAR,
            OK_msg VARCHAR,
            sticky_conn INT CHECK (sticky_conn IN (0,1)),
            multiplex INT CHECK (multiplex IN (0,1,2)),             --如果为0，将禁用多路复用。 如果为1，则在没有其他条件阻止这种情况（例如用户变量或事务）的情况下，可以重新启用Multiplex。 如果为2，则仅对当前查询不禁用多路复用。 请参见Wiki。默认为NULL，因此不修改多路复用策略。
            gtid_from_hostgroup INT UNSIGNED,
            log INT CHECK (log IN (0,1)),
            apply INT CHECK(apply IN (0,1)) NOT NULL DEFAULT 0,  --当设置为1时，在匹配并处理此规则后将不再评估其他查询（注意：此后将不再评估mysql_query_rules_fast_routing规则）
            comment VARCHAR)
        1 row in set (0.00 sec)
        ```
    - 根据sql匹配正则表达式，并加载到runtime  
        ``` shell
        mysql> insert into mysql_query_rules(rule_id,active,match_pattern,destination_hostgroup,apply) values(1,1,'^SELECT.*FOR UPDATE$',100,1);
        Query OK, 1 row affected (0.00 sec)

        mysql> insert into mysql_query_rules(rule_id,active,match_pattern,destination_hostgroup,apply) values(2,1,'^SELECT',101,1);
        Query OK, 1 row affected (0.00 sec)

        mysql> select rule_id,active,match_pattern,destination_hostgroup,apply from mysql_query_rules;
        +---------+--------+----------------------+-----------------------+-------+
        | rule_id | active | match_pattern        | destination_hostgroup | apply |
        +---------+--------+----------------------+-----------------------+-------+
        | 1       | 1      | ^SELECT.*FOR UPDATE$ | 100                   | 1     |
        | 2       | 1      | ^SELECT              | 101                   | 1     |
        +---------+--------+----------------------+-----------------------+-------+
        2 rows in set (0.00 sec)

        mysql> load mysql query rules to run;
        Query OK, 0 rows affected (0.00 sec)

        mysql> save mysql query rules to disk;
        Query OK, 0 rows affected (0.04 sec)
        ```
    - 使用sysbench运行事务，并查看stats.mysql_query_digest  
        ``` shell
        [14:31:03] root@ms84:~ # sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-host=192.168.188.84 --mysql-port=6033 --mysql-user=proxy --mysql-password=proxy --db-driver=mysql --mysql-db=kk --table-size=5000  run            
        sysbench 1.0.17 (using system LuaJIT 2.0.4)

        mysql> select * from stats.stats_mysql_query_digest_reset;
        Empty set (0.00 sec)

        mysql> select hostgroup, digest, digest_text, count_star, first_seen, last_seen from stats.stats_mysql_query_digest;
        +-----------+--------------------+--------------------------------------------------------------------+------------+------------+------------+
        | hostgroup | digest             | digest_text                                                        | count_star | first_seen | last_seen  |
        +-----------+--------------------+--------------------------------------------------------------------+------------+------------+------------+
        | 100       | 0xE52A0A0210634DAC | INSERT INTO sbtest1 (id, k, c, pad) VALUES (?, ?, ?, ?)            | 409        | 1589870243 | 1589870250 |
        | 100       | 0xFB239BC95A23CA36 | UPDATE sbtest1 SET c=? WHERE id=?                                  | 409        | 1589870243 | 1589870250 |
        | 100       | 0xC198E52BCCB481C7 | UPDATE sbtest1 SET k=k+? WHERE id=?                                | 409        | 1589870243 | 1589870250 |
        | 101       | 0xC19480748AE79B4B | SELECT DISTINCT c FROM sbtest1 WHERE id BETWEEN ? AND ? ORDER BY c | 409        | 1589870243 | 1589870250 |
        | 100       | 0xE365BEB555319B9E | DELETE FROM sbtest1 WHERE id=?                                     | 409        | 1589870243 | 1589870250 |
        | 101       | 0xAC80A5EA0101522E | SELECT c FROM sbtest1 WHERE id BETWEEN ? AND ? ORDER BY c          | 409        | 1589870243 | 1589870250 |
        | 101       | 0xDBF868B2AA296BC5 | SELECT SUM(k) FROM sbtest1 WHERE id BETWEEN ? AND ?                | 409        | 1589870243 | 1589870250 |
        | 101       | 0x290B92FD743826DA | SELECT c FROM sbtest1 WHERE id BETWEEN ? AND ?                     | 409        | 1589870243 | 1589870250 |
        | 101       | 0xBF001A0C13781C1D | SELECT c FROM sbtest1 WHERE id=?                                   | 4087       | 1589870243 | 1589870250 |
        | 100       | 0x695FBF255DBEB0DD | COMMIT                                                             | 409        | 1589870243 | 1589870250 |
        | 100       | 0xFAD1519E4760CBDE | BEGIN                                                              | 410        | 1589870243 | 1589870250 |
        +-----------+--------------------+--------------------------------------------------------------------+------------+------------+------------+
        11 rows in set (0.01 sec)


        ```
    - 针对特定SQL进行读写分离规则（生产环境强烈建议使用此模式）  
        因为生产环境业务情况较为固定，SQL类别总体上有一个固定范围。根据业务情况，并不是将所有读写进行分离就是最佳方案，很多时候只许将特定的一些SQL集路由到slave上进行读，而大部分业务还保留在主库。  
        这时便用上了基于digest进行读写分离的规则。一般将特别大事务量的查询，或特别频繁的查询路由到slave上。
       **不过digest是完全正则匹配， 如果出现大小写、多空格等情况，生成的digest是不同的，无法利用上规则**


        比如，上一个实验里，0xBF001A0C13781C1D 这个sql运行了4087次，其它sql都远低于该值。那么我们就为这个sql指定规则。  
        ``` shell
        mysql> insert into mysql_query_rules(rule_id,active,digest,destination_hostgroup,apply) values(3,1,'0xBF001A0C13781C1D',101,1);
        Query OK, 1 row affected (0.00 sec)

        mysql> update mysql_query_rules set active=0 , apply=0 where rule_id in (1,2);
        Query OK, 2 rows affected (0.00 sec)

        mysql> select rule_id,active,digest,destination_hostgroup,apply from mysql_query_rules;
        +---------+--------+--------------------+-----------------------+-------+
        | rule_id | active | digest             | destination_hostgroup | apply |
        +---------+--------+--------------------+-----------------------+-------+
        | 1       | 0      | NULL               | 100                   | 0     |
        | 2       | 0      | NULL               | 101                   | 0     |
        | 3       | 1      | 0xBF001A0C13781C1D | 101                   | 1     |
        +---------+--------+--------------------+-----------------------+-------+
        3 rows in set (0.00 sec)

        mysql> select * from stats.stats_mysql_query_digest_reset;
        Empty set (0.00 sec)

        mysql> load mysql query rules to run;
        Query OK, 0 rows affected (0.00 sec)

        mysql> save mysql query rules to disk;
        Query OK, 0 rows affected (0.04 sec)

        ```
    - 使用sysbench运行事务，并查看stats.mysql_query_digest  
        可以看到，0xBF001A0C13781C1D已经被路由到slave，其它事务不受影响，依然在master进行。  
        ``` shell
        [14:58:57] root@ms84:~ # sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-host=192.168.188.84 --mysql-port=6033 --mysql-user=proxy --mysql-password=proxy --db-driver=mysql --mysql-db=kk --table-size=5000  run

        mysql> select hostgroup, digest, digest_text, count_star, first_seen, last_seen from stats.stats_mysql_query_digest;
        +-----------+--------------------+--------------------------------------------------------------------+------------+------------+------------+
        | hostgroup | digest             | digest_text                                                        | count_star | first_seen | last_seen  |
        +-----------+--------------------+--------------------------------------------------------------------+------------+------------+------------+
        | 100       | 0xE52A0A0210634DAC | INSERT INTO sbtest1 (id, k, c, pad) VALUES (?, ?, ?, ?)            | 653        | 1589871539 | 1589871549 |
        | 100       | 0xE365BEB555319B9E | DELETE FROM sbtest1 WHERE id=?                                     | 653        | 1589871539 | 1589871549 |
        | 100       | 0xFB239BC95A23CA36 | UPDATE sbtest1 SET c=? WHERE id=?                                  | 653        | 1589871539 | 1589871549 |
        | 100       | 0xC198E52BCCB481C7 | UPDATE sbtest1 SET k=k+? WHERE id=?                                | 653        | 1589871539 | 1589871549 |
        | 100       | 0xC19480748AE79B4B | SELECT DISTINCT c FROM sbtest1 WHERE id BETWEEN ? AND ? ORDER BY c | 653        | 1589871539 | 1589871549 |
        | 100       | 0xDBF868B2AA296BC5 | SELECT SUM(k) FROM sbtest1 WHERE id BETWEEN ? AND ?                | 653        | 1589871539 | 1589871549 |
        | 100       | 0x290B92FD743826DA | SELECT c FROM sbtest1 WHERE id BETWEEN ? AND ?                     | 653        | 1589871539 | 1589871549 |
        | 101       | 0xBF001A0C13781C1D | SELECT c FROM sbtest1 WHERE id=?                                   | 6521       | 1589871539 | 1589871549 |
        | 100       | 0x695FBF255DBEB0DD | COMMIT                                                             | 653        | 1589871539 | 1589871549 |
        | 100       | 0xAC80A5EA0101522E | SELECT c FROM sbtest1 WHERE id BETWEEN ? AND ? ORDER BY c          | 653        | 1589871539 | 1589871549 |
        | 100       | 0xFAD1519E4760CBDE | BEGIN                                                              | 653        | 1589871539 | 1589871549 |
        +-----------+--------------------+--------------------------------------------------------------------+------------+------------+------------+
        11 rows in set (0.01 sec)

        ```





