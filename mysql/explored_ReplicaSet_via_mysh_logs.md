# 使用MySQL Shell 创建 ReplicaSet，从 MySH 反向理解原理

## 启动MySQL Shell
- 启动MySH
    ```
    # mysqlsh --log-level=8 --dba-log-sql=2
    ```
- 日志
    ```
    2020-05-25 02:27:50: Debug2: Invoking helper
    2020-05-25 02:27:50: Debug2:   Command line: /opt/mysql-shell-8.0.20-linux-glibc2.12-x86-64bit/bin/mysql-secret-store-login-path version
    2020-05-25 02:27:50: Debug2:   Input: 
    2020-05-25 02:27:50: Debug2:   Output: mysql-secret-store-login-path Ver 8.0.20 for Linux on x86_64 - for MySQL 8.0.20 (MySQL Community Server (GPL))

    Copyright (c) 2018, 2020, Oracle and/or its affiliates. All rights reserved.
    2020-05-25 02:27:50: Debug2:   Exit code: 0
    2020-05-25 02:27:50: Info: Using credential store helper: /opt/mysql-shell-8.0.20-linux-glibc2.12-x86-64bit/bin/mysql-secret-store-login-path
    2020-05-25 02:27:50: Info: Loading startup files...
    2020-05-25 02:27:50: Info: Loading plugins...
    2020-05-25 02:27:50: Info: Pager has been set to 'less'.
    2020-05-25 02:27:50: Debug: Using color mode 2
    2020-05-25 02:27:50: Debug: Using prompt theme file /opt/mysql-shell-8.0.20-linux-glibc2.12-x86-64bit/share/mysqlsh/prompt/prompt_256.json
    ```
## 连接到ms81
- 连接到ms81
    ```
    MySQL  JS > \c mysh@192.168.188.81:3388
    Creating a session to 'mysh@192.168.188.81:3388'
    Fetching schema names for autocompletion... Press ^C to stop.
    Your MySQL connection id is 29
    Server version: 8.0.19 MySQL Community Server - GPL
    No default schema selected; type \use <schema> to set one.
    ```
- 日志
    ```
    2020-05-25 02:30:52: Debug2: Invoking helper
    2020-05-25 02:30:52: Debug2:   Command line: /opt/mysql-shell-8.0.20-linux-glibc2.12-x86-64bit/bin/mysql-secret-store-login-path get
    2020-05-25 02:30:52: Debug2:   Input: {"SecretType":"password","ServerURL":"mysh@192.168.188.81:3388"}
    2020-05-25 02:30:52: Debug2:   Output: {"SecretType":"password","ServerURL":"mysh@192.168.188.81:3388","Secret":"****"}
    2020-05-25 02:30:52: Debug2:   Exit code: 0
    ```
## 创建ReplicaSet
- 创建ReplicaSet
    ```
    MySQL  192.168.188.81:3388 ssl  JS > var sh = dba.createReplicaSet('kk')
    A new replicaset with instance 'ms81:3388' will be created.

    * Checking MySQL instance at ms81:3388

    This instance reports its own address as ms81:3388
    ms81:3388: Instance configuration is suitable.

    * Updating metadata...

    ReplicaSet object successfully created for ms81:3388.
    Use rs.addInstance() to add more asynchronously replicated instances to this replicaset and rs.status() to check its status.
    ```
- 日志
    ```
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    
    #一致性读增强 group_replication_consistency
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'   
    
    #获取地址和端口
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    
    #获取UUID
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: SELECT @@server_uuid
    2020-05-25 02:31:13: Debug: Metadata operations will use ms81:3388
    
    #检查是否存在RS的metadata表
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'

    #查询是不是MGR成员，查询是否是MGR里的在线成员。
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: select count(*) from performance_schema.replication_group_members where MEMBER_ID = @@server_uuid AND MEMBER_STATE IS NOT NULL AND MEMBER_STATE <> 'OFFLINE'
    2020-05-25 02:31:13: Debug: Instance type check: ms81:3388: GR is installed but not active

    #获取OS信息：linux-glibc2.12
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('version_compile_os')
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')

    2020-05-25 02:31:13: Debug: Acquiring EXCLUSIVE lock ('AdminAPI_instance', 'AdminAPI_lock') on ms81:3388.
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: SELECT service_get_write_locks('AdminAPI_instance', 'AdminAPI_lock', 0)
    2020-05-25 02:31:13: Debug: A new replicaset with instance 'ms81:3388' will be created.

    2020-05-25 02:31:13: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:31:13: Debug: * Checking MySQL instance at ms81:3388
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: SELECT @@hostname, @@report_host
    2020-05-25 02:31:13: Debug: Target has report_host=NULL
    2020-05-25 02:31:13: Debug: Target has hostname=ms81
    2020-05-25 02:31:13: Debug: This instance reports its own address as ms81:3388

    #默认为ON，startup时读取mysqld-auto.cnf ，为OFF时跳过对该文件的读取。
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('persisted_globals_load')

    #获取page size
    2020-05-25 02:31:13: Info: Validating InnoDB page size of instance 'ms81:3388'.
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('innodb_page_size')

    #检查P_S是否启用
    2020-05-25 02:31:13: Info: Checking if performance_schema is enabled on instance 'ms81:3388'.
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('performance_schema')

    2020-05-25 02:31:13: Info: Validating configuration of ms81:3388 (mycnf = )
    2020-05-25 02:31:13: Debug: Checking if 'server_id' is compatible.
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:31:13: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('performance_schema')

    #EXPLICIT，MySQL8.0中将很多数据库配置信息都写入了variables_info表中
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SELECT variable_source FROM performance_schema.variables_info WHERE variable_name = 'server_id'
    2020-05-25 02:31:14: Debug: OK: 'server_id' value '813388' is compatible.
    2020-05-25 02:31:14: Debug: Checking if 'log_bin' is compatible.
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('log_bin')
    2020-05-25 02:31:14: Debug: OK: 'log_bin' value 'ON' is compatible.
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('port')
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('slave_parallel_workers')

    #检查binlog format是否满足InnoDB Cluster要求（row）
    2020-05-25 02:31:14: Debug: Checking if 'binlog_format' is compatible with InnoDB Cluster.
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('binlog_format')
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'binlog_format'
    2020-05-25 02:31:14: Debug: OK: 'binlog_format' value 'ROW' is compatible.

    2020-05-25 02:31:14: Debug: Checking if 'log_slave_updates' is compatible with InnoDB Cluster.
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('log_slave_updates')
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'log_slave_updates'
    2020-05-25 02:31:14: Debug: OK: 'log_slave_updates' value 'ON' is compatible.

    2020-05-25 02:31:14: Debug: Checking if 'enforce_gtid_consistency' is compatible with InnoDB Cluster.
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('enforce_gtid_consistency')
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'enforce_gtid_consistency'
    2020-05-25 02:31:14: Debug: OK: 'enforce_gtid_consistency' value 'ON' is compatible.
    2020-05-25 02:31:14: Debug: Checking if 'gtid_mode' is compatible with InnoDB Cluster.
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('gtid_mode')
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'gtid_mode'
    2020-05-25 02:31:14: Debug: OK: 'gtid_mode' value 'ON' is compatible.
    2020-05-25 02:31:14: Debug: Checking if 'master_info_repository' is compatible with InnoDB Cluster.
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('master_info_repository')
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'master_info_repository'
    2020-05-25 02:31:14: Debug: OK: 'master_info_repository' value 'TABLE' is compatible.
    2020-05-25 02:31:14: Debug: Checking if 'relay_log_info_repository' is compatible with InnoDB Cluster.
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('relay_log_info_repository')
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'relay_log_info_repository'
    2020-05-25 02:31:14: Debug: OK: 'relay_log_info_repository' value 'TABLE' is compatible.


    2020-05-25 02:31:14: Debug: Checking if 'report_port' is compatible with InnoDB Cluster.
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('report_port')
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'report_port'
    2020-05-25 02:31:14: Debug: OK: 'report_port' value '3388' is compatible.
    2020-05-25 02:31:14: Debug: Check command returned: {"status": "ok"}


    #查询复制过滤规则？
    2020-05-25 02:31:14: Debug: ms81:3388: Instance configuration is suitable.
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SHOW MASTER STATUS
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SELECT count(*) FROM performance_schema.replication_applier_global_filters WHERE filter_rule <> ''
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SELECT count(*) FROM performance_schema.replication_applier_filters WHERE filter_rule <> ''

    #这段是MGR的判断。判断MGR各节点状态。
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SELECT @@group_replication_group_name group_name,  @@group_replication_single_primary_mode single_primary,  @@server_uuid,  member_state,  (SELECT    sum(IF(member_state in ('ONLINE', 'RECOVERING'), 1, 0)) > sum(1)/2   FROM performance_schema.replication_group_members) has_quorum, COALESCE(/*!80002 member_role = 'PRIMARY', NULL AND */     NOT @@group_replication_single_primary_mode OR     member_id = (select variable_value       from performance_schema.global_status       where variable_name = 'group_replication_primary_member') ) is_primary FROM performance_schema.replication_group_members WHERE member_id = @@server_uuid

    2020-05-25 02:31:14: Info: ms81:3388: -> MySQL Error 1193 (HY000): Unknown system variable 'group_replication_group_name'
    2020-05-25 02:31:14: Error: Error while querying for group_replication info: Unknown system variable 'group_replication_group_name'

    # 查询出各通道的状态，并判断各通道的延迟情况。
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name

    #查询从节点。此时没有结果返回，光杆司令。
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SHOW SLAVE HOSTS
    2020-05-25 02:31:14: Info: Unfencing PRIMARY ms81:3388
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SET PERSIST `SUPER_READ_ONLY` = 'OFF'
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SET PERSIST `READ_ONLY` = 'OFF'
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('server_id')

    #重建rs专用用户
    2020-05-25 02:31:14: Info: Dropping account mysql_innodb_rs_813388@% at ms81:3388
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: DROP USER IF EXISTS 'mysql_innodb_rs_813388'@'%'
    2020-05-25 02:31:14: Info: Creating replication user mysql_innodb_rs_813388@% with random password at ms81:3388
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: CREATE USER IF NOT EXISTS 'mysql_innodb_rs_813388'@'%' IDENTIFIED BY ****
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: GRANT REPLICATION SLAVE ON *.* TO 'mysql_innodb_rs_813388'@'%'
    2020-05-25 02:31:14: Debug: * Updating metadata...

    # 在这里直接查询……然后发现没有metadata表。
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:31:14: Info: ms81:3388: -> MySQL Error 1049 (42000): Unknown database 'mysql_innodb_cluster_metadata'
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: DROP SCHEMA IF EXISTS `mysql_innodb_cluster_metadata`
    2020-05-25 02:31:14: Info: Deploying metadata schema in ms81:3388...
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: CREATE DATABASE IF NOT EXISTS mysql_innodb_cluster_metadata DEFAULT CHARACTER SET utf8mb4
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: USE mysql_innodb_cluster_metadata
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: SET names utf8mb4
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: --  Metadata Schema Version
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: --  -----------------------

    # 创建了个视图
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: /*
    View that holds the current version of the metadata schema.

    PLEASE NOTE:
    During the upgrade process of the metadata schema the schema_version is
    set to 0, 0, 0. This behavior is used for other components to detect a
    schema upgrade process and hold back metadata refreshes during upgrades.
    */
    DROP VIEW IF EXISTS schema_version
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: CREATE SQL SECURITY INVOKER VIEW schema_version (major, minor, patch) AS SELECT 2, 0, 0

    # 创建cluster表
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: --  GR Cluster Tables
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: --  -----------------
    2020-05-25 02:31:14: Info: 192.168.188.81:3388: /*
    Basic information about clusters in general.

    Both InnoDB clusters and replicasets are represented as clusters in
    this table, with different cluster_type values.
    */
    CREATE TABLE IF NOT EXISTS clusters (
    /*
        unique ID used to distinguish the cluster from other clusters
    */
    `cluster_id` CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci,
    /*
        user specified name for the cluster. cluster_name must be unique
    */
    `cluster_name` VARCHAR(40) NOT NULL,
    /*
        Brief description of the cluster.
    */
    `description` TEXT,
    /*
        Cluster options explicitly set by the user from the Shell.
    */
    `options` JSON,
    /*
        Contain attributes assigned to each cluster.
        The attributes can be used to tag the clusters with custom attributes.
        {
        group_replication_group_name: "254616cc-fb47-11e5-aac5"
        }
    */
    `attributes` JSON,
    /*
    Whether this is a GR or AR "cluster" (that is, an InnoDB cluster or an
    Async ReplicaSet).
    */
    `cluster_type` ENUM('gr', 'ar') NOT NULL,
    /*
        Specifies the type of topology of a cluster as last known by the shell.
        This is just a snapshot of the GR configuration and should be automatically
        refreshed by the shell.
    */
    `primary_mode` ENUM('pm', 'mm') NOT NULL DEFAULT 'pm',

    /*
        Default options for Routers.
    */
    `router_options` JSON,

    PRIMARY KEY(cluster_id)
    ) CHARSET = utf8mb4, ROW_FORMAT = DYNAMIC



    # 创建instance表
    2020-05-25 02:31:15: Info: 192.168.188.81:3388: /*
    Managed MySQL server instances and basic information about them.
    */
    CREATE TABLE IF NOT EXISTS instances (
    /*
        The ID of the server instance and is a unique identifier of the server
        instance.
    */
    `instance_id` INT UNSIGNED AUTO_INCREMENT,
    /*
        Cluster ID that the server belongs to.
    */
    `cluster_id` CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    /*
        network address of the host of the instance.
        Taken from @@report_host or @@hostname
    */
    `address` VARCHAR(265) CHARACTER SET ascii COLLATE ascii_general_ci,
    /*
        MySQL generated server_uuid for the instance
    */
    `mysql_server_uuid` CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci
        NOT NULL,
    /*
        Unique, user specified name for the server.
        Default is address:port (must fit at least 255 chars of address + port)
    */
    `instance_name` VARCHAR(265) NOT NULL,
    /*
        A JSON document with the addresses available for the server instance. The
        protocols and addresses are further described in the Protocol section below.
        {
        mysqlClassic: "host.foo.com:3306",
        mysqlX: "host.foo.com:33060",
        grLocal: "host.foo.com:49213"
        }
    */
    `addresses` JSON NOT NULL,
    /*
        Contain attributes assigned to the server and is a JSON data type with
        key-value pair. The attributes can be used to tag the servers with custom
        attributes.
    */
    `attributes` JSON,
    /*
        An optional brief description of the group.
    */
    `description` TEXT,

    PRIMARY KEY(instance_id, cluster_id),
    FOREIGN KEY (cluster_id) REFERENCES clusters(cluster_id)
    ) CHARSET = utf8mb4, ROW_FORMAT = DYNAMIC

    # 创建异步复制集群view表
    2020-05-25 02:31:15: Info: 192.168.188.81:3388: --  AR ReplicaSet Tables
    2020-05-25 02:31:15: Info: 192.168.188.81:3388: --  ---------------------
    2020-05-25 02:31:15: Info: 192.168.188.81:3388: /*
    A "view" of the topology of a replicaset at a given point in time.
    Every time topology of the replicaset changes (added and removed instances
    and failovers), a new record is added here (and in async_cluster_members).

    The most current view will be the one with the highest view_id.

    This table maintains a history of replicaset configurations, but older
    records may get deleted.
    */
    CREATE TABLE IF NOT EXISTS async_cluster_views (
    `cluster_id` CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,

    `view_id` INT UNSIGNED NOT NULL,

    /*
        The type of the glboal topology between clusters.
        Changing the topology_type is not currently supported, so this value
        must always be copied when a view changes.
    */
    `topology_type` ENUM('SINGLE-PRIMARY-TREE'),

    /*
        What caused the view change. Possible values are pre-defined by the shell.
    */
    `view_change_reason` VARCHAR(32) NOT NULL,

    /*
        Timestamp of the change.
    */
    `view_change_time` TIMESTAMP(6) NOT NULL,

    /*
        Information about the cause for a view change.
    */
    `view_change_info` JSON NOT NULL,

    `attributes` JSON NOT NULL,

    PRIMARY KEY (cluster_id, view_id),
    INDEX (view_id),

    FOREIGN KEY (cluster_id)
        REFERENCES clusters (cluster_id)
    ) CHARSET = utf8mb4, ROW_FORMAT = DYNAMIC

    # 创建异步复制成员表
    2020-05-25 02:31:16: Info: 192.168.188.81:3388: /*
    The instances that are part of a given view, along with their replication
    master. The PRIMARY will have a NULL master.
    */
    CREATE TABLE IF NOT EXISTS async_cluster_members (
    `cluster_id` CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,

    `view_id` INT UNSIGNED NOT NULL,

    /*
        Reference to an instance in the instances table.
        This reference may become invalid for older views, for instances that are
        removed from the replicaset.
    */
    `instance_id` INT UNSIGNED NOT NULL,

    /*
        id of the master of this instance. NULL if this is the PRIMARY.
    */
    `master_instance_id` INT UNSIGNED,

    /*
        TRUE if this is the PRIMARY of the replicaset.
    */
    `primary_master` BOOL NOT NULL,

    `attributes` JSON NOT NULL,

    PRIMARY KEY (cluster_id, view_id, instance_id),
    INDEX (view_id),
    INDEX (instance_id),

    FOREIGN KEY (cluster_id, view_id)
        REFERENCES async_cluster_views (cluster_id, view_id)
    ) CHARSET = utf8mb4, ROW_FORMAT = DYNAMIC

    # 创建router表
    2020-05-25 02:31:17: Info: 192.168.188.81:3388: /*
    This table contain a list of all router instances that are tracked by the
    cluster.
    */
    CREATE TABLE IF NOT EXISTS routers (
    /*
        The ID of the router instance and is a unique identifier of the server
        instance.
    */
    `router_id` INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    /*
        A user specified name for an instance of the router.
        Should default to address:port, where port is the RW port for classic
        protocol.
    */
    `router_name` VARCHAR(265) NOT NULL,
    /*
        The product name of the routing component, e.g. 'MySQL Router'
    */
    `product_name` VARCHAR(128) NOT NULL,
    /*
        network address of the host the Router is running on.
    */
    `address` VARCHAR(256) CHARACTER SET ascii COLLATE ascii_general_ci,
    /*
        The version of the router instance. Updated on bootstrap and each startup
        of the router instance. Format: x.y.z, 3 digits for each component.
        Managed by Router.
    */
    `version` VARCHAR(12) DEFAULT NULL,
    /*
        A timestamp updated by the router every hour with the current time. This
        timestamp is used to detect routers that are no longer used or stalled.
        Managed by Router.
    */
    `last_check_in` TIMESTAMP NULL DEFAULT NULL,
    /*
        Router specific custom attributes.
        Managed by Router.
    */
    `attributes` JSON,
    /*
        The ID of the cluster this router instance is routing to.
        (implicit foreign key to avoid trouble when deleting a cluster).
        For backwards compatibility, if NULL, assumes there's a single cluster
        in the metadata.
    */
    `cluster_id` CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci
        DEFAULT NULL,
    /*
        Router instance specific configuration options.
        Managed by Shell.
    */
    `options` JSON DEFAULT NULL,

    UNIQUE KEY (address, router_name)
    ) CHARSET = utf8mb4, ROW_FORMAT = DYNAMIC
    2020-05-25 02:31:17: Info: 192.168.188.81:3388: /*
    This table contains a list of all REST user accounts that are granted
    access to the routers REST interface. These are managed by the shell
    per cluster.
    */
    CREATE TABLE IF NOT EXISTS router_rest_accounts (
    /*
        The ID of the cluster this router account applies to.
        (implicit foreign key to avoid trouble when deleting a cluster).
    */
    `cluster_id` CHAR(36) CHARACTER SET ascii COLLATE ascii_general_ci
        NOT NULL,
    /*
        The name of the user account.
    */
    `user` VARCHAR(256) NOT NULL,
    /*
        The authentication method used.
    */
    `authentication_method` VARCHAR(64) NOT NULL DEFAULT 'modular_crypt_format',
    /*
        The authentication string of the user account. The password is stored
        hashed, salted, multiple-rounds.
    */
    `authentication_string` TEXT CHARACTER SET ascii COLLATE ascii_general_ci
        DEFAULT NULL,
    /*
        A short description of the user account.
    */
    `description` VARCHAR(255) DEFAULT NULL,
    /*
        Stores the users privileges in a JSON document. Example:
        {readPriv: "Y", updatePriv: "N"}
    */
    `privileges` JSON,
    /*
        Additional attributes for the user account
    */
    `attributes` JSON DEFAULT NULL,

    PRIMARY KEY (cluster_id, user)
    ) CHARSET = utf8mb4, ROW_FORMAT = DYNAMIC

    # 创建接口视图
    2020-05-25 02:31:18: Info: 192.168.188.81:3388: --  Public Interface Views
    2020-05-25 02:31:18: Info: 192.168.188.81:3388: --  ----------------------
    2020-05-25 02:31:18: Info: 192.168.188.81:3388: /*
    These views will remain backwards compatible even if the internal schema
    change. No existing columns will have their types changed or removed,
    although new columns may be added in the future.
    */

    DROP VIEW IF EXISTS v2_clusters
    2020-05-25 02:31:18: Info: 192.168.188.81:3388: CREATE SQL SECURITY INVOKER VIEW v2_clusters AS
        SELECT
            c.cluster_type,
            c.primary_mode,
            c.cluster_id,
            c.cluster_name,
            c.router_options
        FROM clusters c
    2020-05-25 02:31:18: Info: 192.168.188.81:3388: DROP VIEW IF EXISTS v2_gr_clusters
    2020-05-25 02:31:18: Info: 192.168.188.81:3388: CREATE SQL SECURITY INVOKER VIEW v2_gr_clusters AS
        SELECT
            c.cluster_type,
            c.primary_mode,
            c.cluster_id as cluster_id,
            c.cluster_name as cluster_name,
            c.attributes->>'$.group_replication_group_name' as group_name,
            c.attributes,
            c.options,
            c.router_options,
            c.description as description,
            NULL as replicated_cluster_id
        FROM clusters c
        WHERE c.cluster_type = 'gr'
    2020-05-25 02:31:18: Info: 192.168.188.81:3388: DROP VIEW IF EXISTS v2_instances
    2020-05-25 02:31:18: Info: 192.168.188.81:3388: CREATE SQL SECURITY INVOKER VIEW v2_instances AS
    SELECT i.instance_id,
            i.cluster_id,
            i.instance_name as label,
            i.mysql_server_uuid,
            i.address,
            i.addresses->>'$.mysqlClassic' as endpoint,
            i.addresses->>'$.mysqlX' as xendpoint,
            i.attributes
    FROM instances i
    2020-05-25 02:31:18: Info: 192.168.188.81:3388: DROP VIEW IF EXISTS v2_ar_clusters
    2020-05-25 02:31:18: Info: 192.168.188.81:3388: CREATE SQL SECURITY INVOKER VIEW v2_ar_clusters AS
        SELECT
            acv.view_id,
            c.cluster_type,
            c.primary_mode,
            acv.topology_type as async_topology_type,
            c.cluster_id,
            c.cluster_name,
            c.attributes,
            c.options,
            c.router_options,
            c.description
        FROM clusters c
        JOIN async_cluster_views acv
        ON c.cluster_id = acv.cluster_id
        WHERE acv.view_id = (SELECT max(view_id)
            FROM async_cluster_views
            WHERE c.cluster_id = cluster_id)
        AND c.cluster_type = 'ar'
    2020-05-25 02:31:18: Info: 192.168.188.81:3388: DROP VIEW IF EXISTS v2_ar_members
    2020-05-25 02:31:18: Info: 192.168.188.81:3388: CREATE SQL SECURITY INVOKER VIEW v2_ar_members AS
    SELECT
            acm.view_id,
            i.cluster_id,
            i.instance_id,
            i.instance_name as label,
            i.mysql_server_uuid as member_id,
            IF(acm.primary_master, 'PRIMARY', 'SECONDARY') as member_role,
            acm.master_instance_id as master_instance_id,
            mi.mysql_server_uuid as master_member_id
    FROM instances i
    LEFT JOIN async_cluster_members acm
        ON acm.cluster_id = i.cluster_id AND acm.instance_id = i.instance_id
    LEFT JOIN instances mi
        ON mi.instance_id = acm.master_instance_id
    WHERE acm.view_id = (SELECT max(view_id)
        FROM async_cluster_views WHERE i.cluster_id = cluster_id)
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: /*
    Returns information about the InnoDB cluster or replicaset the server
    being queried is part of.
    */
    DROP VIEW IF EXISTS v2_this_instance
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: CREATE SQL SECURITY INVOKER VIEW v2_this_instance AS
    SELECT i.cluster_id,
            i.instance_id,
            c.cluster_name,
            c.cluster_type
    FROM v2_instances i
    JOIN clusters c ON i.cluster_id = c.cluster_id
    WHERE i.mysql_server_uuid = (SELECT convert(variable_value using ascii)
        FROM performance_schema.global_variables
        WHERE variable_name = 'server_uuid')
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: /*
    List of registered router instances. New routers will do inserts into this
    VIEW during bootstrap. They will also update the version, last_check_in and
    attributes field during runtime.
    */
    DROP VIEW IF EXISTS v2_routers
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: CREATE SQL SECURITY INVOKER VIEW v2_routers AS
    SELECT r.router_id,
            r.cluster_id,
            r.router_name,
            r.product_name,
            r.address,
            r.version,
            r.last_check_in,
            r.attributes,
            r.options
    FROM routers r
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: /*
    List of REST user accounts that are granted access to the routers REST
    interface. These are managed by the shell per cluster and consumed by the
    router.
    */
    DROP VIEW IF EXISTS v2_router_rest_accounts
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: CREATE SQL SECURITY INVOKER VIEW v2_router_rest_accounts AS
    SELECT a.cluster_id,
            a.user,
            a.authentication_method,
            a.authentication_string,
            a.description,
            a.privileges,
            a.attributes
    FROM router_rest_accounts a

    # 通过查询mysql库，向集群metadata库插入数据。
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: USE mysql
    2020-05-25 02:31:19: Info: Creating replicaset metadata...
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: START TRANSACTION
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: SELECT uuid()

    # ar == asynchronous repilcation，   pm/mm
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: INSERT INTO mysql_innodb_cluster_metadata.clusters (cluster_id, cluster_name, description, cluster_type, primary_mode, attributes) VALUES ('d10f0970-9e2f-11ea-a355-0242c0a8bc51', 'kk', 'Default ReplicaSet', 'ar', 'pm', JSON_OBJECT('adopted', 0))

    2020-05-25 02:31:19: Info: 192.168.188.81:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_views ( cluster_id, view_id, topology_type, view_change_reason, view_change_time, view_change_info, attributes ) VALUES ('d10f0970-9e2f-11ea-a355-0242c0a8bc51', 1, 'SINGLE-PRIMARY-TREE', 'CREATE', NOW(6), JSON_OBJECT('user', USER(),   'source', @@server_uuid),'{}')
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: COMMIT
    2020-05-25 02:31:19: Info: Recording metadata for ms81:3388

    #MGR的动作
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: SELECT @@mysqlx_port
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: show GLOBAL variables where `variable_name` in ('group_replication_local_address')

    2020-05-25 02:31:19: Info: 192.168.188.81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:31:19: Debug: Acquiring EXCLUSIVE lock ('AdminAPI_metadata', 'AdminAPI_lock') on ms81:3388.

    #上写锁，更新instance元数据表，记录mysqlx port
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: SELECT service_get_write_locks('AdminAPI_metadata', 'AdminAPI_lock', 60)
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: START TRANSACTION
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: INSERT INTO mysql_innodb_cluster_metadata.instances (cluster_id, address, mysql_server_uuid, instance_name, addresses, attributes)VALUES ('d10f0970-9e2f-11ea-a355-0242c0a8bc51', 'ms81:3388', 'f1847297-9b2d-11ea-ba52-0242c0a8bc51', 'ms81:3388', json_object('mysqlClassic', 'ms81:3388', 'mysqlX', 'ms81:33060'), '{}')

    #获取最新的view_id。 view_id：每次节点状态变更，view_id+1。
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: SELECT MAX(view_id) FROM mysql_innodb_cluster_metadata.async_cluster_views WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:31:19: Debug: Updating metadata for async cluster ADD_INSTANCE view d10f0970-9e2f-11ea-a355-0242c0a8bc51,2

    #将节点信息写入到异步复制集群视图表。
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_views (cluster_id, view_id, topology_type,  view_change_reason, view_change_time, view_change_info,  attributes) SELECT cluster_id, 2, topology_type, 'ADD_INSTANCE', NOW(6), JSON_OBJECT('user', USER(),   'source', @@server_uuid), attributes FROM mysql_innodb_cluster_metadata.async_cluster_views WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 1

    #将节点信息写入到异步复制成员表
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_members (cluster_id, view_id, instance_id, master_instance_id,    primary_master, attributes) SELECT cluster_id, 2, instance_id, master_instance_id,    primary_master, attributes FROM mysql_innodb_cluster_metadata.async_cluster_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 1


    2020-05-25 02:31:19: Info: 192.168.188.81:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_members ( cluster_id, view_id, instance_id, master_instance_id, primary_master, attributes) VALUES ('d10f0970-9e2f-11ea-a355-0242c0a8bc51', 2, 1, IF(0=0, NULL, 0), 1,    (SELECT JSON_OBJECT('instance.mysql_server_uuid', mysql_server_uuid,       'instance.address', address)     FROM mysql_innodb_cluster_metadata.instances     WHERE instance_id = 1) )

    2020-05-25 02:31:19: Info: 192.168.188.81:3388: COMMIT
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')

    #释放锁
    2020-05-25 02:31:19: Debug: Releasing locks for 'AdminAPI_metadata' on ms81:3388.
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: SELECT service_release_locks('AdminAPI_metadata')

    #更新clusters表
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: UPDATE mysql_innodb_cluster_metadata.clusters SET attributes = json_set(attributes, '$.opt_gtidSetIsComplete', CAST('false' as JSON)) WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')

    2020-05-25 02:31:19: Debug: Releasing locks for 'AdminAPI_instance' on ms81:3388.
    2020-05-25 02:31:19: Info: 192.168.188.81:3388: SELECT service_release_locks('AdminAPI_instance')
    2020-05-25 02:31:19: Debug: ReplicaSet object successfully created for ms81:3388.
    Use rs.addInstance() to add more asynchronously replicated instances to this replicaset and rs.status() to check its status.

    ```
## 查看RS状态
- 查看状态
    ```
    MySQL  192.168.188.81:3388 ssl  JS > sh.status()
    {
        "replicaSet": {
            "name": "kk", 
            "primary": "ms81:3388", 
            "status": "AVAILABLE", 
            "statusText": "All instances available.", 
            "topology": {
                "ms81:3388": {
                    "address": "ms81:3388", 
                    "instanceRole": "PRIMARY", 
                    "mode": "R/W", 
                    "status": "ONLINE"
                }
            }, 
            "type": "ASYNC"
        }
    }
    ```
- 日志
    ```
    2020-05-25 02:32:51: Debug: Refreshing metadata cache
    2020-05-25 02:32:51: Info: 192.168.188.81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:32:51: Info: 192.168.188.81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:32:51: Info: 192.168.188.81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:32:51: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:32:51: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:32:51: Info: 192.168.188.81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`


    2020-05-25 02:32:51: Info: 192.168.188.81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id

    
    2020-05-25 02:32:51: Info: 192.168.188.81:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:32:51: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:32:51: Info: 192.168.188.81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:32:51: Info: 192.168.188.81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:32:51: Info: 192.168.188.81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:32:51: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:32:51: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:32:51: Info: 192.168.188.81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:32:51: Debug: Instance type check: ms81:3388: Metadata version 2.0.0 found
    2020-05-25 02:32:51: Info: 192.168.188.81:3388: select cluster_type from `mysql_innodb_cluster_metadata`.v2_this_instance
    2020-05-25 02:32:51: Debug: Instance type check: ms81:3388: ReplicaSet metadata record found (metadata 2.0.0)
    2020-05-25 02:32:51: Debug: Instance f1847297-9b2d-11ea-ba52-0242c0a8bc51 is managed for ASYNC-REPLICATION
    2020-05-25 02:32:51: Info: 192.168.188.81:3388: select count(*) from performance_schema.replication_group_members where MEMBER_ID = @@server_uuid AND MEMBER_STATE IS NOT NULL AND MEMBER_STATE <> 'OFFLINE'
    2020-05-25 02:32:51: Debug: Instance type check: ms81:3388: GR is installed but not active
    2020-05-25 02:32:51: Info: 192.168.188.81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.mysql_server_uuid = 'f1847297-9b2d-11ea-ba52-0242c0a8bc51'
    2020-05-25 02:32:51: Info: 192.168.188.81:3388: SELECT view_id, member_id FROM  mysql_innodb_cluster_metadata.v2_ar_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND member_role = 'PRIMARY'
    2020-05-25 02:32:51: Info: ms81:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:32:51: Info: ms81:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:32:51: Info: ms81:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:32:51: Info: ms81:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:32:51: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:32:51: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:32:51: Debug: Refreshing metadata cache
    2020-05-25 02:32:51: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:32:51: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:32:51: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:32:51: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:32:51: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:32:51: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:32:51: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:32:51: Info: ms81:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:32:51: Info: Connected to replicaset PRIMARY instance ms81:3388
    2020-05-25 02:32:51: Info: ms81:3388: SELECT view_id, member_id FROM  mysql_innodb_cluster_metadata.v2_ar_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND member_role = 'PRIMARY'
    2020-05-25 02:32:51: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:32:51: Info: ms81:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:32:51: Info: ms81:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:32:51: Info: ms81:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:32:51: Info: ms81:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:32:51: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:32:51: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:32:51: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:32:51: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:32:51: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:32:51: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:32:51: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:32:51: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:32:51: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:32:51: Info: ms81:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c WHERE c.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:32:51: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, am.master_instance_id, am.master_member_id, am.member_role, am.view_id,  i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:32:51: Debug: 1 instances in replicaset kk
    2020-05-25 02:32:51: Debug: Scanning state of replicaset ms81:3388
    2020-05-25 02:32:51: Debug: Connecting to ms81:3388
    2020-05-25 02:32:51: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:32:51: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:32:51: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:32:51: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:32:51: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:32:51: Info: ms81:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:32:51: Info: ms81:3388: SHOW SLAVE HOSTS

    ```
## 添加节点ms82
- 添加节点ms82
    ```
    MySQL  192.168.188.81:3388 ssl  JS > sh.addInstance('mysh@192.168.188.82:3388')
    Adding instance to the replicaset...

    * Performing validation checks

    This instance reports its own address as ms82:3388
    ms82:3388: Instance configuration is suitable.

    * Checking async replication topology...

    * Checking transaction state of the instance...

    WARNING: A GTID set check of the MySQL instance at 'ms82:3388' determined that it contains transactions that do not originate from the replicaset, which must be discarded before it can join the replicaset.

    ms82:3388 has the following errant GTIDs that do not exist in the replicaset:
    f6f42ea6-9b2d-11ea-a229-0242c0a8bc52:1,
    f8825c7a-9b2d-11ea-8956-0242c0a8bc53:6-7

    WARNING: Discarding these extra GTID events can either be done manually or by completely overwriting the state of ms82:3388 with a physical snapshot from an existing replicaset member. To use this method by default, set the 'recoveryMethod' option to 'clone'.

    Having extra GTID events is not expected, and it is recommended to investigate this further and ensure that the data can be removed prior to choosing the clone recovery method.

    Please select a recovery method [C]lone/[A]bort (default Abort): 

    ```
- 日志
    ```
    2020-05-25 02:33:56: Debug: Refreshing metadata cache
    2020-05-25 02:33:56: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:33:56: Info: ms81:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:33:56: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:33:56: Info: 192.168.188.81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:33:56: Info: 192.168.188.81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:33:56: Info: 192.168.188.81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:33:56: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:33:56: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:33:56: Info: 192.168.188.81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:33:56: Debug: Instance type check: ms81:3388: Metadata version 2.0.0 found
    2020-05-25 02:33:56: Info: 192.168.188.81:3388: select cluster_type from `mysql_innodb_cluster_metadata`.v2_this_instance
    2020-05-25 02:33:56: Debug: Instance type check: ms81:3388: ReplicaSet metadata record found (metadata 2.0.0)
    2020-05-25 02:33:56: Debug: Instance f1847297-9b2d-11ea-ba52-0242c0a8bc51 is managed for ASYNC-REPLICATION
    2020-05-25 02:33:56: Info: 192.168.188.81:3388: select count(*) from performance_schema.replication_group_members where MEMBER_ID = @@server_uuid AND MEMBER_STATE IS NOT NULL AND MEMBER_STATE <> 'OFFLINE'
    2020-05-25 02:33:56: Debug: Instance type check: ms81:3388: GR is installed but not active
    2020-05-25 02:33:56: Info: 192.168.188.81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.mysql_server_uuid = 'f1847297-9b2d-11ea-ba52-0242c0a8bc51'
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT @@server_uuid
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('version_compile_os')
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:33:56: Debug: Acquiring EXCLUSIVE lock ('AdminAPI_instance', 'AdminAPI_lock') on ms82:3388.
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT service_get_write_locks('AdminAPI_instance', 'AdminAPI_lock', 0)
    2020-05-25 02:33:56: Info: ms81:3388: SELECT view_id, member_id FROM  mysql_innodb_cluster_metadata.v2_ar_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND member_role = 'PRIMARY'
    2020-05-25 02:33:56: Info: ms81:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:33:56: Info: ms81:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:33:56: Info: ms81:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:33:56: Info: ms81:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:33:56: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:33:56: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:33:56: Debug: Refreshing metadata cache
    2020-05-25 02:33:56: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:33:56: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:33:56: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:33:56: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:33:56: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:33:56: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:33:56: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:33:56: Info: ms81:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:33:56: Info: Connected to replicaset PRIMARY instance ms81:3388
    2020-05-25 02:33:56: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('version_compile_os')
    2020-05-25 02:33:56: Info: ms81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:33:56: Debug: Acquiring SHARED lock ('AdminAPI_instance', 'AdminAPI_lock') on ms81:3388.
    2020-05-25 02:33:56: Info: ms81:3388: SELECT service_get_read_locks('AdminAPI_instance', 'AdminAPI_lock', 0)
    2020-05-25 02:33:56: Info: ms81:3388: SELECT view_id, member_id FROM  mysql_innodb_cluster_metadata.v2_ar_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND member_role = 'PRIMARY'
    2020-05-25 02:33:56: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:33:56: Info: ms81:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:33:56: Info: ms81:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:33:56: Info: ms81:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:33:56: Info: ms81:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:33:56: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:33:56: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:33:56: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:33:56: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:33:56: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:33:56: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:33:56: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:33:56: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:33:56: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:33:56: Info: ms81:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c WHERE c.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:33:56: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, am.master_instance_id, am.master_member_id, am.member_role, am.view_id,  i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:33:56: Debug: 1 instances in replicaset kk
    2020-05-25 02:33:56: Debug: Scanning state of replicaset ms81:3388
    2020-05-25 02:33:56: Debug: Connecting to ms81:3388
    2020-05-25 02:33:56: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:33:56: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:33:56: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:33:56: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:33:56: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:33:56: Info: ms81:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:33:56: Info: ms81:3388: SHOW SLAVE HOSTS
    2020-05-25 02:33:56: Debug: Adding instance to the replicaset...
    2020-05-25 02:33:56: Debug: * Performing validation checks
    2020-05-25 02:33:56: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.mysql_server_uuid = 'f6f42ea6-9b2d-11ea-a229-0242c0a8bc52'
    2020-05-25 02:33:56: Info: Error querying metadata for f6f42ea6-9b2d-11ea-a229-0242c0a8bc52: Metadata for instance f6f42ea6-9b2d-11ea-a229-0242c0a8bc52 not found

    2020-05-25 02:33:56: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT @@hostname, @@report_host
    2020-05-25 02:33:56: Debug: Target has report_host=NULL
    2020-05-25 02:33:56: Debug: Target has hostname=ms82
    2020-05-25 02:33:56: Debug: This instance reports its own address as ms82:3388
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('persisted_globals_load')
    2020-05-25 02:33:56: Info: Validating InnoDB page size of instance 'ms82:3388'.
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('innodb_page_size')
    2020-05-25 02:33:56: Info: Checking if performance_schema is enabled on instance 'ms82:3388'.
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('performance_schema')
    2020-05-25 02:33:56: Info: Validating configuration of ms82:3388 (mycnf = )
    2020-05-25 02:33:56: Debug: Checking if 'server_id' is compatible.
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('performance_schema')
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT variable_source FROM performance_schema.variables_info WHERE variable_name = 'server_id'
    2020-05-25 02:33:56: Debug: OK: 'server_id' value '823388' is compatible.
    2020-05-25 02:33:56: Debug: Checking if 'log_bin' is compatible.
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('log_bin')
    2020-05-25 02:33:56: Debug: OK: 'log_bin' value 'ON' is compatible.
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('port')
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('slave_parallel_workers')
    2020-05-25 02:33:56: Debug: Checking if 'binlog_format' is compatible with InnoDB Cluster.
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('binlog_format')
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'binlog_format'
    2020-05-25 02:33:56: Debug: OK: 'binlog_format' value 'ROW' is compatible.
    2020-05-25 02:33:56: Debug: Checking if 'log_slave_updates' is compatible with InnoDB Cluster.
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('log_slave_updates')
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'log_slave_updates'
    2020-05-25 02:33:56: Debug: OK: 'log_slave_updates' value 'ON' is compatible.
    2020-05-25 02:33:56: Debug: Checking if 'enforce_gtid_consistency' is compatible with InnoDB Cluster.
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('enforce_gtid_consistency')
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'enforce_gtid_consistency'
    2020-05-25 02:33:56: Debug: OK: 'enforce_gtid_consistency' value 'ON' is compatible.
    2020-05-25 02:33:56: Debug: Checking if 'gtid_mode' is compatible with InnoDB Cluster.
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('gtid_mode')
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'gtid_mode'
    2020-05-25 02:33:56: Debug: OK: 'gtid_mode' value 'ON' is compatible.
    2020-05-25 02:33:56: Debug: Checking if 'master_info_repository' is compatible with InnoDB Cluster.
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('master_info_repository')
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'master_info_repository'
    2020-05-25 02:33:56: Debug: OK: 'master_info_repository' value 'TABLE' is compatible.
    2020-05-25 02:33:56: Debug: Checking if 'relay_log_info_repository' is compatible with InnoDB Cluster.
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('relay_log_info_repository')
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'relay_log_info_repository'
    2020-05-25 02:33:56: Debug: OK: 'relay_log_info_repository' value 'TABLE' is compatible.
    2020-05-25 02:33:56: Debug: Checking if 'report_port' is compatible with InnoDB Cluster.
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('report_port')
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'report_port'
    2020-05-25 02:33:56: Debug: OK: 'report_port' value '3388' is compatible.
    2020-05-25 02:33:56: Debug: Check command returned: {"status": "ok"}
    2020-05-25 02:33:56: Debug: ms82:3388: Instance configuration is suitable.
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SHOW MASTER STATUS
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT count(*) FROM performance_schema.replication_applier_global_filters WHERE filter_rule <> ''
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT count(*) FROM performance_schema.replication_applier_filters WHERE filter_rule <> ''
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT @@group_replication_group_name group_name,  @@group_replication_single_primary_mode single_primary,  @@server_uuid,  member_state,  (SELECT    sum(IF(member_state in ('ONLINE', 'RECOVERING'), 1, 0)) > sum(1)/2   FROM performance_schema.replication_group_members) has_quorum, COALESCE(/*!80002 member_role = 'PRIMARY', NULL AND */     NOT @@group_replication_single_primary_mode OR     member_id = (select variable_value       from performance_schema.global_status       where variable_name = 'group_replication_primary_member') ) is_primary FROM performance_schema.replication_group_members WHERE member_id = @@server_uuid
    2020-05-25 02:33:56: Info: ms82:3388: -> MySQL Error 1193 (HY000): Unknown system variable 'group_replication_group_name'
    2020-05-25 02:33:56: Error: Error while querying for group_replication info: Unknown system variable 'group_replication_group_name'
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SHOW SLAVE HOSTS
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT @@server_id
    2020-05-25 02:33:56: Debug: * Checking async replication topology...
    2020-05-25 02:33:56: Info: ACTIVE master cluster is ms81:3388
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    WHERE c.channel_name = ''
    2020-05-25 02:33:56: Debug: * Checking transaction state of the instance...
    2020-05-25 02:33:56: Info: ms81:3388: SELECT attributes->'$.opt_gtidSetIsComplete' FROM mysql_innodb_cluster_metadata.clusters WHERE cluster_id='d10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:33:56: Debug: Checking if instance 'ms82:3388' has the clone plugin installed
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT plugin_status FROM information_schema.plugins WHERE plugin_name = 'clone'
    2020-05-25 02:33:56: Info: 192.168.188.82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:33:56: Info: 192.168.188.81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:33:56: Info: 192.168.188.81:3388: SELECT @@GLOBAL.GTID_PURGED
    2020-05-25 02:33:56: Info: The target instance 'ms82:3388' has not been pre-provisioned (GTID set is empty). The Shell is unable to decide whether replication can completely recover its state.
    2020-05-25 02:33:56: Debug: The safest and most convenient way to provision a new instance is through automatic clone provisioning, which will completely overwrite the state of 'ms82:3388' with a physical snapshot from an existing replicaset member. To use this method by default, set the 'recoveryMethod' option to 'clone'.
    2020-05-25 02:33:56: Warning: It should be safe to rely on replication to incrementally recover the state of the new instance if you are sure all updates ever executed in the replicaset were done with GTIDs enabled, there are no purged transactions and the new instance contains the same GTID set as the replicaset or a subset of it. To use this method by default, set the 'recoveryMethod' option to 'incremental'.

    ```

    ```
    Please select a recovery method [C]lone/[A]bort (default Abort): C
    * Updating topology
    Waiting for clone process of the new member to complete. Press ^C to abort the operation.
    * Waiting for clone to finish...
    NOTE: ms82:3388 is being cloned from ms81:3388
    ** Stage DROP DATA: Completed
    ** Clone Transfer  
        FILE COPY  ############################################################  100%  Completed
        PAGE COPY  ############################################################  100%  Completed
        REDO COPY  ############################################################  100%  Completed
    ** Stage RECOVERY: \
    NOTE: ms82:3388 is shutting down...

    * Waiting for server restart... ready
    * ms82:3388 has restarted, waiting for clone to finish...
    * Clone process has finished: 154.37 MB transferred in 4 sec (38.59 MB/s)

    ** Configuring ms82:3388 to replicate from ms81:3388
    ** Waiting for new instance to synchronize with PRIMARY...

    The instance 'ms82:3388' was added to the replicaset and is replicating from ms81:3388.

    ```
    ```
    2020-05-25 02:35:18: Debug: * Updating topology
    2020-05-25 02:35:18: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:35:18: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:35:18: Info: Dropping account mysql_innodb_rs_823388@% at ms81:3388
    2020-05-25 02:35:18: Info: ms81:3388: DROP USER IF EXISTS 'mysql_innodb_rs_823388'@'%'
    2020-05-25 02:35:18: Info: Creating replication user mysql_innodb_rs_823388@% with random password at ms81:3388
    2020-05-25 02:35:18: Info: ms81:3388: CREATE USER IF NOT EXISTS 'mysql_innodb_rs_823388'@'%' IDENTIFIED BY ****
    2020-05-25 02:35:18: Info: ms81:3388: GRANT REPLICATION SLAVE ON *.* TO 'mysql_innodb_rs_823388'@'%'
    2020-05-25 02:35:18: Info: ms81:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c WHERE c.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:35:18: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, am.master_instance_id, am.master_member_id, am.member_role, am.view_id,  i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:35:18: Debug: 1 instances in replicaset kk
    2020-05-25 02:35:18: Debug: Scanning state of replicaset ms81:3388
    2020-05-25 02:35:18: Debug: Connecting to ms81:3388
    2020-05-25 02:35:18: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:35:18: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:35:18: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:35:18: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:35:18: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:35:18: Info: ms81:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:35:18: Info: ms81:3388: SHOW SLAVE HOSTS
    2020-05-25 02:35:18: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.address = 'ms81:3388'
    2020-05-25 02:35:18: Info: ms81:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c WHERE c.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:35:18: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, am.master_instance_id, am.master_member_id, am.member_role, am.view_id,  i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:35:18: Debug: 1 instances in replicaset kk
    2020-05-25 02:35:18: Debug: Scanning state of replicaset ms81:3388
    2020-05-25 02:35:18: Debug: Connecting to ms81:3388
    2020-05-25 02:35:18: Info: ms81:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:35:18: Info: ms81:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:35:18: Info: ms81:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:35:18: Info: ms81:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:35:18: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:35:18: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:35:18: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:35:18: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:35:18: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:35:18: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:35:18: Info: ms81:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:35:18: Info: ms81:3388: SHOW SLAVE HOSTS
    2020-05-25 02:35:18: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:35:18: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('version_compile_os')
    2020-05-25 02:35:18: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('version_compile_machine')
    2020-05-25 02:35:18: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('version_compile_machine')
    2020-05-25 02:35:18: Info: Installing the clone plugin on donor 'ms81:3388'.
    2020-05-25 02:35:18: Info: ms81:3388: SELECT plugin_status FROM information_schema.plugins WHERE plugin_name = 'clone'
    2020-05-25 02:35:18: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:35:18: Info: Installing the clone plugin on recipient 'ms82:3388'.
    2020-05-25 02:35:18: Info: 192.168.188.82:3388: SELECT plugin_status FROM information_schema.plugins WHERE plugin_name = 'clone'
    2020-05-25 02:35:18: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:35:18: Info: 192.168.188.82:3388: SET GLOBAL `clone_valid_donor_list` = 'ms81:3388'
    2020-05-25 02:35:18: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:35:18: Info: Creating clone recovery user mysql_innodb_rs_823388@% at ms82:3388.
    2020-05-25 02:35:18: Info: 192.168.188.82:3388: SET SESSION sql_log_bin=0
    2020-05-25 02:35:18: Info: 192.168.188.82:3388: CREATE USER IF NOT EXISTS 'mysql_innodb_rs_823388'@'%' IDENTIFIED BY ****
    2020-05-25 02:35:18: Info: 192.168.188.82:3388: GRANT CLONE_ADMIN, EXECUTE ON *.* TO 'mysql_innodb_rs_823388'@'%'
    2020-05-25 02:35:18: Info: 192.168.188.82:3388: GRANT SELECT ON performance_schema.* TO 'mysql_innodb_rs_823388'@'%'
    2020-05-25 02:35:18: Info: 192.168.188.82:3388: SET SESSION sql_log_bin=1
    2020-05-25 02:35:18: Info: ms81:3388: GRANT BACKUP_ADMIN ON *.* TO 'mysql_innodb_rs_823388'@'%'
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: SELECT @@server_uuid
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: SELECT NOW(3)
    2020-05-25 02:35:19: Debug: Waiting for clone process of the new member to complete. Press ^C to abort the operation.
    2020-05-25 02:35:19: Info: Waiting for clone process to start at 192.168.188.82:3388...
    2020-05-25 02:35:19: Debug: Cloning instance 'ms81:3388' into 'ms82:3388'.
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: CLONE INSTANCE FROM 'mysql_innodb_rs_823388'@'ms81':3388 IDENTIFIED BY ****
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: SELECT @@server_uuid
    2020-05-25 02:35:19: Info: ms82:3388 has started
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:19: Debug: * Waiting for clone to finish...
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:19: Info: ms82:3388 is being cloned from ms81:3388
    2020-05-25 02:35:19: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(0, DROP DATA, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:19: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:19: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(0, DROP DATA, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:20: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:20: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:20: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:20: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:20: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:20: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:21: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:21: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:21: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:21: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:21: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:21: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:22: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:22: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:22: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:22: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:22: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:22: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:23: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:23: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:23: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:23: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:23: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:23: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:24: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:24: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:24: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:24: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:24: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:24: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:25: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:25: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:25: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:25: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:25: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:25: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:26: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:26: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:26: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:26: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:26: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:26: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:27: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:27: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:27: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:27: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:27: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:27: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:28: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:28: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:28: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:28: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:28: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:28: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:29: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:29: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:29: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:29: Info: ms82:3388: -> MySQL Error 3707 (HY000): ms82:3388: Restart server failed (mysqld is not managed by supervisor process).
    2020-05-25 02:35:29: Info: Error cloning from instance 'ms81:3388': MySQL Error 3707 (HY000): ms82:3388: Restart server failed (mysqld is not managed by supervisor process).
    2020-05-25 02:35:29: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:29: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:29: Debug2: Clone state=In Progress, elapsed=10, errno=0, error=, stage=(6, RECOVERY, state=Not Started, elapsed=0, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:30: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:30: Info: ms82:3388: -> MySQL Error 1053 (08S01): Server shutdown in progress
    2020-05-25 02:35:30: Info: ms82:3388 is shutting down...
    2020-05-25 02:35:30: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:31: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:32: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:33: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:34: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:35: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:36: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:37: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:38: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:39: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:40: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:41: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:42: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:43: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:44: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:45: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:46: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:47: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:48: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:49: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:50: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:51: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:52: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:53: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:54: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:55: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:56: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
    2020-05-25 02:35:57: Info: 192.168.188.82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:35:57: Info: 192.168.188.82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:35:57: Info: 192.168.188.82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:35:57: Info: 192.168.188.82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:35:57: Info: 192.168.188.82:3388: SELECT @@server_uuid
    2020-05-25 02:35:57: Info: ms82:3388 has started
    2020-05-25 02:35:57: Debug: * ms82:3388 has restarted, waiting for clone to finish...
    2020-05-25 02:35:57: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:35:19.037' ORDER BY id DESC LIMIT 1
    2020-05-25 02:35:57: Info: 192.168.188.82:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:35:57: Debug2: Clone state=Completed, elapsed=32, errno=0, error=, stage=(6, RECOVERY, state=Completed, elapsed=1, begin_time=2020-05-25 10:35:19.038)
    2020-05-25 02:35:57: Debug: * Clone process has finished: 158.21 MB transferred in 4 sec (39.55 MB/s)
    2020-05-25 02:35:57: Info: 192.168.188.82:3388: SELECT 1
    2020-05-25 02:35:57: Info: ms82:3388: -> MySQL Error 2013 (HY000): Lost connection to MySQL server during query
    2020-05-25 02:35:57: Debug: Target instance connection lost: MySQL Error 2013 (HY000): Lost connection to MySQL server during query. Re-establishing a connection.
    2020-05-25 02:35:57: Info: ms81:3388: SELECT 1
    2020-05-25 02:35:57: Info: ms81:3388: REVOKE BACKUP_ADMIN ON *.* FROM 'mysql_innodb_rs_823388'
    2020-05-25 02:35:57: Info: 192.168.188.82:3388: SELECT 1
    2020-05-25 02:35:57: Info: ms81:3388: SELECT 1
    2020-05-25 02:35:57: Info: Stopping channel '' at ms82:3388
    2020-05-25 02:35:57: Debug: Stopping slave channel  for ms82:3388...
    2020-05-25 02:35:57: Info: 192.168.188.82:3388: STOP SLAVE FOR CHANNEL ''
    2020-05-25 02:35:57: Info: 192.168.188.82:3388: SHOW STATUS LIKE 'Slave_open_temp_tables'
    2020-05-25 02:35:57: Info: Resetting slave for channel '' at ms82:3388
    2020-05-25 02:35:57: Debug: Resetting slave ALL channel '' for ms82:3388...
    2020-05-25 02:35:57: Info: 192.168.188.82:3388: RESET SLAVE ALL FOR CHANNEL ''
    2020-05-25 02:35:57: Debug: ** Configuring ms82:3388 to replicate from ms81:3388
    2020-05-25 02:35:57: Info: Setting up async master for channel '' of ms82:3388 to ms81:3388 (user 'mysql_innodb_rs_823388')
    2020-05-25 02:35:57: Info: 192.168.188.82:3388: CHANGE MASTER TO /*!80011 get_master_public_key=1, */ MASTER_HOST=/*(*/ 'ms81' /*)*/, MASTER_PORT=/*(*/ 3388 /*)*/, MASTER_USER='mysql_innodb_rs_823388', MASTER_PASSWORD=****, MASTER_AUTO_POSITION=1 FOR CHANNEL ''
    2020-05-25 02:35:57: Info: Starting replication at ms82:3388 ...
    2020-05-25 02:35:57: Debug: Starting slave channel  for ms82:3388...
    2020-05-25 02:35:57: Info: 192.168.188.82:3388: START SLAVE FOR CHANNEL ''
    2020-05-25 02:35:58: Info: Fencing new instance 'ms82:3388' to prevent updates.
    2020-05-25 02:35:58: Info: 192.168.188.82:3388: SET PERSIST `SUPER_READ_ONLY` = 'ON'
    2020-05-25 02:35:58: Debug: ** Waiting for new instance to synchronize with PRIMARY...
    2020-05-25 02:35:58: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:35:58: Info: 192.168.188.82:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-37', 2)
    2020-05-25 02:35:58: Info: Recording metadata for ms82:3388
    2020-05-25 02:35:58: Info: 192.168.188.82:3388: SELECT @@mysqlx_port
    2020-05-25 02:35:58: Info: 192.168.188.82:3388: show GLOBAL variables where `variable_name` in ('group_replication_local_address')
    2020-05-25 02:35:58: Info: ms81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:35:58: Debug: Acquiring EXCLUSIVE lock ('AdminAPI_metadata', 'AdminAPI_lock') on ms81:3388.
    2020-05-25 02:35:58: Info: ms81:3388: SELECT service_get_write_locks('AdminAPI_metadata', 'AdminAPI_lock', 60)
    2020-05-25 02:35:58: Info: ms81:3388: START TRANSACTION
    2020-05-25 02:35:58: Info: ms81:3388: INSERT INTO mysql_innodb_cluster_metadata.instances (cluster_id, address, mysql_server_uuid, instance_name, addresses, attributes)VALUES ('d10f0970-9e2f-11ea-a355-0242c0a8bc51', 'ms82:3388', 'f6f42ea6-9b2d-11ea-a229-0242c0a8bc52', 'ms82:3388', json_object('mysqlClassic', 'ms82:3388', 'mysqlX', 'ms82:33060'), '{}')
    2020-05-25 02:35:58: Info: ms81:3388: SELECT MAX(view_id) FROM mysql_innodb_cluster_metadata.async_cluster_views WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:35:58: Debug: Updating metadata for async cluster ADD_INSTANCE view d10f0970-9e2f-11ea-a355-0242c0a8bc51,3
    2020-05-25 02:35:58: Info: ms81:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_views (cluster_id, view_id, topology_type,  view_change_reason, view_change_time, view_change_info,  attributes) SELECT cluster_id, 3, topology_type, 'ADD_INSTANCE', NOW(6), JSON_OBJECT('user', USER(),   'source', @@server_uuid), attributes FROM mysql_innodb_cluster_metadata.async_cluster_views WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 2
    2020-05-25 02:35:58: Info: ms81:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_members (cluster_id, view_id, instance_id, master_instance_id,    primary_master, attributes) SELECT cluster_id, 3, instance_id, master_instance_id,    primary_master, attributes FROM mysql_innodb_cluster_metadata.async_cluster_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 2
    2020-05-25 02:35:58: Info: ms81:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_members ( cluster_id, view_id, instance_id, master_instance_id, primary_master, attributes) VALUES ('d10f0970-9e2f-11ea-a355-0242c0a8bc51', 3, 2, IF(1=0, NULL, 1), 0,    (SELECT JSON_OBJECT('instance.mysql_server_uuid', mysql_server_uuid,       'instance.address', address)     FROM mysql_innodb_cluster_metadata.instances     WHERE instance_id = 2) )
    2020-05-25 02:35:58: Info: ms81:3388: COMMIT
    2020-05-25 02:35:58: Info: ms81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:35:58: Debug: Releasing locks for 'AdminAPI_metadata' on ms81:3388.
    2020-05-25 02:35:58: Info: ms81:3388: SELECT service_release_locks('AdminAPI_metadata')
    2020-05-25 02:35:58: Debug: The instance 'ms82:3388' was added to the replicaset and is replicating from ms81:3388.

    2020-05-25 02:35:58: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:35:58: Info: 192.168.188.82:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-38', 2)
    2020-05-25 02:35:59: Info: ms81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:35:59: Debug: Releasing locks for 'AdminAPI_instance' on ms81:3388.
    2020-05-25 02:35:59: Info: ms81:3388: SELECT service_release_locks('AdminAPI_instance')
    2020-05-25 02:35:59: Info: 192.168.188.82:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:35:59: Debug: Releasing locks for 'AdminAPI_instance' on ms82:3388.
    2020-05-25 02:35:59: Info: 192.168.188.82:3388: SELECT service_release_locks('AdminAPI_instance')

    ```
## 查看RS状态
- 查看状态
    ```
    MySQL  192.168.188.81:3388 ssl  JS > sh.status()
    {
        "replicaSet": {
            "name": "kk", 
            "primary": "ms81:3388", 
            "status": "AVAILABLE", 
            "statusText": "All instances available.", 
            "topology": {
                "ms81:3388": {
                    "address": "ms81:3388", 
                    "instanceRole": "PRIMARY", 
                    "mode": "R/W", 
                    "status": "ONLINE"
                }, 
                "ms82:3388": {
                    "address": "ms82:3388", 
                    "instanceRole": "SECONDARY", 
                    "mode": "R/O", 
                    "replication": {
                        "applierStatus": "APPLIED_ALL", 
                        "applierThreadState": "Waiting for an event from Coordinator", 
                        "applierWorkerThreads": 4, 
                        "receiverStatus": "ON", 
                        "receiverThreadState": "Waiting for master to send event", 
                        "replicationLag": null
                    }, 
                    "status": "ONLINE"
                }
            }, 
            "type": "ASYNC"
        }
    }
    ```
- 日志
    ```
    2020-05-25 02:36:57: Debug: Refreshing metadata cache
    2020-05-25 02:36:57: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:36:57: Info: ms81:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:36:57: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:36:57: Info: 192.168.188.81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:36:57: Info: 192.168.188.81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:36:57: Info: 192.168.188.81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:36:57: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:36:57: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:36:57: Info: 192.168.188.81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:36:57: Debug: Instance type check: ms81:3388: Metadata version 2.0.0 found
    2020-05-25 02:36:57: Info: 192.168.188.81:3388: select cluster_type from `mysql_innodb_cluster_metadata`.v2_this_instance
    2020-05-25 02:36:57: Debug: Instance type check: ms81:3388: ReplicaSet metadata record found (metadata 2.0.0)
    2020-05-25 02:36:57: Debug: Instance f1847297-9b2d-11ea-ba52-0242c0a8bc51 is managed for ASYNC-REPLICATION
    2020-05-25 02:36:57: Info: 192.168.188.81:3388: select count(*) from performance_schema.replication_group_members where MEMBER_ID = @@server_uuid AND MEMBER_STATE IS NOT NULL AND MEMBER_STATE <> 'OFFLINE'
    2020-05-25 02:36:57: Debug: Instance type check: ms81:3388: GR is installed but not active
    2020-05-25 02:36:57: Info: 192.168.188.81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.mysql_server_uuid = 'f1847297-9b2d-11ea-ba52-0242c0a8bc51'
    2020-05-25 02:36:57: Info: ms81:3388: SELECT view_id, member_id FROM  mysql_innodb_cluster_metadata.v2_ar_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND member_role = 'PRIMARY'
    2020-05-25 02:36:57: Info: ms81:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:36:57: Info: ms81:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:36:57: Info: ms81:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:36:57: Info: ms81:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:36:57: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:36:57: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:36:57: Debug: Refreshing metadata cache
    2020-05-25 02:36:57: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:36:57: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:36:57: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:36:57: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:36:57: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:36:57: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:36:57: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:36:57: Info: ms81:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:36:57: Info: Connected to replicaset PRIMARY instance ms81:3388
    2020-05-25 02:36:57: Info: ms81:3388: SELECT view_id, member_id FROM  mysql_innodb_cluster_metadata.v2_ar_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND member_role = 'PRIMARY'
    2020-05-25 02:36:57: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:36:57: Info: ms81:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:36:57: Info: ms81:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:36:57: Info: ms81:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:36:57: Info: ms81:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:36:57: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:36:57: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:36:57: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:36:57: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:36:57: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:36:57: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:36:57: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:36:57: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:36:57: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:36:57: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:36:57: Info: ms82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:36:57: Info: ms82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:36:57: Info: ms82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:36:57: Info: ms82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:36:57: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:36:57: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:36:57: Info: ms82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:36:57: Info: ms82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:36:57: Info: ms82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:36:57: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:36:57: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:36:57: Info: ms82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:36:57: Info: ms82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:36:57: Info: ms81:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c WHERE c.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:36:57: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, am.master_instance_id, am.master_member_id, am.member_role, am.view_id,  i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:36:57: Debug: 2 instances in replicaset kk
    2020-05-25 02:36:57: Debug: Scanning state of replicaset ms81:3388
    2020-05-25 02:36:57: Debug: Connecting to ms81:3388
    2020-05-25 02:36:57: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:36:57: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:36:57: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:36:57: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:36:57: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:36:57: Info: ms81:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:36:57: Info: ms81:3388: SHOW SLAVE HOSTS
    2020-05-25 02:36:57: Info: ms81:3388 has 1 instances replicating from it
    2020-05-25 02:36:57: Debug: Scanning state of replicaset ms82:3388
    2020-05-25 02:36:57: Debug: Connecting to ms82:3388
    2020-05-25 02:36:57: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:36:57: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:36:57: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:36:57: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:36:57: Info: ms82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:36:57: Info: ms82:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011

    ```
## 添加节点ms83
- 添加节点ms83
    ```
    MySQL  192.168.188.81:3388 ssl  JS > sh.addInstance('mysh@192.168.188.83:3388')

    ```
- 日志
    ```
    2020-05-25 02:37:46: Debug: Refreshing metadata cache
    2020-05-25 02:37:46: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:37:46: Info: ms81:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:37:46: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:37:46: Info: 192.168.188.81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:37:46: Info: 192.168.188.81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:37:46: Info: 192.168.188.81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:37:46: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:37:46: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:37:46: Info: 192.168.188.81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:37:46: Debug: Instance type check: ms81:3388: Metadata version 2.0.0 found
    2020-05-25 02:37:46: Info: 192.168.188.81:3388: select cluster_type from `mysql_innodb_cluster_metadata`.v2_this_instance
    2020-05-25 02:37:46: Debug: Instance type check: ms81:3388: ReplicaSet metadata record found (metadata 2.0.0)
    2020-05-25 02:37:46: Debug: Instance f1847297-9b2d-11ea-ba52-0242c0a8bc51 is managed for ASYNC-REPLICATION
    2020-05-25 02:37:46: Info: 192.168.188.81:3388: select count(*) from performance_schema.replication_group_members where MEMBER_ID = @@server_uuid AND MEMBER_STATE IS NOT NULL AND MEMBER_STATE <> 'OFFLINE'
    2020-05-25 02:37:46: Debug: Instance type check: ms81:3388: GR is installed but not active
    2020-05-25 02:37:46: Info: 192.168.188.81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.mysql_server_uuid = 'f1847297-9b2d-11ea-ba52-0242c0a8bc51'
    2020-05-25 02:37:46: Info: 192.168.188.83:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:37:46: Info: 192.168.188.83:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:37:46: Info: 192.168.188.83:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:37:46: Info: 192.168.188.83:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:37:46: Info: 192.168.188.83:3388: SELECT @@server_uuid
    2020-05-25 02:37:46: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('version_compile_os')
    2020-05-25 02:37:46: Info: 192.168.188.83:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:37:46: Debug: Acquiring EXCLUSIVE lock ('AdminAPI_instance', 'AdminAPI_lock') on ms83:3388.
    2020-05-25 02:37:46: Info: 192.168.188.83:3388: SELECT service_get_write_locks('AdminAPI_instance', 'AdminAPI_lock', 0)
    2020-05-25 02:37:46: Info: ms81:3388: SELECT view_id, member_id FROM  mysql_innodb_cluster_metadata.v2_ar_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND member_role = 'PRIMARY'
    2020-05-25 02:37:47: Info: ms81:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:37:47: Info: ms81:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:37:47: Info: ms81:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:37:47: Info: ms81:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:37:47: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:37:47: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:37:47: Debug: Refreshing metadata cache
    2020-05-25 02:37:47: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:37:47: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:37:47: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:37:47: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:37:47: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:37:47: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:37:47: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:37:47: Info: ms81:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:37:47: Info: Connected to replicaset PRIMARY instance ms81:3388
    2020-05-25 02:37:47: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('version_compile_os')
    2020-05-25 02:37:47: Info: ms81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:37:47: Debug: Acquiring SHARED lock ('AdminAPI_instance', 'AdminAPI_lock') on ms81:3388.
    2020-05-25 02:37:47: Info: ms81:3388: SELECT service_get_read_locks('AdminAPI_instance', 'AdminAPI_lock', 0)
    2020-05-25 02:37:47: Info: ms81:3388: SELECT view_id, member_id FROM  mysql_innodb_cluster_metadata.v2_ar_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND member_role = 'PRIMARY'
    2020-05-25 02:37:47: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:37:47: Info: ms81:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:37:47: Info: ms81:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:37:47: Info: ms81:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:37:47: Info: ms81:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:37:47: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:37:47: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:37:47: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:37:47: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:37:47: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:37:47: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:37:47: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:37:47: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:37:47: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:37:47: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:37:47: Info: ms82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:37:47: Info: ms82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:37:47: Info: ms82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:37:47: Info: ms82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:37:47: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:37:47: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:37:47: Info: ms82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:37:47: Info: ms82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:37:47: Info: ms82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:37:47: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:37:47: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:37:47: Info: ms82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:37:47: Info: ms82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:37:47: Info: ms81:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c WHERE c.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:37:47: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, am.master_instance_id, am.master_member_id, am.member_role, am.view_id,  i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:37:47: Debug: 2 instances in replicaset kk
    2020-05-25 02:37:47: Debug: Scanning state of replicaset ms81:3388
    2020-05-25 02:37:47: Debug: Connecting to ms81:3388
    2020-05-25 02:37:47: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:37:47: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:37:47: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:37:47: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:37:47: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:37:47: Info: ms81:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:37:47: Info: ms81:3388: SHOW SLAVE HOSTS
    2020-05-25 02:37:47: Info: ms81:3388 has 1 instances replicating from it
    2020-05-25 02:37:47: Debug: Scanning state of replicaset ms82:3388
    2020-05-25 02:37:47: Debug: Connecting to ms82:3388
    2020-05-25 02:37:47: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:37:47: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:37:47: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:37:47: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:37:47: Info: ms82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:37:47: Info: ms82:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:37:47: Info: channel '' at ms82:3388 with source_uuid: f1847297-9b2d-11ea-ba52-0242c0a8bc51, master ms81:3388 (running)
    2020-05-25 02:37:47: Info: ms82:3388: SELECT * FROM mysql.slave_master_info WHERE channel_name = ''
    2020-05-25 02:37:47: Info: ms82:3388: SELECT * FROM mysql.slave_relay_log_info WHERE channel_name = ''
    2020-05-25 02:37:47: Info: ms82:3388: SHOW SLAVE HOSTS
    2020-05-25 02:37:47: Debug: Adding instance to the replicaset...
    2020-05-25 02:37:47: Debug: * Performing validation checks
    2020-05-25 02:37:47: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.mysql_server_uuid = 'f8825c7a-9b2d-11ea-8956-0242c0a8bc53'
    2020-05-25 02:37:47: Info: Error querying metadata for f8825c7a-9b2d-11ea-8956-0242c0a8bc53: Metadata for instance f8825c7a-9b2d-11ea-8956-0242c0a8bc53 not found

    2020-05-25 02:37:47: Debug: Metadata operations will use ms83:3388
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SELECT @@hostname, @@report_host
    2020-05-25 02:37:47: Debug: Target has report_host=NULL
    2020-05-25 02:37:47: Debug: Target has hostname=ms83
    2020-05-25 02:37:47: Debug: This instance reports its own address as ms83:3388
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('persisted_globals_load')
    2020-05-25 02:37:47: Info: Validating InnoDB page size of instance 'ms83:3388'.
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('innodb_page_size')
    2020-05-25 02:37:47: Info: Checking if performance_schema is enabled on instance 'ms83:3388'.
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('performance_schema')
    2020-05-25 02:37:47: Info: Validating configuration of ms83:3388 (mycnf = )
    2020-05-25 02:37:47: Debug: Checking if 'server_id' is compatible.
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('performance_schema')
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SELECT variable_source FROM performance_schema.variables_info WHERE variable_name = 'server_id'
    2020-05-25 02:37:47: Debug: OK: 'server_id' value '833388' is compatible.
    2020-05-25 02:37:47: Debug: Checking if 'log_bin' is compatible.
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('log_bin')
    2020-05-25 02:37:47: Debug: OK: 'log_bin' value 'ON' is compatible.
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('port')
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('slave_parallel_workers')
    2020-05-25 02:37:47: Debug: Checking if 'binlog_format' is compatible with InnoDB Cluster.
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('binlog_format')
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'binlog_format'
    2020-05-25 02:37:47: Debug: OK: 'binlog_format' value 'ROW' is compatible.
    2020-05-25 02:37:47: Debug: Checking if 'log_slave_updates' is compatible with InnoDB Cluster.
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('log_slave_updates')
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'log_slave_updates'
    2020-05-25 02:37:47: Debug: OK: 'log_slave_updates' value 'ON' is compatible.
    2020-05-25 02:37:47: Debug: Checking if 'enforce_gtid_consistency' is compatible with InnoDB Cluster.
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('enforce_gtid_consistency')
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'enforce_gtid_consistency'
    2020-05-25 02:37:47: Debug: OK: 'enforce_gtid_consistency' value 'ON' is compatible.
    2020-05-25 02:37:47: Debug: Checking if 'gtid_mode' is compatible with InnoDB Cluster.
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('gtid_mode')
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'gtid_mode'
    2020-05-25 02:37:47: Debug: OK: 'gtid_mode' value 'ON' is compatible.
    2020-05-25 02:37:47: Debug: Checking if 'master_info_repository' is compatible with InnoDB Cluster.
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('master_info_repository')
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'master_info_repository'
    2020-05-25 02:37:47: Debug: OK: 'master_info_repository' value 'TABLE' is compatible.
    2020-05-25 02:37:47: Debug: Checking if 'relay_log_info_repository' is compatible with InnoDB Cluster.
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('relay_log_info_repository')
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'relay_log_info_repository'
    2020-05-25 02:37:47: Debug: OK: 'relay_log_info_repository' value 'TABLE' is compatible.
    2020-05-25 02:37:47: Debug: Checking if 'report_port' is compatible with InnoDB Cluster.
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('report_port')
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SELECT variable_value FROM performance_schema.persisted_variables WHERE variable_name = 'report_port'
    2020-05-25 02:37:47: Debug: OK: 'report_port' value '3388' is compatible.
    2020-05-25 02:37:47: Debug: Check command returned: {"status": "ok"}
    2020-05-25 02:37:47: Debug: ms83:3388: Instance configuration is suitable.
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SHOW MASTER STATUS
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SELECT count(*) FROM performance_schema.replication_applier_global_filters WHERE filter_rule <> ''
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SELECT count(*) FROM performance_schema.replication_applier_filters WHERE filter_rule <> ''
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SELECT @@group_replication_group_name group_name,  @@group_replication_single_primary_mode single_primary,  @@server_uuid,  member_state,  (SELECT    sum(IF(member_state in ('ONLINE', 'RECOVERING'), 1, 0)) > sum(1)/2   FROM performance_schema.replication_group_members) has_quorum, COALESCE(/*!80002 member_role = 'PRIMARY', NULL AND */     NOT @@group_replication_single_primary_mode OR     member_id = (select variable_value       from performance_schema.global_status       where variable_name = 'group_replication_primary_member') ) is_primary FROM performance_schema.replication_group_members WHERE member_id = @@server_uuid
    2020-05-25 02:37:47: Info: ms83:3388: -> MySQL Error 1193 (HY000): Unknown system variable 'group_replication_group_name'
    2020-05-25 02:37:47: Error: Error while querying for group_replication info: Unknown system variable 'group_replication_group_name'
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SHOW SLAVE HOSTS
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SELECT @@server_id
    2020-05-25 02:37:47: Debug: * Checking async replication topology...
    2020-05-25 02:37:47: Info: ACTIVE master cluster is ms81:3388
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    WHERE c.channel_name = ''
    2020-05-25 02:37:47: Debug: * Checking transaction state of the instance...
    2020-05-25 02:37:47: Info: ms81:3388: SELECT attributes->'$.opt_gtidSetIsComplete' FROM mysql_innodb_cluster_metadata.clusters WHERE cluster_id='d10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:37:47: Debug: Checking if instance 'ms83:3388' has the clone plugin installed
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SELECT plugin_status FROM information_schema.plugins WHERE plugin_name = 'clone'
    2020-05-25 02:37:47: Info: 192.168.188.83:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:37:47: Info: 192.168.188.81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:37:47: Info: 192.168.188.81:3388: SELECT @@GLOBAL.GTID_PURGED
    2020-05-25 02:37:47: Info: The target instance 'ms83:3388' has not been pre-provisioned (GTID set is empty). The Shell is unable to decide whether replication can completely recover its state.
    2020-05-25 02:37:47: Debug: The safest and most convenient way to provision a new instance is through automatic clone provisioning, which will completely overwrite the state of 'ms83:3388' with a physical snapshot from an existing replicaset member. To use this method by default, set the 'recoveryMethod' option to 'clone'.
    2020-05-25 02:37:47: Warning: It should be safe to rely on replication to incrementally recover the state of the new instance if you are sure all updates ever executed in the replicaset were done with GTIDs enabled, there are no purged transactions and the new instance contains the same GTID set as the replicaset or a subset of it. To use this method by default, set the 'recoveryMethod' option to 'incremental'.

    ```

    ```
    Please select a recovery method [C]lone/[A]bort (default Abort): C
    * Updating topology
    * Waiting for the donor to synchronize with PRIMARY...

    Waiting for clone process of the new member to complete. Press ^C to abort the operation.
    * Waiting for clone to finish...
    NOTE: ms83:3388 is being cloned from ms82:3388
    ** Stage DROP DATA: Completed
    ** Clone Transfer  
        FILE COPY  ############################################################  100%  Completed
        PAGE COPY  ############################################################  100%  Completed
        REDO COPY  ############################################################  100%  Completed
    ** Stage RECOVERY: |
    NOTE: ms83:3388 is shutting down...

    * Waiting for server restart... ready
    * ms83:3388 has restarted, waiting for clone to finish...
    * Clone process has finished: 154.23 MB transferred in 4 sec (38.56 MB/s)

    ** Configuring ms83:3388 to replicate from ms81:3388
    ** Waiting for new instance to synchronize with PRIMARY...

    The instance 'ms83:3388' was added to the replicaset and is replicating from ms81:3388.

    ```
    ```
    2020-05-25 02:39:15: Debug: * Updating topology
    2020-05-25 02:39:15: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:39:15: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:39:15: Info: Dropping account mysql_innodb_rs_833388@% at ms81:3388
    2020-05-25 02:39:15: Info: ms81:3388: DROP USER IF EXISTS 'mysql_innodb_rs_833388'@'%'
    2020-05-25 02:39:15: Info: Creating replication user mysql_innodb_rs_833388@% with random password at ms81:3388
    2020-05-25 02:39:15: Info: ms81:3388: CREATE USER IF NOT EXISTS 'mysql_innodb_rs_833388'@'%' IDENTIFIED BY ****
    2020-05-25 02:39:16: Info: ms81:3388: GRANT REPLICATION SLAVE ON *.* TO 'mysql_innodb_rs_833388'@'%'
    2020-05-25 02:39:16: Info: ms81:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c WHERE c.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:39:16: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, am.master_instance_id, am.master_member_id, am.member_role, am.view_id,  i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:39:16: Debug: 2 instances in replicaset kk
    2020-05-25 02:39:16: Debug: Scanning state of replicaset ms81:3388
    2020-05-25 02:39:16: Debug: Connecting to ms81:3388
    2020-05-25 02:39:16: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:39:16: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:39:16: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:39:16: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:39:16: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:39:16: Info: ms81:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:39:16: Info: ms81:3388: SHOW SLAVE HOSTS
    2020-05-25 02:39:16: Info: ms81:3388 has 1 instances replicating from it
    2020-05-25 02:39:16: Debug: Scanning state of replicaset ms82:3388
    2020-05-25 02:39:16: Debug: Connecting to ms82:3388
    2020-05-25 02:39:16: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:39:16: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:39:16: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:39:16: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:39:16: Info: ms82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:39:16: Info: ms82:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:39:16: Info: channel '' at ms82:3388 with source_uuid: f1847297-9b2d-11ea-ba52-0242c0a8bc51, master ms81:3388 (running)
    2020-05-25 02:39:16: Info: ms82:3388: SELECT * FROM mysql.slave_master_info WHERE channel_name = ''
    2020-05-25 02:39:16: Info: ms82:3388: SELECT * FROM mysql.slave_relay_log_info WHERE channel_name = ''
    2020-05-25 02:39:16: Info: ms82:3388: SHOW SLAVE HOSTS
    2020-05-25 02:39:16: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.address = 'ms82:3388'
    2020-05-25 02:39:16: Info: ms81:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c WHERE c.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:39:16: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, am.master_instance_id, am.master_member_id, am.member_role, am.view_id,  i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:39:16: Debug: 2 instances in replicaset kk
    2020-05-25 02:39:16: Debug: Scanning state of replicaset ms81:3388
    2020-05-25 02:39:16: Debug: Connecting to ms81:3388
    2020-05-25 02:39:16: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:39:16: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:39:16: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:39:16: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:39:16: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:39:16: Info: ms81:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:39:16: Info: ms81:3388: SHOW SLAVE HOSTS
    2020-05-25 02:39:16: Info: ms81:3388 has 1 instances replicating from it
    2020-05-25 02:39:16: Debug: Scanning state of replicaset ms82:3388
    2020-05-25 02:39:16: Debug: Connecting to ms82:3388
    2020-05-25 02:39:16: Info: ms82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:39:16: Info: ms82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:39:16: Info: ms82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:39:16: Info: ms82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:39:16: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:39:16: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:39:16: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:39:16: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:39:16: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:39:16: Info: ms82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:39:16: Info: ms82:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:39:16: Info: channel '' at ms82:3388 with source_uuid: f1847297-9b2d-11ea-ba52-0242c0a8bc51, master ms81:3388 (running)
    2020-05-25 02:39:16: Info: ms82:3388: SELECT * FROM mysql.slave_master_info WHERE channel_name = ''
    2020-05-25 02:39:16: Info: ms82:3388: SELECT * FROM mysql.slave_relay_log_info WHERE channel_name = ''
    2020-05-25 02:39:16: Info: ms82:3388: SHOW SLAVE HOSTS
    2020-05-25 02:39:16: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:39:16: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('version_compile_os')
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('version_compile_machine')
    2020-05-25 02:39:16: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('version_compile_machine')
    2020-05-25 02:39:16: Info: Installing the clone plugin on donor 'ms82:3388'.
    2020-05-25 02:39:16: Info: ms82:3388: SELECT plugin_status FROM information_schema.plugins WHERE plugin_name = 'clone'
    2020-05-25 02:39:16: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:39:16: Info: Installing the clone plugin on recipient 'ms83:3388'.
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: SELECT plugin_status FROM information_schema.plugins WHERE plugin_name = 'clone'
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: SET GLOBAL `clone_valid_donor_list` = 'ms82:3388'
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:39:16: Info: Creating clone recovery user mysql_innodb_rs_833388@% at ms83:3388.
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: SET SESSION sql_log_bin=0
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: CREATE USER IF NOT EXISTS 'mysql_innodb_rs_833388'@'%' IDENTIFIED BY ****
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: GRANT CLONE_ADMIN, EXECUTE ON *.* TO 'mysql_innodb_rs_833388'@'%'
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: GRANT SELECT ON performance_schema.* TO 'mysql_innodb_rs_833388'@'%'
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: SET SESSION sql_log_bin=1
    2020-05-25 02:39:16: Info: ms81:3388: GRANT BACKUP_ADMIN ON *.* TO 'mysql_innodb_rs_833388'@'%'
    2020-05-25 02:39:16: Debug: * Waiting for the donor to synchronize with PRIMARY...
    2020-05-25 02:39:16: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:39:16: Info: ms82:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-42', 2)
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: SELECT @@server_uuid
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: SELECT NOW(3)
    2020-05-25 02:39:16: Debug: Waiting for clone process of the new member to complete. Press ^C to abort the operation.
    2020-05-25 02:39:16: Info: Waiting for clone process to start at 192.168.188.83:3388...
    2020-05-25 02:39:16: Debug: Cloning instance 'ms82:3388' into 'ms83:3388'.
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: CLONE INSTANCE FROM 'mysql_innodb_rs_833388'@'ms82':3388 IDENTIFIED BY ****
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: SELECT @@server_uuid
    2020-05-25 02:39:16: Info: ms83:3388 has started
    2020-05-25 02:39:16: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:17: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:17: Debug: * Waiting for clone to finish...
    2020-05-25 02:39:17: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:17: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:17: Info: ms83:3388 is being cloned from ms82:3388
    2020-05-25 02:39:17: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(0, DROP DATA, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:17: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:17: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:17: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(0, DROP DATA, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:18: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:18: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:18: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:18: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:18: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:18: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:19: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:19: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:19: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:19: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:19: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:19: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:20: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:20: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:20: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:20: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:20: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:20: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:21: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:21: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:21: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:21: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:21: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:21: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:22: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:22: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:22: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:22: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:22: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:22: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(1, FILE COPY, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:23: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:23: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:23: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:23: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:23: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:23: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:24: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:24: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:24: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:24: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:24: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:24: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:25: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:25: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:25: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:25: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:25: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:25: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:26: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:26: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:26: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:26: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:26: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:26: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:27: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:27: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:27: Debug2: Clone state=In Progress, elapsed=0, errno=0, error=, stage=(4, FILE SYNC, state=In Progress, elapsed=0, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:27: Info: ms83:3388: -> MySQL Error 3707 (HY000): ms83:3388: Restart server failed (mysqld is not managed by supervisor process).
    2020-05-25 02:39:27: Info: Error cloning from instance 'ms82:3388': MySQL Error 3707 (HY000): ms83:3388: Restart server failed (mysqld is not managed by supervisor process).
    2020-05-25 02:39:27: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:27: Info: ms83:3388: -> MySQL Error 1053 (08S01): Server shutdown in progress
    2020-05-25 02:39:27: Info: ms83:3388 is shutting down...
    2020-05-25 02:39:27: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.83' (111)
    2020-05-25 02:39:28: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.83' (111)
    2020-05-25 02:39:29: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.83' (111)
    2020-05-25 02:39:30: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.83' (111)
    2020-05-25 02:39:31: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.83' (111)
    2020-05-25 02:39:32: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.83' (111)
    2020-05-25 02:39:33: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.83' (111)
    2020-05-25 02:39:34: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.83' (111)
    2020-05-25 02:39:35: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.83' (111)
    2020-05-25 02:39:36: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.83' (111)
    2020-05-25 02:39:37: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.83' (111)
    2020-05-25 02:39:38: Debug2: While waiting for server to start: MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.83' (111)
    2020-05-25 02:39:39: Info: 192.168.188.83:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:39:39: Info: 192.168.188.83:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:39:39: Info: 192.168.188.83:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:39:39: Info: 192.168.188.83:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:39:39: Info: 192.168.188.83:3388: SELECT @@server_uuid
    2020-05-25 02:39:39: Info: ms83:3388 has started
    2020-05-25 02:39:39: Debug: * ms83:3388 has restarted, waiting for clone to finish...
    2020-05-25 02:39:39: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_status WHERE begin_time >= '2020-05-25 10:39:16.907' ORDER BY id DESC LIMIT 1
    2020-05-25 02:39:39: Info: 192.168.188.83:3388: SELECT *, end_time-begin_time as elapsed FROM performance_schema.clone_progress WHERE id = 1
    2020-05-25 02:39:39: Debug2: Clone state=Completed, elapsed=17, errno=0, error=, stage=(6, RECOVERY, state=Completed, elapsed=1, begin_time=2020-05-25 10:39:16.908)
    2020-05-25 02:39:39: Debug: ** Stage RESTART: Completed
    2020-05-25 02:39:39: Debug: * Clone process has finished: 158.43 MB transferred in 5 sec (31.69 MB/s)
    2020-05-25 02:39:39: Info: 192.168.188.83:3388: SELECT 1
    2020-05-25 02:39:39: Info: ms83:3388: -> MySQL Error 2013 (HY000): Lost connection to MySQL server during query
    2020-05-25 02:39:39: Debug: Target instance connection lost: MySQL Error 2013 (HY000): Lost connection to MySQL server during query. Re-establishing a connection.
    2020-05-25 02:39:39: Info: ms81:3388: SELECT 1
    2020-05-25 02:39:39: Info: ms81:3388: REVOKE BACKUP_ADMIN ON *.* FROM 'mysql_innodb_rs_833388'
    2020-05-25 02:39:40: Info: 192.168.188.83:3388: SELECT 1
    2020-05-25 02:39:40: Info: ms81:3388: SELECT 1
    2020-05-25 02:39:40: Info: Stopping channel '' at ms83:3388
    2020-05-25 02:39:40: Debug: Stopping slave channel  for ms83:3388...
    2020-05-25 02:39:40: Info: 192.168.188.83:3388: STOP SLAVE FOR CHANNEL ''
    2020-05-25 02:39:40: Info: 192.168.188.83:3388: SHOW STATUS LIKE 'Slave_open_temp_tables'
    2020-05-25 02:39:40: Info: Resetting slave for channel '' at ms83:3388
    2020-05-25 02:39:40: Debug: Resetting slave ALL channel '' for ms83:3388...
    2020-05-25 02:39:40: Info: 192.168.188.83:3388: RESET SLAVE ALL FOR CHANNEL ''
    2020-05-25 02:39:40: Debug: ** Configuring ms83:3388 to replicate from ms81:3388
    2020-05-25 02:39:40: Info: Setting up async master for channel '' of ms83:3388 to ms81:3388 (user 'mysql_innodb_rs_833388')
    2020-05-25 02:39:40: Info: 192.168.188.83:3388: CHANGE MASTER TO /*!80011 get_master_public_key=1, */ MASTER_HOST=/*(*/ 'ms81' /*)*/, MASTER_PORT=/*(*/ 3388 /*)*/, MASTER_USER='mysql_innodb_rs_833388', MASTER_PASSWORD=****, MASTER_AUTO_POSITION=1 FOR CHANNEL ''
    2020-05-25 02:39:41: Info: Starting replication at ms83:3388 ...
    2020-05-25 02:39:41: Debug: Starting slave channel  for ms83:3388...
    2020-05-25 02:39:41: Info: 192.168.188.83:3388: START SLAVE FOR CHANNEL ''
    2020-05-25 02:39:41: Info: Fencing new instance 'ms83:3388' to prevent updates.
    2020-05-25 02:39:41: Info: 192.168.188.83:3388: SET PERSIST `SUPER_READ_ONLY` = 'ON'
    2020-05-25 02:39:41: Debug: ** Waiting for new instance to synchronize with PRIMARY...
    2020-05-25 02:39:41: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:39:41: Info: 192.168.188.83:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-43', 2)
    2020-05-25 02:39:41: Info: Recording metadata for ms83:3388
    2020-05-25 02:39:41: Info: 192.168.188.83:3388: SELECT @@mysqlx_port
    2020-05-25 02:39:41: Info: 192.168.188.83:3388: show GLOBAL variables where `variable_name` in ('group_replication_local_address')
    2020-05-25 02:39:41: Info: ms81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:39:41: Debug: Acquiring EXCLUSIVE lock ('AdminAPI_metadata', 'AdminAPI_lock') on ms81:3388.
    2020-05-25 02:39:41: Info: ms81:3388: SELECT service_get_write_locks('AdminAPI_metadata', 'AdminAPI_lock', 60)
    2020-05-25 02:39:41: Info: ms81:3388: START TRANSACTION
    2020-05-25 02:39:41: Info: ms81:3388: INSERT INTO mysql_innodb_cluster_metadata.instances (cluster_id, address, mysql_server_uuid, instance_name, addresses, attributes)VALUES ('d10f0970-9e2f-11ea-a355-0242c0a8bc51', 'ms83:3388', 'f8825c7a-9b2d-11ea-8956-0242c0a8bc53', 'ms83:3388', json_object('mysqlClassic', 'ms83:3388', 'mysqlX', 'ms83:33060'), '{}')
    2020-05-25 02:39:41: Info: ms81:3388: SELECT MAX(view_id) FROM mysql_innodb_cluster_metadata.async_cluster_views WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:39:41: Debug: Updating metadata for async cluster ADD_INSTANCE view d10f0970-9e2f-11ea-a355-0242c0a8bc51,4
    2020-05-25 02:39:41: Info: ms81:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_views (cluster_id, view_id, topology_type,  view_change_reason, view_change_time, view_change_info,  attributes) SELECT cluster_id, 4, topology_type, 'ADD_INSTANCE', NOW(6), JSON_OBJECT('user', USER(),   'source', @@server_uuid), attributes FROM mysql_innodb_cluster_metadata.async_cluster_views WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 3
    2020-05-25 02:39:41: Info: ms81:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_members (cluster_id, view_id, instance_id, master_instance_id,    primary_master, attributes) SELECT cluster_id, 4, instance_id, master_instance_id,    primary_master, attributes FROM mysql_innodb_cluster_metadata.async_cluster_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 3
    2020-05-25 02:39:41: Info: ms81:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_members ( cluster_id, view_id, instance_id, master_instance_id, primary_master, attributes) VALUES ('d10f0970-9e2f-11ea-a355-0242c0a8bc51', 4, 3, IF(1=0, NULL, 1), 0,    (SELECT JSON_OBJECT('instance.mysql_server_uuid', mysql_server_uuid,       'instance.address', address)     FROM mysql_innodb_cluster_metadata.instances     WHERE instance_id = 3) )
    2020-05-25 02:39:41: Info: ms81:3388: COMMIT
    2020-05-25 02:39:42: Info: ms81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:39:42: Debug: Releasing locks for 'AdminAPI_metadata' on ms81:3388.
    2020-05-25 02:39:42: Info: ms81:3388: SELECT service_release_locks('AdminAPI_metadata')
    2020-05-25 02:39:42: Debug: The instance 'ms83:3388' was added to the replicaset and is replicating from ms81:3388.

    2020-05-25 02:39:42: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:39:42: Info: 192.168.188.83:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44', 2)
    2020-05-25 02:39:42: Info: ms81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:39:42: Debug: Releasing locks for 'AdminAPI_instance' on ms81:3388.
    2020-05-25 02:39:42: Info: ms81:3388: SELECT service_release_locks('AdminAPI_instance')
    2020-05-25 02:39:42: Info: 192.168.188.83:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:39:42: Debug: Releasing locks for 'AdminAPI_instance' on ms83:3388.
    2020-05-25 02:39:42: Info: 192.168.188.83:3388: SELECT service_release_locks('AdminAPI_instance')

    ```
## 将master关掉，查看RS状态
- 将master关掉，查看RS状态
    ```
    master mysql> shutdown;

     MySQL  192.168.188.81:3388 ssl  JS > sh.status()
    ReplicaSet.status: The Metadata is inaccessible (MetadataError)
    ```
- 日志
    ```
    2020-05-25 02:41:57: Debug: Refreshing metadata cache
    2020-05-25 02:41:57: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:41:57: Info: ms81:3388: -> MySQL Error 2013 (HY000): Lost connection to MySQL server during query
    2020-05-25 02:41:57: Warning: While querying metadata: MySQL Error 2013 (HY000): Lost connection to MySQL server during query
    2020-05-25 02:41:57: Debug: ReplicaSet.status: Failed to execute query on Metadata server ms81:3388: Lost connection to MySQL server during query (MySQL Error 2013)
    ```
## 在ms82上尝试createRS ，来了解如何避免重复创建
- mysh重新连接到ms82
    ```
    2020-05-25 02:42:28: Debug2: Invoking helper
    2020-05-25 02:42:28: Debug2:   Command line: /opt/mysql-shell-8.0.20-linux-glibc2.12-x86-64bit/bin/mysql-secret-store-login-path get
    2020-05-25 02:42:28: Debug2:   Input: {"SecretType":"password","ServerURL":"mysh@192.168.188.82:3388"}
    2020-05-25 02:42:28: Debug2:   Output: {"SecretType":"password","ServerURL":"mysh@192.168.188.82:3388","Secret":"****"}
    2020-05-25 02:42:28: Debug2:   Exit code: 0

    ```
- 在ms82上尝试createRS ，来了解如何避免重复创建
    ```
    MySQL  192.168.188.82:3388 ssl  JS > var sh = dba.createReplicaSet('kk')
    Dba.createReplicaSet: Unable to create replicaset. The instance 'ms82:3388' already belongs to a replicaset. Use dba.getReplicaSet() to access it. (MYSQLSH 51306)

    ```
- 日志
    ```
    2020-05-25 02:42:47: Info: 192.168.188.82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:42:47: Info: 192.168.188.82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:42:47: Info: 192.168.188.82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:42:47: Info: 192.168.188.82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:42:47: Info: 192.168.188.82:3388: SELECT @@server_uuid
    2020-05-25 02:42:47: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:42:47: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:42:47: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:42:47: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:42:47: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:42:47: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:42:47: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:42:47: Debug: Instance type check: ms82:3388: Metadata version 2.0.0 found
    2020-05-25 02:42:47: Info: 192.168.188.82:3388: select cluster_type from `mysql_innodb_cluster_metadata`.v2_this_instance
    2020-05-25 02:42:47: Debug: Instance type check: ms82:3388: ReplicaSet metadata record found (metadata 2.0.0)
    2020-05-25 02:42:47: Debug: Instance f6f42ea6-9b2d-11ea-a229-0242c0a8bc52 is managed for ASYNC-REPLICATION
    2020-05-25 02:42:47: Info: 192.168.188.82:3388: select count(*) from performance_schema.replication_group_members where MEMBER_ID = @@server_uuid AND MEMBER_STATE IS NOT NULL AND MEMBER_STATE <> 'OFFLINE'
    2020-05-25 02:42:47: Debug: Instance type check: ms82:3388: GR is installed but not active
    2020-05-25 02:42:47: Info: 192.168.188.82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.mysql_server_uuid = 'f6f42ea6-9b2d-11ea-a229-0242c0a8bc52'
    2020-05-25 02:42:47: Debug: Dba.createReplicaSet: Unable to create replicaset. The instance 'ms82:3388' already belongs to a replicaset. Use dba.getReplicaSet() to access it. (MYSQLSH 51306)

    ```
## ms82上获取RS
- ms82上获取RS
    ```
    MySQL  192.168.188.82:3388 ssl  JS > var sh = dba.getReplicaSet()
    You are connected to a member of replicaset 'kk'.

    ```
- 日志
    ```
    2020-05-25 02:43:14: Info: 192.168.188.82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:43:14: Info: 192.168.188.82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:43:14: Info: 192.168.188.82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:43:14: Info: 192.168.188.82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:43:14: Info: 192.168.188.82:3388: SELECT @@server_uuid
    2020-05-25 02:43:14: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:43:14: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:43:14: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:43:14: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:43:14: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:43:14: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:43:14: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:43:14: Debug: Instance type check: ms82:3388: Metadata version 2.0.0 found
    2020-05-25 02:43:14: Info: 192.168.188.82:3388: select cluster_type from `mysql_innodb_cluster_metadata`.v2_this_instance
    2020-05-25 02:43:14: Debug: Instance type check: ms82:3388: ReplicaSet metadata record found (metadata 2.0.0)
    2020-05-25 02:43:14: Debug: Instance f6f42ea6-9b2d-11ea-a229-0242c0a8bc52 is managed for ASYNC-REPLICATION
    2020-05-25 02:43:14: Info: 192.168.188.82:3388: select count(*) from performance_schema.replication_group_members where MEMBER_ID = @@server_uuid AND MEMBER_STATE IS NOT NULL AND MEMBER_STATE <> 'OFFLINE'
    2020-05-25 02:43:14: Debug: Instance type check: ms82:3388: GR is installed but not active
    2020-05-25 02:43:14: Info: 192.168.188.82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.mysql_server_uuid = 'f6f42ea6-9b2d-11ea-a229-0242c0a8bc52'
    2020-05-25 02:43:14: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:43:14: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:43:14: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:43:14: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:43:14: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:43:14: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:43:14: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:43:14: Info: 192.168.188.82:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c JOIN mysql_innodb_cluster_metadata.`v2_instances` i  ON i.`cluster_id` = `c`.`cluster_id` WHERE i.mysql_server_uuid = 'f6f42ea6-9b2d-11ea-a229-0242c0a8bc52'
    2020-05-25 02:43:14: Debug: You are connected to a member of replicaset 'kk'.

    ```
## 此时查看RS状态（master失联）
- 此时查看RS状态（master失联）
    ```
    MySQL  192.168.188.82:3388 ssl  JS > sh.status()
    ERROR: Unable to connect to the PRIMARY of the replicaset kk: MySQL Error 2003: ms81:3388: Can't connect to MySQL server on 'ms81' (111)
    Cluster change operations will not be possible unless the PRIMARY can be reached.
    If the PRIMARY is unavailable, you must either repair it or perform a forced failover.
    See \help forcePrimaryInstance for more information.
    WARNING: MYSQLSH 51118: PRIMARY instance is unavailable
    {
        "replicaSet": {
            "name": "kk", 
            "primary": "ms81:3388", 
            "status": "UNAVAILABLE", 
            "statusText": "PRIMARY instance is not available, but there is at least one SECONDARY that could be force-promoted.", 
            "topology": {
                "ms81:3388": {
                    "address": "ms81:3388", 
                    "connectError": "ms81:3388: Can't connect to MySQL server on 'ms81' (111)", 
                    "fenced": null, 
                    "instanceRole": "PRIMARY", 
                    "mode": null, 
                    "status": "UNREACHABLE"
                }, 
                "ms82:3388": {
                    "address": "ms82:3388", 
                    "fenced": true, 
                    "instanceErrors": [
                        "ERROR: Replication I/O thread (receiver) has stopped with an error."
                    ], 
                    "instanceRole": "SECONDARY", 
                    "mode": "R/O", 
                    "replication": {
                        "applierStatus": "APPLIED_ALL", 
                        "applierThreadState": "Waiting for an event from Coordinator", 
                        "applierWorkerThreads": 4, 
                        "expectedSource": "ms81:3388", 
                        "receiverLastError": "error reconnecting to master 'mysql_innodb_rs_823388@ms81:3388' - retry-time: 60 retries: 6 message: Can't connect to MySQL server on 'ms81' (111)", 
                        "receiverLastErrorNumber": 2003, 
                        "receiverLastErrorTimestamp": "2020-05-21 16:00:19.547412", 
                        "receiverStatus": "ERROR", 
                        "receiverThreadState": "", 
                        "replicationLag": null, 
                        "source": "ms81:3388"
                    }, 
                    "status": "ERROR", 
                    "transactionSetConsistencyStatus": null
                }, 
                "ms83:3388": {
                    "address": "ms83:3388", 
                    "fenced": true, 
                    "instanceErrors": [
                        "ERROR: Replication I/O thread (receiver) has stopped with an error."
                    ], 
                    "instanceRole": "SECONDARY", 
                    "mode": "R/O", 
                    "replication": {
                        "applierStatus": "APPLIED_ALL", 
                        "applierThreadState": "Waiting for an event from Coordinator", 
                        "applierWorkerThreads": 4, 
                        "expectedSource": "ms81:3388", 
                        "receiverLastError": "error reconnecting to master 'mysql_innodb_rs_833388@ms81:3388' - retry-time: 60 retries: 6 message: Can't connect to MySQL server on 'ms81' (111)", 
                        "receiverLastErrorNumber": 2003, 
                        "receiverLastErrorTimestamp": "2020-05-21 16:00:19.547552", 
                        "receiverStatus": "ERROR", 
                        "receiverThreadState": "", 
                        "replicationLag": null, 
                        "source": "ms81:3388"
                    }, 
                    "status": "ERROR", 
                    "transactionSetConsistencyStatus": null
                }
            }, 
            "type": "ASYNC"
        }
    }
    MySQL  192.168.188.82:3388 ssl  JS > 

    ```
- 日志
    ```
    2020-05-25 02:43:37: Debug: Refreshing metadata cache
    2020-05-25 02:43:37: Info: 192.168.188.82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:43:37: Info: 192.168.188.82:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:43:37: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:43:37: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:43:37: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:43:37: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:43:37: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:43:37: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:43:37: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:43:37: Debug: Instance type check: ms82:3388: Metadata version 2.0.0 found
    2020-05-25 02:43:37: Info: 192.168.188.82:3388: select cluster_type from `mysql_innodb_cluster_metadata`.v2_this_instance
    2020-05-25 02:43:37: Debug: Instance type check: ms82:3388: ReplicaSet metadata record found (metadata 2.0.0)
    2020-05-25 02:43:37: Debug: Instance f6f42ea6-9b2d-11ea-a229-0242c0a8bc52 is managed for ASYNC-REPLICATION
    2020-05-25 02:43:37: Info: 192.168.188.82:3388: select count(*) from performance_schema.replication_group_members where MEMBER_ID = @@server_uuid AND MEMBER_STATE IS NOT NULL AND MEMBER_STATE <> 'OFFLINE'
    2020-05-25 02:43:37: Debug: Instance type check: ms82:3388: GR is installed but not active
    2020-05-25 02:43:37: Info: 192.168.188.82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.mysql_server_uuid = 'f6f42ea6-9b2d-11ea-a229-0242c0a8bc52'
    2020-05-25 02:43:37: Info: 192.168.188.82:3388: SELECT view_id, member_id FROM  mysql_innodb_cluster_metadata.v2_ar_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND member_role = 'PRIMARY'
    2020-05-25 02:43:37: Error: Unable to connect to the PRIMARY of the replicaset kk: MySQL Error 2003: ms81:3388: Can't connect to MySQL server on 'ms81' (111)
    2020-05-25 02:43:37: Debug: Cluster change operations will not be possible unless the PRIMARY can be reached.
    2020-05-25 02:43:37: Debug: If the PRIMARY is unavailable, you must either repair it or perform a forced failover.
    2020-05-25 02:43:37: Debug: See \help forcePrimaryInstance for more information.
    2020-05-25 02:43:37: Warning: MYSQLSH 51118: PRIMARY instance is unavailable
    2020-05-25 02:43:37: Info: 192.168.188.82:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c WHERE c.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:43:37: Info: 192.168.188.82:3388: SELECT i.instance_id, i.cluster_id, am.master_instance_id, am.master_member_id, am.member_role, am.view_id,  i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:43:37: Debug: 3 instances in replicaset kk
    2020-05-25 02:43:37: Debug: Scanning state of replicaset ms81:3388
    2020-05-25 02:43:37: Debug: Connecting to ms81:3388
    2020-05-25 02:43:37: Warning: Could not connect to ms81:3388: MySQL Error 2003: ms81:3388: Can't connect to MySQL server on 'ms81' (111)
    2020-05-25 02:43:37: Debug: Scanning state of replicaset ms82:3388
    2020-05-25 02:43:37: Debug: Connecting to ms82:3388
    2020-05-25 02:43:37: Info: ms82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:43:37: Info: ms82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:43:37: Info: ms82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:43:37: Info: ms82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:43:37: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:43:37: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:43:37: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:43:37: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:43:37: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:43:37: Info: ms82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:43:37: Info: ms82:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:43:37: Info: channel '' at ms82:3388 with source_uuid: f1847297-9b2d-11ea-ba52-0242c0a8bc51, master ms81:3388 (running)
    2020-05-25 02:43:37: Info: ms82:3388: SELECT * FROM mysql.slave_master_info WHERE channel_name = ''
    2020-05-25 02:43:37: Info: ms82:3388: SELECT * FROM mysql.slave_relay_log_info WHERE channel_name = ''
    2020-05-25 02:43:37: Info: ms82:3388: SHOW SLAVE HOSTS
    2020-05-25 02:43:37: Debug: Scanning state of replicaset ms83:3388
    2020-05-25 02:43:37: Debug: Connecting to ms83:3388
    2020-05-25 02:43:37: Info: ms83:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:43:37: Info: ms83:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:43:37: Info: ms83:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:43:37: Info: ms83:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:43:37: Info: ms83:3388: SELECT @@server_uuid
    2020-05-25 02:43:37: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:43:37: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:43:37: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:43:37: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:43:37: Info: ms83:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:43:37: Info: ms83:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:43:37: Info: channel '' at ms83:3388 with source_uuid: f1847297-9b2d-11ea-ba52-0242c0a8bc51, master ms81:3388 (running)
    2020-05-25 02:43:37: Info: ms83:3388: SELECT * FROM mysql.slave_master_info WHERE channel_name = ''
    2020-05-25 02:43:37: Info: ms83:3388: SELECT * FROM mysql.slave_relay_log_info WHERE channel_name = ''
    2020-05-25 02:43:37: Info: ms83:3388: SHOW SLAVE HOSTS

    ```
- 重新拉起master，发现mysh中没有内容输出。继续保持master关闭。

## 对master角色进行failover
- 尝试对master角色进行failover
    ```
    MySQL  192.168.188.82:3388 ssl  JS > sh.forcePrimaryInstance('ms83:3388')
    ```
- 日志
    ```
    2020-05-25 02:45:21: Debug: Refreshing metadata cache
    2020-05-25 02:45:21: Info: 192.168.188.82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:45:21: Info: 192.168.188.82:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:45:21: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:45:21: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:45:21: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:45:21: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:45:21: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:45:21: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:45:21: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:45:21: Debug: Instance type check: ms82:3388: Metadata version 2.0.0 found
    2020-05-25 02:45:21: Info: 192.168.188.82:3388: select cluster_type from `mysql_innodb_cluster_metadata`.v2_this_instance
    2020-05-25 02:45:21: Debug: Instance type check: ms82:3388: ReplicaSet metadata record found (metadata 2.0.0)
    2020-05-25 02:45:21: Debug: Instance f6f42ea6-9b2d-11ea-a229-0242c0a8bc52 is managed for ASYNC-REPLICATION
    2020-05-25 02:45:21: Info: 192.168.188.82:3388: select count(*) from performance_schema.replication_group_members where MEMBER_ID = @@server_uuid AND MEMBER_STATE IS NOT NULL AND MEMBER_STATE <> 'OFFLINE'
    2020-05-25 02:45:21: Debug: Instance type check: ms82:3388: GR is installed but not active
    2020-05-25 02:45:21: Info: 192.168.188.82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.mysql_server_uuid = 'f6f42ea6-9b2d-11ea-a229-0242c0a8bc52'
    2020-05-25 02:45:21: Info: 192.168.188.82:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c WHERE c.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:45:21: Info: 192.168.188.82:3388: SELECT i.instance_id, i.cluster_id, am.master_instance_id, am.master_member_id, am.member_role, am.view_id,  i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:45:21: Debug: 3 instances in replicaset kk
    2020-05-25 02:45:21: Debug: Scanning state of replicaset ms81:3388
    2020-05-25 02:45:21: Debug: Connecting to ms81:3388
    2020-05-25 02:45:21: Warning: Could not connect to ms81:3388: MySQL Error 2003: ms81:3388: Can't connect to MySQL server on 'ms81' (111)
    2020-05-25 02:45:21: Debug: Scanning state of replicaset ms82:3388
    2020-05-25 02:45:21: Debug: Connecting to ms82:3388
    2020-05-25 02:45:21: Info: ms82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:45:21: Info: ms82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:45:21: Info: ms82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:45:21: Info: ms82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:45:21: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:45:21: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:45:21: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:45:21: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:45:21: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:45:21: Info: ms82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:45:21: Info: ms82:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:45:21: Info: channel '' at ms82:3388 with source_uuid: f1847297-9b2d-11ea-ba52-0242c0a8bc51, master ms81:3388 (running)
    2020-05-25 02:45:21: Info: ms82:3388: SELECT * FROM mysql.slave_master_info WHERE channel_name = ''
    2020-05-25 02:45:21: Info: ms82:3388: SELECT * FROM mysql.slave_relay_log_info WHERE channel_name = ''
    2020-05-25 02:45:21: Info: ms82:3388: SHOW SLAVE HOSTS
    2020-05-25 02:45:21: Debug: Scanning state of replicaset ms83:3388
    2020-05-25 02:45:21: Debug: Connecting to ms83:3388
    2020-05-25 02:45:21: Info: ms83:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:45:21: Info: ms83:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:45:21: Info: ms83:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:45:21: Info: ms83:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:45:21: Info: ms83:3388: SELECT @@server_uuid
    2020-05-25 02:45:21: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:45:21: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:45:21: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:45:21: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:45:21: Info: ms83:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:45:21: Info: ms83:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:45:21: Info: channel '' at ms83:3388 with source_uuid: f1847297-9b2d-11ea-ba52-0242c0a8bc51, master ms81:3388 (running)
    2020-05-25 02:45:21: Info: ms83:3388: SELECT * FROM mysql.slave_master_info WHERE channel_name = ''
    2020-05-25 02:45:21: Info: ms83:3388: SELECT * FROM mysql.slave_relay_log_info WHERE channel_name = ''
    2020-05-25 02:45:21: Info: ms83:3388: SHOW SLAVE HOSTS
    2020-05-25 02:45:21: Info: ms83:3388: SELECT @@server_uuid
    2020-05-25 02:45:21: Info: 192.168.188.82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:45:21: Debug: * Connecting to replicaset instances
    2020-05-25 02:45:21: Info: 192.168.188.82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:45:21: Debug: ** Connecting to ms82:3388
    2020-05-25 02:45:21: Info: ms82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:45:21: Info: ms82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:45:21: Info: ms82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:45:21: Info: ms82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:45:21: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:45:21: Debug: ** Connecting to ms83:3388
    2020-05-25 02:45:21: Info: ms83:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:45:21: Info: ms83:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:45:21: Info: ms83:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:45:21: Info: ms83:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:45:21: Info: ms83:3388: SELECT @@server_uuid
    2020-05-25 02:45:21: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('version_compile_os')
    2020-05-25 02:45:21: Info: ms82:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:45:21: Debug: Acquiring EXCLUSIVE lock ('AdminAPI_instance', 'AdminAPI_lock') on ms82:3388.
    2020-05-25 02:45:21: Info: ms82:3388: SELECT service_get_write_locks('AdminAPI_instance', 'AdminAPI_lock', 0)
    2020-05-25 02:45:21: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('version_compile_os')
    2020-05-25 02:45:21: Info: ms83:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:45:21: Debug: Acquiring EXCLUSIVE lock ('AdminAPI_instance', 'AdminAPI_lock') on ms83:3388.
    2020-05-25 02:45:21: Info: ms83:3388: SELECT service_get_write_locks('AdminAPI_instance', 'AdminAPI_lock', 0)
    2020-05-25 02:45:21: Debug: * Waiting for all received transactions to be applied
    2020-05-25 02:45:21: Info: ms82:3388: SELECT GROUP_CONCAT(received_transaction_set)   FROM performance_schema.replication_connection_status   WHERE channel_name = ''
    2020-05-25 02:45:21: Info: ms83:3388: SELECT GROUP_CONCAT(received_transaction_set)   FROM performance_schema.replication_connection_status   WHERE channel_name = ''
    2020-05-25 02:45:21: Debug: ** Waiting for received transactions to be applied at ms82:3388
    2020-05-25 02:45:21: Info: ms82:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:37-44', 60)
    2020-05-25 02:45:21: Debug: ** Waiting for received transactions to be applied at ms83:3388
    2020-05-25 02:45:21: Info: ms83:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:43-44', 60)
    2020-05-25 02:45:21: Debug: ms83:3388 will be promoted to PRIMARY of the replicaset and the former PRIMARY will be invalidated.
    2020-05-25 02:45:21: Debug: * Checking status of last known PRIMARY
    2020-05-25 02:45:21: Info: Status of PRIMARY node ms81:3388 is UNREACHABLE
    2020-05-25 02:45:21: Info: ms81:3388 is UNREACHABLE
    2020-05-25 02:45:21: Info: ms82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:45:21: Info: ms83:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:45:21: Debug: * Checking status of promoted instance
    2020-05-25 02:45:21: Info: ms83:3388 has status ONLINE
    2020-05-25 02:45:21: Debug: * Checking transaction set status
    2020-05-25 02:45:21: Info: ms83:3388: SET @gtidset_a='f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44'
    2020-05-25 02:45:21: Info: ms83:3388: SET @gtidset_b='f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44'
    2020-05-25 02:45:21: Info: ms83:3388: SELECT GTID_SUBTRACT(@gtidset_a, @gtidset_b)
    2020-05-25 02:45:21: Info: ms83:3388: SELECT GTID_SUBTRACT(@gtidset_b, @gtidset_a)
    2020-05-25 02:45:21: Debug: * Promoting ms83:3388 to a PRIMARY...
    2020-05-25 02:45:21: Info: Clearing SUPER_READ_ONLY in new PRIMARY ms83:3388
    2020-05-25 02:45:21: Info: ms83:3388: SET PERSIST `SUPER_READ_ONLY` = 'OFF'
    2020-05-25 02:45:21: Info: ms83:3388: SET PERSIST `READ_ONLY` = 'OFF'
    2020-05-25 02:45:21: Info: Stopping channel '' at ms83:3388
    2020-05-25 02:45:21: Debug: Stopping slave channel  for ms83:3388...
    2020-05-25 02:45:21: Info: ms83:3388: STOP SLAVE FOR CHANNEL ''
    2020-05-25 02:45:21: Info: ms83:3388: SHOW STATUS LIKE 'Slave_open_temp_tables'
    2020-05-25 02:45:21: Debug: * Updating metadata...
    2020-05-25 02:45:21: Debug: Metadata operations will use ms83:3388
    2020-05-25 02:45:21: Info: ms83:3388: START TRANSACTION
    2020-05-25 02:45:21: Info: ms83:3388: SELECT c.cluster_id, c.async_topology_type FROM mysql_innodb_cluster_metadata.v2_ar_clusters c JOIN mysql_innodb_cluster_metadata.v2_ar_members m   ON c.cluster_id = m.cluster_id WHERE m.instance_id = 3
    2020-05-25 02:45:21: Info: ms83:3388: SELECT m.instance_id FROM mysql_innodb_cluster_metadata.v2_ar_members m WHERE m.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND m.member_role = 'PRIMARY'
    2020-05-25 02:45:21: Info: ms83:3388: SELECT MAX(view_id) FROM mysql_innodb_cluster_metadata.async_cluster_views WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:45:21: Debug: Updating metadata for async cluster FORCE_ACTIVE view d10f0970-9e2f-11ea-a355-0242c0a8bc51,65536
    2020-05-25 02:45:21: Info: ms83:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_views (cluster_id, view_id, topology_type,  view_change_reason, view_change_time, view_change_info,  attributes) SELECT cluster_id, 65536, topology_type, 'FORCE_ACTIVE', NOW(6), JSON_OBJECT('user', USER(),   'source', @@server_uuid), attributes FROM mysql_innodb_cluster_metadata.async_cluster_views WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 4
    2020-05-25 02:45:21: Info: ms83:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_members (cluster_id, view_id, instance_id, master_instance_id,    primary_master, attributes) SELECT cluster_id, 65536, instance_id, NULL, 1, attributes FROM mysql_innodb_cluster_metadata.async_cluster_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 4 AND instance_id = 3
    2020-05-25 02:45:21: Info: ms83:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_members (cluster_id, view_id, instance_id, master_instance_id,    primary_master, attributes) SELECT cluster_id, 65536, instance_id, 3,     IF(instance_id = 3, 1, 0), attributes FROM mysql_innodb_cluster_metadata.async_cluster_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 4   AND instance_id NOT IN (3, 1)
    2020-05-25 02:45:21: Info: ms83:3388: COMMIT
    2020-05-25 02:45:21: Debug: ms83:3388 was force-promoted to PRIMARY.
    2020-05-25 02:45:21: Info: Former PRIMARY ms81:3388 is now invalidated and must be removed from the replicaset.
    2020-05-25 02:45:21: Debug: * Updating source of remaining SECONDARY instances
    2020-05-25 02:45:21: Info: ms82:3388: SET PERSIST `SUPER_READ_ONLY` = 'ON'
    2020-05-25 02:45:21: Debug: ** Changing replication source of ms82:3388 to ms83:3388
    2020-05-25 02:45:21: Info: Stopping replication at ms82:3388 ...
    2020-05-25 02:45:21: Info: Stopping channel '' at ms82:3388
    2020-05-25 02:45:21: Debug: Stopping slave channel  for ms82:3388...
    2020-05-25 02:45:21: Info: ms82:3388: STOP SLAVE FOR CHANNEL ''
    2020-05-25 02:45:21: Info: ms82:3388: SHOW STATUS LIKE 'Slave_open_temp_tables'
    2020-05-25 02:45:21: Info: Changing master address for channel '' of ms82:3388 to ms83:3388
    2020-05-25 02:45:21: Info: ms82:3388: CHANGE MASTER TO  MASTER_HOST=/*(*/ 'ms83' /*)*/, MASTER_PORT=/*(*/ 3388 /*)*/ FOR CHANNEL ''
    2020-05-25 02:45:21: Info: Starting replication at ms82:3388 ...
    2020-05-25 02:45:21: Debug: Starting slave channel  for ms82:3388...
    2020-05-25 02:45:21: Info: ms82:3388: START SLAVE FOR CHANNEL ''
    2020-05-25 02:45:22: Info: PRIMARY changed for instance ms82:3388
    2020-05-25 02:45:22: Info: Resetting slave for channel '' at ms83:3388
    2020-05-25 02:45:22: Debug: Resetting slave ALL channel '' for ms83:3388...
    2020-05-25 02:45:22: Info: ms83:3388: RESET SLAVE ALL FOR CHANNEL ''
    2020-05-25 02:45:22: Debug: Failover finished successfully.
    2020-05-25 02:45:22: Info: ms82:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:45:22: Debug: Releasing locks for 'AdminAPI_instance' on ms82:3388.
    2020-05-25 02:45:22: Info: ms82:3388: SELECT service_release_locks('AdminAPI_instance')
    2020-05-25 02:45:22: Info: ms83:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:45:22: Debug: Releasing locks for 'AdminAPI_instance' on ms83:3388.
    2020-05-25 02:45:22: Info: ms83:3388: SELECT service_release_locks('AdminAPI_instance')

    ```

## rejoin
- 重启ms81后，节点需要rejoin，在rejoin前查看一下RS状态
    ```
    MySQL  192.168.188.82:3388 ssl  JS > sh.status()
    {
        "replicaSet": {
            "name": "kk", 
            "primary": "ms83:3388", 
            "status": "AVAILABLE_PARTIAL", 
            "statusText": "The PRIMARY instance is available, but one or more SECONDARY instances are not.", 
            "topology": {
                "ms81:3388": {
                    "address": "ms81:3388", 
                    "fenced": false, 
                    "instanceErrors": [
                        "WARNING: Instance was INVALIDATED and must be removed from the replicaset.", 
                        "ERROR: Instance is NOT a PRIMARY but super_read_only option is OFF. Accidental updates to this instance are possible and will cause inconsistencies in the replicaset."
                    ], 
                    "instanceRole": null, 
                    "mode": null, 
                    "status": "INVALIDATED", 
                    "transactionSetConsistencyStatus": "OK"
                }, 
                "ms82:3388": {
                    "address": "ms82:3388", 
                    "instanceRole": "SECONDARY", 
                    "mode": "R/O", 
                    "replication": {
                        "applierStatus": "APPLIED_ALL", 
                        "applierThreadState": "Waiting for an event from Coordinator", 
                        "applierWorkerThreads": 4, 
                        "receiverStatus": "ON", 
                        "receiverThreadState": "Waiting for master to send event", 
                        "replicationLag": null
                    }, 
                    "status": "ONLINE"
                }, 
                "ms83:3388": {
                    "address": "ms83:3388", 
                    "instanceRole": "PRIMARY", 
                    "mode": "R/W", 
                    "status": "ONLINE"
                }
            }, 
            "type": "ASYNC"
        }
    }

    ```
- 日志
    ```
    2020-05-25 02:46:29: Debug: Refreshing metadata cache
    2020-05-25 02:46:29: Info: ms83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:46:29: Info: ms83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:46:29: Info: ms83:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:46:29: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:46:29: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:46:29: Info: ms83:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:46:29: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:46:29: Info: ms83:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:46:29: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:46:29: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:46:29: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:46:29: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:46:29: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:46:29: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:46:29: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:46:29: Debug: Instance type check: ms82:3388: Metadata version 2.0.0 found
    2020-05-25 02:46:29: Info: 192.168.188.82:3388: select cluster_type from `mysql_innodb_cluster_metadata`.v2_this_instance
    2020-05-25 02:46:29: Debug: Instance type check: ms82:3388: ReplicaSet metadata record found (metadata 2.0.0)
    2020-05-25 02:46:29: Debug: Instance f6f42ea6-9b2d-11ea-a229-0242c0a8bc52 is managed for ASYNC-REPLICATION
    2020-05-25 02:46:29: Info: 192.168.188.82:3388: select count(*) from performance_schema.replication_group_members where MEMBER_ID = @@server_uuid AND MEMBER_STATE IS NOT NULL AND MEMBER_STATE <> 'OFFLINE'
    2020-05-25 02:46:29: Debug: Instance type check: ms82:3388: GR is installed but not active
    2020-05-25 02:46:29: Info: 192.168.188.82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.mysql_server_uuid = 'f6f42ea6-9b2d-11ea-a229-0242c0a8bc52'
    2020-05-25 02:46:29: Info: ms83:3388: SELECT view_id, member_id FROM  mysql_innodb_cluster_metadata.v2_ar_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND member_role = 'PRIMARY'
    2020-05-25 02:46:29: Info: ms83:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:46:29: Info: ms83:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:46:29: Info: ms83:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:46:29: Info: ms83:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:46:29: Info: ms83:3388: SELECT @@server_uuid
    2020-05-25 02:46:29: Debug: Metadata operations will use ms83:3388
    2020-05-25 02:46:29: Debug: Refreshing metadata cache
    2020-05-25 02:46:29: Info: ms83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:46:29: Info: ms83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:46:29: Info: ms83:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:46:29: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:46:29: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:46:29: Info: ms83:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:46:29: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:46:29: Info: ms83:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:46:29: Info: Connected to replicaset PRIMARY instance ms83:3388
    2020-05-25 02:46:29: Info: ms83:3388: SELECT view_id, member_id FROM  mysql_innodb_cluster_metadata.v2_ar_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND member_role = 'PRIMARY'
    2020-05-25 02:46:29: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:46:29: Info: ms81:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:46:29: Info: ms81:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:46:29: Info: ms81:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:46:29: Info: ms81:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:46:29: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:46:29: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:46:29: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:46:29: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:46:29: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:46:29: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:46:29: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:46:29: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:46:29: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:46:29: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:46:29: Info: ms82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:46:29: Info: ms82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:46:29: Info: ms82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:46:29: Info: ms82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:46:29: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:46:29: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:46:29: Info: ms82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:46:29: Info: ms82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:46:29: Info: ms82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:46:29: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:46:29: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:46:29: Info: ms82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:46:29: Info: ms82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:46:29: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:46:29: Info: ms83:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:46:29: Info: ms83:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:46:29: Info: ms83:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:46:29: Info: ms83:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:46:29: Info: ms83:3388: SELECT @@server_uuid
    2020-05-25 02:46:29: Debug: Metadata operations will use ms83:3388
    2020-05-25 02:46:29: Info: ms83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:46:29: Info: ms83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:46:29: Info: ms83:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:46:29: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:46:29: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:46:29: Info: ms83:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:46:29: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:46:29: Info: ms83:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c WHERE c.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:46:29: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, am.master_instance_id, am.master_member_id, am.member_role, am.view_id,  i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:46:29: Debug: 3 instances in replicaset kk
    2020-05-25 02:46:29: Debug: Scanning state of replicaset ms81:3388
    2020-05-25 02:46:29: Debug: Connecting to ms81:3388
    2020-05-25 02:46:29: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:46:29: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:46:29: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:46:29: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:46:29: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:46:29: Info: ms81:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:46:29: Info: ms81:3388: SHOW SLAVE HOSTS
    2020-05-25 02:46:29: Debug: Scanning state of replicaset ms82:3388
    2020-05-25 02:46:29: Debug: Connecting to ms82:3388
    2020-05-25 02:46:29: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:46:29: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:46:29: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:46:29: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:46:29: Info: ms82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:46:29: Info: ms82:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:46:29: Info: channel '' at ms82:3388 with source_uuid: f8825c7a-9b2d-11ea-8956-0242c0a8bc53, master ms83:3388 (running)
    2020-05-25 02:46:29: Info: ms82:3388: SELECT * FROM mysql.slave_master_info WHERE channel_name = ''
    2020-05-25 02:46:29: Info: ms82:3388: SELECT * FROM mysql.slave_relay_log_info WHERE channel_name = ''
    2020-05-25 02:46:29: Info: ms82:3388: SHOW SLAVE HOSTS
    2020-05-25 02:46:29: Debug: Scanning state of replicaset ms83:3388
    2020-05-25 02:46:29: Debug: Connecting to ms83:3388
    2020-05-25 02:46:29: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:46:29: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:46:29: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:46:29: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:46:29: Info: ms83:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:46:29: Info: ms83:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:46:29: Info: ms83:3388: SHOW SLAVE HOSTS
    2020-05-25 02:46:29: Info: ms83:3388 has 1 instances replicating from it
    2020-05-25 02:46:29: Info: ms83:3388: SELECT GTID_SUBTRACT('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44', @@global.gtid_executed)
    2020-05-25 02:46:29: Debug: GTIDs that exist in ms81:3388 but not its master ms83:3388: '' (0)
    2020-05-25 02:46:29: Info: ms83:3388: SELECT GTID_SUBTRACT('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1', @@global.gtid_executed)
    2020-05-25 02:46:29: Debug: GTIDs that exist in ms82:3388 but not its master ms83:3388: '' (0)

    ```
- 对ms81进行rejoin
    ```
    MySQL  192.168.188.82:3388 ssl  JS > sh.rejoinInstance('ms81:3388')
    * Validating instance...
    ** Checking transaction state of the instance...
    The safest and most convenient way to provision a new instance is through automatic clone provisioning, which will completely overwrite the state of 'ms81:3388' with a physical snapshot from an existing replicaset member. To use this method by default, set the 'recoveryMethod' option to 'clone'.

    WARNING: It should be safe to rely on replication to incrementally recover the state of the new instance if you are sure all updates ever executed in the replicaset were done with GTIDs enabled, there are no purged transactions and the new instance contains the same GTID set as the replicaset or a subset of it. To use this method by default, set the 'recoveryMethod' option to 'incremental'.

    Incremental state recovery was selected because it seems to be safely usable.

    * Rejoining instance to replicaset...
    ** Configuring ms81:3388 to replicate from ms83:3388
    ** Checking replication channel status...
    ** Waiting for rejoined instance to synchronize with PRIMARY...

    * Updating the Metadata...
    The instance 'ms81:3388' rejoined the replicaset and is replicating from ms83:3388.
    ```
- 日志
    ```
    2020-05-25 02:47:13: Debug: Refreshing metadata cache
    2020-05-25 02:47:13: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:47:13: Info: ms83:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:47:13: Debug: Checking rejoin instance preconditions.
    2020-05-25 02:47:13: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:47:13: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:47:13: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:47:13: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:13: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:47:13: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:47:13: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:13: Debug: Instance type check: ms82:3388: Metadata version 2.0.0 found
    2020-05-25 02:47:13: Info: 192.168.188.82:3388: select cluster_type from `mysql_innodb_cluster_metadata`.v2_this_instance
    2020-05-25 02:47:13: Debug: Instance type check: ms82:3388: ReplicaSet metadata record found (metadata 2.0.0)
    2020-05-25 02:47:13: Debug: Instance f6f42ea6-9b2d-11ea-a229-0242c0a8bc52 is managed for ASYNC-REPLICATION
    2020-05-25 02:47:13: Info: 192.168.188.82:3388: select count(*) from performance_schema.replication_group_members where MEMBER_ID = @@server_uuid AND MEMBER_STATE IS NOT NULL AND MEMBER_STATE <> 'OFFLINE'
    2020-05-25 02:47:13: Debug: Instance type check: ms82:3388: GR is installed but not active
    2020-05-25 02:47:13: Info: 192.168.188.82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.mysql_server_uuid = 'f6f42ea6-9b2d-11ea-a229-0242c0a8bc52'
    2020-05-25 02:47:13: Debug: Connecting to target instance.
    2020-05-25 02:47:13: Info: ms81:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:13: Info: ms81:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:13: Info: ms81:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:13: Info: ms81:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:13: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:47:13: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('version_compile_os')
    2020-05-25 02:47:13: Info: ms81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:47:13: Debug: Acquiring EXCLUSIVE lock ('AdminAPI_instance', 'AdminAPI_lock') on ms81:3388.
    2020-05-25 02:47:13: Info: ms81:3388: SELECT service_get_write_locks('AdminAPI_instance', 'AdminAPI_lock', 0)
    2020-05-25 02:47:13: Debug: Setting up topology manager.
    2020-05-25 02:47:13: Info: ms83:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c WHERE c.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:13: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, am.master_instance_id, am.master_member_id, am.member_role, am.view_id,  i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:13: Debug: 3 instances in replicaset kk
    2020-05-25 02:47:13: Debug: Scanning state of replicaset ms81:3388
    2020-05-25 02:47:13: Debug: Connecting to ms81:3388
    2020-05-25 02:47:13: Info: ms81:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:13: Info: ms81:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:13: Info: ms81:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:13: Info: ms81:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:13: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:47:13: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:47:13: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:47:13: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:47:13: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:47:13: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:13: Info: ms81:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:47:13: Info: ms81:3388: SHOW SLAVE HOSTS
    2020-05-25 02:47:13: Debug: Scanning state of replicaset ms82:3388
    2020-05-25 02:47:13: Debug: Connecting to ms82:3388
    2020-05-25 02:47:13: Info: ms82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:13: Info: ms82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:13: Info: ms82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:13: Info: ms82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:13: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:47:13: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:47:13: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:47:13: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:47:13: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:47:13: Info: ms82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:13: Info: ms82:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:47:13: Info: channel '' at ms82:3388 with source_uuid: f8825c7a-9b2d-11ea-8956-0242c0a8bc53, master ms83:3388 (running)
    2020-05-25 02:47:13: Info: ms82:3388: SELECT * FROM mysql.slave_master_info WHERE channel_name = ''
    2020-05-25 02:47:13: Info: ms82:3388: SELECT * FROM mysql.slave_relay_log_info WHERE channel_name = ''
    2020-05-25 02:47:13: Info: ms82:3388: SHOW SLAVE HOSTS
    2020-05-25 02:47:13: Debug: Scanning state of replicaset ms83:3388
    2020-05-25 02:47:13: Debug: Connecting to ms83:3388
    2020-05-25 02:47:13: Info: ms83:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:13: Info: ms83:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:13: Info: ms83:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:13: Info: ms83:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:13: Info: ms83:3388: SELECT @@server_uuid
    2020-05-25 02:47:13: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:47:13: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:47:13: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:47:13: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:47:13: Info: ms83:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:13: Info: ms83:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:47:13: Info: ms83:3388: SHOW SLAVE HOSTS
    2020-05-25 02:47:13: Info: ms83:3388 has 1 instances replicating from it
    2020-05-25 02:47:13: Info: ms83:3388: SELECT GTID_SUBTRACT('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44', @@global.gtid_executed)
    2020-05-25 02:47:13: Debug: GTIDs that exist in ms81:3388 but not its master ms83:3388: '' (0)
    2020-05-25 02:47:13: Info: ms83:3388: SELECT GTID_SUBTRACT('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1', @@global.gtid_executed)
    2020-05-25 02:47:13: Debug: GTIDs that exist in ms82:3388 but not its master ms83:3388: '' (0)
    2020-05-25 02:47:13: Debug: Get current PRIMARY and ensure it is healthy (updatable).
    2020-05-25 02:47:13: Info: ms83:3388: SELECT view_id, member_id FROM  mysql_innodb_cluster_metadata.v2_ar_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND member_role = 'PRIMARY'
    2020-05-25 02:47:13: Debug: Metadata operations will use ms83:3388
    2020-05-25 02:47:13: Debug: Refreshing metadata cache
    2020-05-25 02:47:13: Info: ms83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:47:13: Info: ms83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:47:13: Info: ms83:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:13: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:47:13: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:47:13: Info: ms83:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:13: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:47:13: Info: ms83:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:47:13: Info: Connected to replicaset PRIMARY instance ms83:3388
    2020-05-25 02:47:13: Info: ms83:3388: SELECT @@server_uuid
    2020-05-25 02:47:13: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('version_compile_os')
    2020-05-25 02:47:13: Info: ms83:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:47:13: Debug: Acquiring SHARED lock ('AdminAPI_instance', 'AdminAPI_lock') on ms83:3388.
    2020-05-25 02:47:13: Info: ms83:3388: SELECT service_get_read_locks('AdminAPI_instance', 'AdminAPI_lock', 0)
    2020-05-25 02:47:13: Info: ms83:3388: SELECT view_id, member_id FROM  mysql_innodb_cluster_metadata.v2_ar_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND member_role = 'PRIMARY'
    2020-05-25 02:47:13: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:13: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:47:13: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:47:13: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:47:13: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:47:13: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:13: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:47:13: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:47:13: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:13: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:13: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:47:13: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:47:13: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:47:13: Info: ms82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:47:13: Info: ms82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:47:13: Info: ms82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:13: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:47:13: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:47:13: Info: ms82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:13: Info: ms82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:13: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:47:13: Info: ms83:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:13: Info: ms83:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:13: Info: ms83:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:13: Info: ms83:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:13: Info: ms83:3388: SELECT @@server_uuid
    2020-05-25 02:47:13: Debug: Metadata operations will use ms83:3388
    2020-05-25 02:47:13: Info: ms83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:47:13: Info: ms83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:47:13: Info: ms83:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:13: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:47:13: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:47:13: Info: ms83:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:13: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:13: Debug: * Validating instance...
    2020-05-25 02:47:13: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.address = 'ms81:3388'
    2020-05-25 02:47:13: Debug: ** Checking transaction state of the instance...
    2020-05-25 02:47:13: Info: ms83:3388: SELECT attributes->'$.opt_gtidSetIsComplete' FROM mysql_innodb_cluster_metadata.clusters WHERE cluster_id='d10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:13: Debug: Checking if instance 'ms81:3388' has the clone plugin installed
    2020-05-25 02:47:13: Info: ms81:3388: SELECT plugin_status FROM information_schema.plugins WHERE plugin_name = 'clone'
    2020-05-25 02:47:13: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:13: Info: 192.168.188.82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:13: Info: 192.168.188.82:3388: SELECT @@GLOBAL.GTID_PURGED
    2020-05-25 02:47:13: Info: 192.168.188.82:3388: SET @gtidset_a='f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1'
    2020-05-25 02:47:13: Info: 192.168.188.82:3388: SET @gtidset_b='f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44'
    2020-05-25 02:47:13: Info: 192.168.188.82:3388: SELECT GTID_SUBTRACT(@gtidset_a, @gtidset_b)
    2020-05-25 02:47:13: Info: 192.168.188.82:3388: SELECT GTID_SUBTRACT(@gtidset_b, @gtidset_a)
    2020-05-25 02:47:13: Info: 192.168.188.82:3388: SELECT GTID_SUBTRACT('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-36', 'f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44') = ''
    2020-05-25 02:47:13: Debug: The safest and most convenient way to provision a new instance is through automatic clone provisioning, which will completely overwrite the state of 'ms81:3388' with a physical snapshot from an existing replicaset member. To use this method by default, set the 'recoveryMethod' option to 'clone'.
    2020-05-25 02:47:13: Warning: It should be safe to rely on replication to incrementally recover the state of the new instance if you are sure all updates ever executed in the replicaset were done with GTIDs enabled, there are no purged transactions and the new instance contains the same GTID set as the replicaset or a subset of it. To use this method by default, set the 'recoveryMethod' option to 'incremental'.
    2020-05-25 02:47:13: Debug: Incremental state recovery was selected because it seems to be safely usable.
    2020-05-25 02:47:13: Debug: * Rejoining instance to replicaset...
    2020-05-25 02:47:13: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:47:13: Info: Resetting password for mysql_innodb_rs_813388@% at ms83:3388
    2020-05-25 02:47:13: Info: ms83:3388: SET PASSWORD FOR 'mysql_innodb_rs_813388'@'%' = ****
    2020-05-25 02:47:13: Debug: ** Configuring ms81:3388 to replicate from ms83:3388
    2020-05-25 02:47:13: Info: Stopping replication at ms81:3388 ...
    2020-05-25 02:47:13: Info: Stopping channel '' at ms81:3388
    2020-05-25 02:47:13: Debug: Stopping slave channel  for ms81:3388...
    2020-05-25 02:47:13: Info: ms81:3388: STOP SLAVE FOR CHANNEL ''
    2020-05-25 02:47:13: Info: ms81:3388: SHOW STATUS LIKE 'Slave_open_temp_tables'
    2020-05-25 02:47:13: Info: Setting up async master for channel '' of ms81:3388 to ms83:3388 (user 'mysql_innodb_rs_813388')
    2020-05-25 02:47:13: Info: ms81:3388: CHANGE MASTER TO /*!80011 get_master_public_key=1, */ MASTER_HOST=/*(*/ 'ms83' /*)*/, MASTER_PORT=/*(*/ 3388 /*)*/, MASTER_USER='mysql_innodb_rs_813388', MASTER_PASSWORD=****, MASTER_AUTO_POSITION=1 FOR CHANNEL ''
    2020-05-25 02:47:14: Info: Starting replication at ms81:3388 ...
    2020-05-25 02:47:14: Debug: Starting slave channel  for ms81:3388...
    2020-05-25 02:47:14: Info: ms81:3388: START SLAVE FOR CHANNEL ''
    2020-05-25 02:47:14: Debug: ** Checking replication channel status...
    2020-05-25 02:47:14: Debug: ms81:3388: waiting for replication i/o thread for channel 
    2020-05-25 02:47:14: Info: ms81:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    WHERE c.channel_name = ''
    2020-05-25 02:47:14: Debug: source="ms83:3388" channel= status=ON receiver=ON coordinator=ON applier0=ON applier1=ON applier2=ON applier3=ON
    2020-05-25 02:47:14: Info: Fencing new instance 'ms81:3388' to prevent updates.
    2020-05-25 02:47:14: Info: ms81:3388: SET PERSIST `SUPER_READ_ONLY` = 'ON'
    2020-05-25 02:47:14: Debug: ** Waiting for rejoined instance to synchronize with PRIMARY...
    2020-05-25 02:47:14: Info: ms83:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:14: Info: ms81:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-2', 2)
    2020-05-25 02:47:14: Debug: * Updating the Metadata...
    2020-05-25 02:47:14: Info: ms83:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:47:14: Debug: Acquiring EXCLUSIVE lock ('AdminAPI_metadata', 'AdminAPI_lock') on ms83:3388.
    2020-05-25 02:47:14: Info: ms83:3388: SELECT service_get_write_locks('AdminAPI_metadata', 'AdminAPI_lock', 60)
    2020-05-25 02:47:14: Info: ms83:3388: START TRANSACTION
    2020-05-25 02:47:14: Info: ms83:3388: SELECT MAX(view_id) FROM mysql_innodb_cluster_metadata.async_cluster_views WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:14: Debug: Updating metadata for async cluster REJOIN_INSTANCE view d10f0970-9e2f-11ea-a355-0242c0a8bc51,65537
    2020-05-25 02:47:14: Info: ms83:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_views (cluster_id, view_id, topology_type,  view_change_reason, view_change_time, view_change_info,  attributes) SELECT cluster_id, 65537, topology_type, 'REJOIN_INSTANCE', NOW(6), JSON_OBJECT('user', USER(),   'source', @@server_uuid), attributes FROM mysql_innodb_cluster_metadata.async_cluster_views WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 65536
    2020-05-25 02:47:14: Info: ms83:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_members (cluster_id, view_id, instance_id, master_instance_id,    primary_master, attributes) SELECT cluster_id, 65537, instance_id, master_instance_id,    primary_master, attributes FROM mysql_innodb_cluster_metadata.async_cluster_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 65536 AND instance_id <> 1
    2020-05-25 02:47:14: Info: ms83:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_members ( cluster_id, view_id, instance_id, master_instance_id, primary_master, attributes) VALUES ('d10f0970-9e2f-11ea-a355-0242c0a8bc51', 65537, 1, IF(3=0, NULL, 3), 0,    (SELECT JSON_OBJECT('instance.mysql_server_uuid', mysql_server_uuid,       'instance.address', address)     FROM mysql_innodb_cluster_metadata.instances     WHERE instance_id = 1) )
    2020-05-25 02:47:14: Info: ms83:3388: COMMIT
    2020-05-25 02:47:15: Info: ms83:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:47:15: Debug: Releasing locks for 'AdminAPI_metadata' on ms83:3388.
    2020-05-25 02:47:15: Info: ms83:3388: SELECT service_release_locks('AdminAPI_metadata')
    2020-05-25 02:47:15: Debug: The instance 'ms81:3388' rejoined the replicaset and is replicating from ms83:3388.

    2020-05-25 02:47:15: Info: ms83:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:47:15: Debug: Releasing locks for 'AdminAPI_instance' on ms83:3388.
    2020-05-25 02:47:15: Info: ms83:3388: SELECT service_release_locks('AdminAPI_instance')
    2020-05-25 02:47:15: Info: ms81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:47:15: Debug: Releasing locks for 'AdminAPI_instance' on ms81:3388.
    2020-05-25 02:47:15: Info: ms81:3388: SELECT service_release_locks('AdminAPI_instance')

    ```

## switchover
- 做一次switchover
    ```
    MySQL  192.168.188.82:3388 ssl  JS > sh.setPrimaryInstance('ms82:3388')
    ms82:3388 will be promoted to PRIMARY of 'kk'.
    The current PRIMARY is ms83:3388.

    * Connecting to replicaset instances
    ** Connecting to ms81:3388
    ** Connecting to ms82:3388
    ** Connecting to ms83:3388
    ** Connecting to ms81:3388
    ** Connecting to ms82:3388
    ** Connecting to ms83:3388

    * Performing validation checks
    ** Checking async replication topology...
    ** Checking transaction state of the instance...

    * Synchronizing transaction backlog at ms82:3388

    * Updating metadata

    * Acquiring locks in replicaset instances
    ** Pre-synchronizing SECONDARIES
    ** Acquiring global lock at PRIMARY
    ** Acquiring global lock at SECONDARIES

    * Updating replication topology
    ** Configuring ms83:3388 to replicate from ms82:3388
    ** Changing replication source of ms81:3388 to ms82:3388

    ms82:3388 was promoted to PRIMARY.

    ```
- 日志
    ```
    2020-05-25 02:47:33: Debug: Refreshing metadata cache
    2020-05-25 02:47:33: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:47:33: Info: ms83:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:47:33: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:47:33: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:47:33: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:47:33: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:33: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:47:33: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:47:33: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:33: Debug: Instance type check: ms82:3388: Metadata version 2.0.0 found
    2020-05-25 02:47:33: Info: 192.168.188.82:3388: select cluster_type from `mysql_innodb_cluster_metadata`.v2_this_instance
    2020-05-25 02:47:33: Debug: Instance type check: ms82:3388: ReplicaSet metadata record found (metadata 2.0.0)
    2020-05-25 02:47:33: Debug: Instance f6f42ea6-9b2d-11ea-a229-0242c0a8bc52 is managed for ASYNC-REPLICATION
    2020-05-25 02:47:33: Info: 192.168.188.82:3388: select count(*) from performance_schema.replication_group_members where MEMBER_ID = @@server_uuid AND MEMBER_STATE IS NOT NULL AND MEMBER_STATE <> 'OFFLINE'
    2020-05-25 02:47:33: Debug: Instance type check: ms82:3388: GR is installed but not active
    2020-05-25 02:47:33: Info: 192.168.188.82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.mysql_server_uuid = 'f6f42ea6-9b2d-11ea-a229-0242c0a8bc52'
    2020-05-25 02:47:33: Info: ms83:3388: SELECT view_id, member_id FROM  mysql_innodb_cluster_metadata.v2_ar_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND member_role = 'PRIMARY'
    2020-05-25 02:47:33: Info: ms83:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:33: Info: ms83:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:33: Info: ms83:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:33: Info: ms83:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:33: Info: ms83:3388: SELECT @@server_uuid
    2020-05-25 02:47:33: Debug: Metadata operations will use ms83:3388
    2020-05-25 02:47:33: Debug: Refreshing metadata cache
    2020-05-25 02:47:33: Info: ms83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:47:33: Info: ms83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:47:33: Info: ms83:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:33: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:47:33: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:47:33: Info: ms83:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:33: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:47:33: Info: ms83:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:47:33: Info: Connected to replicaset PRIMARY instance ms83:3388
    2020-05-25 02:47:33: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('version_compile_os')
    2020-05-25 02:47:33: Info: ms83:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:47:33: Debug: Acquiring EXCLUSIVE lock ('AdminAPI_instance', 'AdminAPI_lock') on ms83:3388.
    2020-05-25 02:47:33: Info: ms83:3388: SELECT service_get_write_locks('AdminAPI_instance', 'AdminAPI_lock', 0)
    2020-05-25 02:47:33: Info: ms83:3388: SELECT view_id, member_id FROM  mysql_innodb_cluster_metadata.v2_ar_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND member_role = 'PRIMARY'
    2020-05-25 02:47:33: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:33: Info: ms81:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:33: Info: ms81:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:33: Info: ms81:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:33: Info: ms81:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:33: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:47:33: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:47:33: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:47:33: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:47:33: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:33: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:47:33: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:47:33: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:33: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:33: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:47:33: Info: ms82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:33: Info: ms82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:33: Info: ms82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:33: Info: ms82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:33: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:47:33: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:47:33: Info: ms82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:47:33: Info: ms82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:47:33: Info: ms82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:33: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:47:33: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:47:33: Info: ms82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:33: Info: ms82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:33: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:47:33: Info: ms83:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:33: Info: ms83:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:33: Info: ms83:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:33: Info: ms83:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:33: Info: ms83:3388: SELECT @@server_uuid
    2020-05-25 02:47:33: Debug: Metadata operations will use ms83:3388
    2020-05-25 02:47:33: Info: ms83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:47:33: Info: ms83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:47:33: Info: ms83:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:33: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:47:33: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:47:33: Info: ms83:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:33: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:33: Info: ms83:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c WHERE c.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:33: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, am.master_instance_id, am.master_member_id, am.member_role, am.view_id,  i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:33: Debug: 3 instances in replicaset kk
    2020-05-25 02:47:33: Debug: Scanning state of replicaset ms81:3388
    2020-05-25 02:47:33: Debug: Connecting to ms81:3388
    2020-05-25 02:47:33: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:47:33: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:47:33: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:47:33: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:47:33: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:33: Info: ms81:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:47:33: Info: channel '' at ms81:3388 with source_uuid: f8825c7a-9b2d-11ea-8956-0242c0a8bc53, master ms83:3388 (running)
    2020-05-25 02:47:33: Info: ms81:3388: SELECT * FROM mysql.slave_master_info WHERE channel_name = ''
    2020-05-25 02:47:33: Info: ms81:3388: SELECT * FROM mysql.slave_relay_log_info WHERE channel_name = ''
    2020-05-25 02:47:33: Info: ms81:3388: SHOW SLAVE HOSTS
    2020-05-25 02:47:33: Debug: Scanning state of replicaset ms82:3388
    2020-05-25 02:47:33: Debug: Connecting to ms82:3388
    2020-05-25 02:47:33: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:47:33: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:47:33: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:47:33: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:47:33: Info: ms82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:33: Info: ms82:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:47:33: Info: channel '' at ms82:3388 with source_uuid: f8825c7a-9b2d-11ea-8956-0242c0a8bc53, master ms83:3388 (running)
    2020-05-25 02:47:33: Info: ms82:3388: SELECT * FROM mysql.slave_master_info WHERE channel_name = ''
    2020-05-25 02:47:33: Info: ms82:3388: SELECT * FROM mysql.slave_relay_log_info WHERE channel_name = ''
    2020-05-25 02:47:33: Info: ms82:3388: SHOW SLAVE HOSTS
    2020-05-25 02:47:33: Debug: Scanning state of replicaset ms83:3388
    2020-05-25 02:47:33: Debug: Connecting to ms83:3388
    2020-05-25 02:47:33: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:47:33: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:47:33: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:47:33: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:47:33: Info: ms83:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:33: Info: ms83:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:47:33: Info: ms83:3388: SHOW SLAVE HOSTS
    2020-05-25 02:47:33: Info: ms83:3388 has 2 instances replicating from it
    2020-05-25 02:47:33: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:47:33: Debug: ms82:3388 will be promoted to PRIMARY of 'kk'.
    The current PRIMARY is ms83:3388.

    2020-05-25 02:47:33: Debug: * Connecting to replicaset instances
    2020-05-25 02:47:33: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:33: Debug: ** Connecting to ms81:3388
    2020-05-25 02:47:33: Debug: ** Connecting to ms82:3388
    2020-05-25 02:47:33: Debug: ** Connecting to ms83:3388
    2020-05-25 02:47:33: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:47:33: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('version_compile_os')
    2020-05-25 02:47:33: Info: ms81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:47:33: Debug: Acquiring EXCLUSIVE lock ('AdminAPI_instance', 'AdminAPI_lock') on ms81:3388.
    2020-05-25 02:47:33: Info: ms81:3388: SELECT service_get_write_locks('AdminAPI_instance', 'AdminAPI_lock', 0)
    2020-05-25 02:47:33: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:47:33: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('version_compile_os')
    2020-05-25 02:47:33: Info: ms82:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:47:33: Debug: Acquiring EXCLUSIVE lock ('AdminAPI_instance', 'AdminAPI_lock') on ms82:3388.
    2020-05-25 02:47:33: Info: ms82:3388: SELECT service_get_write_locks('AdminAPI_instance', 'AdminAPI_lock', 0)
    2020-05-25 02:47:33: Info: ms83:3388: SELECT @@server_uuid
    2020-05-25 02:47:33: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:33: Debug: ** Connecting to ms81:3388
    2020-05-25 02:47:33: Info: ms81:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:33: Info: ms81:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:33: Info: ms81:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:33: Info: ms81:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:33: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:47:33: Debug: ** Connecting to ms82:3388
    2020-05-25 02:47:33: Info: ms82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:33: Info: ms82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:33: Info: ms82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:33: Info: ms82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:33: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:47:33: Debug: ** Connecting to ms83:3388
    2020-05-25 02:47:33: Info: ms83:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:33: Info: ms83:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:33: Info: ms83:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:33: Info: ms83:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:33: Info: ms83:3388: SELECT @@server_uuid
    2020-05-25 02:47:33: Debug: * Performing validation checks
    2020-05-25 02:47:33: Debug: ** Checking async replication topology...
    2020-05-25 02:47:33: Debug: ** Checking transaction state of the instance...
    2020-05-25 02:47:33: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:33: Info: ms83:3388: SELECT GTID_SUBTRACT(@@global.gtid_purged, 'f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-3')
    2020-05-25 02:47:33: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:33: Info: ms83:3388: SELECT GTID_SUBTRACT('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-3', @@global.gtid_executed)
    2020-05-25 02:47:33: Info: ms82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:33: Info: ms83:3388: SELECT GTID_SUBTRACT(@@global.gtid_purged, 'f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-3')
    2020-05-25 02:47:33: Info: ms82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:33: Info: ms83:3388: SELECT GTID_SUBTRACT('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-3', @@global.gtid_executed)
    2020-05-25 02:47:33: Debug: * Synchronizing transaction backlog at ms82:3388
    2020-05-25 02:47:33: Info: ms83:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:33: Info: ms82:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-3', 10)
    2020-05-25 02:47:33: Debug: * Updating metadata
    2020-05-25 02:47:33: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:47:33: Info: Resetting password for mysql_innodb_rs_833388@% at ms83:3388
    2020-05-25 02:47:33: Info: ms83:3388: SET PASSWORD FOR 'mysql_innodb_rs_833388'@'%' = ****
    2020-05-25 02:47:33: Info: Updating metadata at ms83:3388
    2020-05-25 02:47:33: Info: ms83:3388: START TRANSACTION
    2020-05-25 02:47:33: Info: ms83:3388: SELECT c.cluster_id, c.async_topology_type FROM mysql_innodb_cluster_metadata.v2_ar_clusters c JOIN mysql_innodb_cluster_metadata.v2_ar_members m   ON c.cluster_id = m.cluster_id WHERE m.instance_id = 2
    2020-05-25 02:47:33: Info: ms83:3388: SELECT m.instance_id FROM mysql_innodb_cluster_metadata.v2_ar_members m WHERE m.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND m.member_role = 'PRIMARY'
    2020-05-25 02:47:33: Info: ms83:3388: SELECT MAX(view_id) FROM mysql_innodb_cluster_metadata.async_cluster_views WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:33: Debug: Updating metadata for async cluster SWITCH_ACTIVE view d10f0970-9e2f-11ea-a355-0242c0a8bc51,65538
    2020-05-25 02:47:33: Info: ms83:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_views (cluster_id, view_id, topology_type,  view_change_reason, view_change_time, view_change_info,  attributes) SELECT cluster_id, 65538, topology_type, 'SWITCH_ACTIVE', NOW(6), JSON_OBJECT('user', USER(),   'source', @@server_uuid), attributes FROM mysql_innodb_cluster_metadata.async_cluster_views WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 65537
    2020-05-25 02:47:33: Info: ms83:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_members (cluster_id, view_id, instance_id, master_instance_id,    primary_master, attributes) SELECT cluster_id, 65538, instance_id, NULL, 1, attributes FROM mysql_innodb_cluster_metadata.async_cluster_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 65537 AND instance_id = 2
    2020-05-25 02:47:33: Info: ms83:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_members (cluster_id, view_id, instance_id, master_instance_id,    primary_master, attributes) SELECT cluster_id, 65538, instance_id, 2, 0, attributes FROM mysql_innodb_cluster_metadata.async_cluster_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 65537 AND instance_id = 3
    2020-05-25 02:47:33: Info: ms83:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_members (cluster_id, view_id, instance_id, master_instance_id,    primary_master, attributes) SELECT cluster_id, 65538, instance_id, 2,     IF(instance_id = 2, 1, 0), attributes FROM mysql_innodb_cluster_metadata.async_cluster_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 65537   AND instance_id NOT IN (2, 3)
    2020-05-25 02:47:33: Info: ms83:3388: COMMIT
    2020-05-25 02:47:34: Debug: * Acquiring locks in replicaset instances
    2020-05-25 02:47:34: Debug: ** Pre-synchronizing SECONDARIES
    2020-05-25 02:47:34: Info: ms83:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:34: Info: ms82:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-5', 60)
    2020-05-25 02:47:34: Info: ms81:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-5', 60)
    2020-05-25 02:47:34: Debug: ** Acquiring global lock at PRIMARY
    2020-05-25 02:47:34: Info: ms83:3388: FLUSH TABLES WITH READ LOCK
    2020-05-25 02:47:34: Info: ms83:3388: SET global super_read_only=1
    2020-05-25 02:47:34: Info: ms83:3388: FLUSH BINARY LOGS
    2020-05-25 02:47:34: Debug: ** Acquiring global lock at SECONDARIES
    2020-05-25 02:47:34: Info: ms83:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:34: Info: ms81:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-5', 60)
    2020-05-25 02:47:34: Info: ms81:3388: FLUSH TABLES WITH READ LOCK
    2020-05-25 02:47:34: Info: ms82:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-5', 60)
    2020-05-25 02:47:34: Info: ms82:3388: FLUSH TABLES WITH READ LOCK
    2020-05-25 02:47:34: Debug: * Updating replication topology
    2020-05-25 02:47:34: Info: Enabling SUPER_READ_ONLY in old PRIMARY ms83:3388
    2020-05-25 02:47:34: Info: ms83:3388: SET PERSIST `SUPER_READ_ONLY` = 'ON'
    2020-05-25 02:47:34: Info: Stopping channel '' at ms82:3388
    2020-05-25 02:47:34: Debug: Stopping slave channel  for ms82:3388...
    2020-05-25 02:47:34: Info: ms82:3388: STOP SLAVE FOR CHANNEL ''
    2020-05-25 02:47:35: Info: ms82:3388: SHOW STATUS LIKE 'Slave_open_temp_tables'
    2020-05-25 02:47:35: Debug: ** Configuring ms83:3388 to replicate from ms82:3388
    2020-05-25 02:47:35: Info: Setting up async master for channel '' of ms83:3388 to ms82:3388 (user 'mysql_innodb_rs_833388')
    2020-05-25 02:47:35: Info: ms83:3388: CHANGE MASTER TO /*!80011 get_master_public_key=1, */ MASTER_HOST=/*(*/ 'ms82' /*)*/, MASTER_PORT=/*(*/ 3388 /*)*/, MASTER_USER='mysql_innodb_rs_833388', MASTER_PASSWORD=****, MASTER_AUTO_POSITION=1 FOR CHANNEL ''
    2020-05-25 02:47:36: Info: Starting replication at ms83:3388 ...
    2020-05-25 02:47:36: Debug: Starting slave channel  for ms83:3388...
    2020-05-25 02:47:36: Info: ms83:3388: START SLAVE FOR CHANNEL ''
    2020-05-25 02:47:36: Info: Clearing SUPER_READ_ONLY in new PRIMARY ms82:3388
    2020-05-25 02:47:36: Info: ms82:3388: SET PERSIST `SUPER_READ_ONLY` = 'OFF'
    2020-05-25 02:47:36: Info: ms82:3388: SET PERSIST `READ_ONLY` = 'OFF'
    2020-05-25 02:47:36: Info: ms81:3388: SET PERSIST `SUPER_READ_ONLY` = 'ON'
    2020-05-25 02:47:36: Debug: ** Changing replication source of ms81:3388 to ms82:3388
    2020-05-25 02:47:36: Info: Stopping replication at ms81:3388 ...
    2020-05-25 02:47:36: Info: Stopping channel '' at ms81:3388
    2020-05-25 02:47:36: Debug: Stopping slave channel  for ms81:3388...
    2020-05-25 02:47:36: Info: ms81:3388: STOP SLAVE FOR CHANNEL ''
    2020-05-25 02:47:36: Info: ms81:3388: SHOW STATUS LIKE 'Slave_open_temp_tables'
    2020-05-25 02:47:36: Info: Changing master address for channel '' of ms81:3388 to ms82:3388
    2020-05-25 02:47:36: Info: ms81:3388: CHANGE MASTER TO  MASTER_HOST=/*(*/ 'ms82' /*)*/, MASTER_PORT=/*(*/ 3388 /*)*/ FOR CHANNEL ''
    2020-05-25 02:47:36: Info: Starting replication at ms81:3388 ...
    2020-05-25 02:47:36: Debug: Starting slave channel  for ms81:3388...
    2020-05-25 02:47:36: Info: ms81:3388: START SLAVE FOR CHANNEL ''
    2020-05-25 02:47:37: Info: PRIMARY changed for instance ms81:3388
    2020-05-25 02:47:37: Info: Resetting slave for channel '' at ms82:3388
    2020-05-25 02:47:37: Debug: Resetting slave ALL channel '' for ms82:3388...
    2020-05-25 02:47:37: Info: ms82:3388: RESET SLAVE ALL FOR CHANNEL ''
    2020-05-25 02:47:37: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:47:37: Debug: ms82:3388 was promoted to PRIMARY.
    2020-05-25 02:47:37: Info: Releasing global locks
    2020-05-25 02:47:37: Info: ms83:3388: UNLOCK TABLES
    2020-05-25 02:47:37: Info: ms81:3388: UNLOCK TABLES
    2020-05-25 02:47:37: Info: ms82:3388: UNLOCK TABLES
    2020-05-25 02:47:37: Info: ms81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:47:37: Debug: Releasing locks for 'AdminAPI_instance' on ms81:3388.
    2020-05-25 02:47:37: Info: ms81:3388: SELECT service_release_locks('AdminAPI_instance')
    2020-05-25 02:47:37: Info: ms82:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:47:37: Debug: Releasing locks for 'AdminAPI_instance' on ms82:3388.
    2020-05-25 02:47:37: Info: ms82:3388: SELECT service_release_locks('AdminAPI_instance')
    2020-05-25 02:47:37: Info: ms83:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:47:37: Debug: Releasing locks for 'AdminAPI_instance' on ms83:3388.
    2020-05-25 02:47:37: Info: ms83:3388: SELECT service_release_locks('AdminAPI_instance')

    ```

- 再一次switchover
    ```
    MySQL  192.168.188.82:3388 ssl  JS > sh.setPrimaryInstance('ms81:3388')
    ms81:3388 will be promoted to PRIMARY of 'kk'.
    The current PRIMARY is ms82:3388.

    * Connecting to replicaset instances
    ** Connecting to ms81:3388
    ** Connecting to ms82:3388
    ** Connecting to ms83:3388
    ** Connecting to ms81:3388
    ** Connecting to ms82:3388
    ** Connecting to ms83:3388

    * Performing validation checks
    ** Checking async replication topology...
    ** Checking transaction state of the instance...

    * Synchronizing transaction backlog at ms81:3388

    * Updating metadata

    * Acquiring locks in replicaset instances
    ** Pre-synchronizing SECONDARIES
    ** Acquiring global lock at PRIMARY
    ** Acquiring global lock at SECONDARIES

    * Updating replication topology
    ** Configuring ms82:3388 to replicate from ms81:3388
    ** Changing replication source of ms83:3388 to ms81:3388

    ms81:3388 was promoted to PRIMARY.
    ```
- 日志
    ```
    2020-05-25 02:47:56: Debug: Refreshing metadata cache
    2020-05-25 02:47:56: Info: ms82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:47:56: Info: ms82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:47:56: Info: ms82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:56: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:47:56: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:47:56: Info: ms82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:56: Info: ms82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:47:56: Info: ms82:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:47:56: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:47:56: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:47:56: Info: 192.168.188.82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:47:56: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:56: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:47:56: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:47:56: Info: 192.168.188.82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:56: Debug: Instance type check: ms82:3388: Metadata version 2.0.0 found
    2020-05-25 02:47:56: Info: 192.168.188.82:3388: select cluster_type from `mysql_innodb_cluster_metadata`.v2_this_instance
    2020-05-25 02:47:56: Debug: Instance type check: ms82:3388: ReplicaSet metadata record found (metadata 2.0.0)
    2020-05-25 02:47:56: Debug: Instance f6f42ea6-9b2d-11ea-a229-0242c0a8bc52 is managed for ASYNC-REPLICATION
    2020-05-25 02:47:56: Info: 192.168.188.82:3388: select count(*) from performance_schema.replication_group_members where MEMBER_ID = @@server_uuid AND MEMBER_STATE IS NOT NULL AND MEMBER_STATE <> 'OFFLINE'
    2020-05-25 02:47:56: Debug: Instance type check: ms82:3388: GR is installed but not active
    2020-05-25 02:47:56: Info: 192.168.188.82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.mysql_server_uuid = 'f6f42ea6-9b2d-11ea-a229-0242c0a8bc52'
    2020-05-25 02:47:56: Info: ms82:3388: SELECT view_id, member_id FROM  mysql_innodb_cluster_metadata.v2_ar_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND member_role = 'PRIMARY'
    2020-05-25 02:47:56: Info: ms82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:56: Info: ms82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:56: Info: ms82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:56: Info: ms82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:56: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:47:56: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:47:56: Debug: Refreshing metadata cache
    2020-05-25 02:47:56: Info: ms82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:47:56: Info: ms82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:47:56: Info: ms82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:56: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:47:56: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:47:56: Info: ms82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:56: Info: ms82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id
    2020-05-25 02:47:56: Info: ms82:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c
    2020-05-25 02:47:56: Info: Connected to replicaset PRIMARY instance ms82:3388
    2020-05-25 02:47:56: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('version_compile_os')
    2020-05-25 02:47:56: Info: ms82:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:47:56: Debug: Acquiring EXCLUSIVE lock ('AdminAPI_instance', 'AdminAPI_lock') on ms82:3388.
    2020-05-25 02:47:56: Info: ms82:3388: SELECT service_get_write_locks('AdminAPI_instance', 'AdminAPI_lock', 0)
    2020-05-25 02:47:56: Info: ms82:3388: SELECT view_id, member_id FROM  mysql_innodb_cluster_metadata.v2_ar_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND member_role = 'PRIMARY'
    2020-05-25 02:47:56: Info: ms82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:56: Info: ms81:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:56: Info: ms81:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:56: Info: ms81:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:56: Info: ms81:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:56: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:47:56: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:47:56: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:47:56: Info: ms81:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:47:56: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:56: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:47:56: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:47:56: Info: ms81:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:56: Info: ms81:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:56: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:47:56: Info: ms82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:56: Info: ms82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:56: Info: ms82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:56: Info: ms82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:56: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:47:56: Debug: Metadata operations will use ms82:3388
    2020-05-25 02:47:56: Info: ms82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:47:56: Info: ms82:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:47:56: Info: ms82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:56: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:47:56: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:47:56: Info: ms82:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:56: Info: ms82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:56: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:47:56: Info: ms83:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:56: Info: ms83:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:56: Info: ms83:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:56: Info: ms83:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:56: Info: ms83:3388: SELECT @@server_uuid
    2020-05-25 02:47:56: Debug: Metadata operations will use ms83:3388
    2020-05-25 02:47:56: Info: ms83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata'
    2020-05-25 02:47:56: Info: ms83:3388: SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata_bkp'
    2020-05-25 02:47:56: Info: ms83:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:56: Info: Detecting state of failed MD schema upgrade... schema_version=2.0.0, target_version=2.0.0, backup_exists=0, saved_stage=null
    2020-05-25 02:47:56: Info: Failed MD schema upgrade detected to be in stage OK
    2020-05-25 02:47:56: Info: ms83:3388: SELECT `major`, `minor`, `patch` FROM `mysql_innodb_cluster_metadata`.`schema_version`
    2020-05-25 02:47:56: Info: ms83:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE `i`.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:56: Info: ms82:3388: SELECT * FROM (
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, NULL as group_name, async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_ar_clusters
    UNION ALL
    SELECT cluster_type, primary_mode, cluster_id, cluster_name,
        description, group_name, NULL as async_topology_type
    FROM mysql_innodb_cluster_metadata.v2_gr_clusters
    ) as c WHERE c.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:56: Info: ms82:3388: SELECT i.instance_id, i.cluster_id, am.master_instance_id, am.master_member_id, am.member_role, am.view_id,  i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:56: Debug: 3 instances in replicaset kk
    2020-05-25 02:47:56: Debug: Scanning state of replicaset ms81:3388
    2020-05-25 02:47:56: Debug: Connecting to ms81:3388
    2020-05-25 02:47:56: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:47:56: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:47:56: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:47:56: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:47:56: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:56: Info: ms81:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:47:56: Info: channel '' at ms81:3388 with source_uuid: f6f42ea6-9b2d-11ea-a229-0242c0a8bc52, master ms82:3388 (running)
    2020-05-25 02:47:56: Info: ms81:3388: SELECT * FROM mysql.slave_master_info WHERE channel_name = ''
    2020-05-25 02:47:56: Info: ms81:3388: SELECT * FROM mysql.slave_relay_log_info WHERE channel_name = ''
    2020-05-25 02:47:56: Info: ms81:3388: SHOW SLAVE HOSTS
    2020-05-25 02:47:56: Debug: Scanning state of replicaset ms82:3388
    2020-05-25 02:47:56: Debug: Connecting to ms82:3388
    2020-05-25 02:47:56: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:47:56: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:47:56: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:47:56: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:47:56: Info: ms82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:56: Info: ms82:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:47:56: Info: ms82:3388: SHOW SLAVE HOSTS
    2020-05-25 02:47:56: Info: ms82:3388 has 2 instances replicating from it
    2020-05-25 02:47:56: Debug: Scanning state of replicaset ms83:3388
    2020-05-25 02:47:56: Debug: Connecting to ms83:3388
    2020-05-25 02:47:56: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:47:56: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('offline_mode')
    2020-05-25 02:47:56: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('read_only')
    2020-05-25 02:47:56: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('super_read_only')
    2020-05-25 02:47:56: Info: ms83:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:56: Info: ms83:3388: SELECT
        c.channel_name, c.host, c.port, c.user,
        s.source_uuid, s.group_name, s.last_heartbeat_timestamp,
        s.service_state io_state, st.processlist_state io_thread_state,
        s.last_error_number io_errno, s.last_error_message io_errmsg,
        s.last_error_timestamp io_errtime,
        co.service_state co_state, cot.processlist_state co_thread_state,
        co.last_error_number co_errno, co.last_error_message co_errmsg,
        co.last_error_timestamp co_errtime,
        w.service_state w_state, wt.processlist_state w_thread_state,
        w.last_error_number w_errno, w.last_error_message w_errmsg,
        w.last_error_timestamp w_errtime,
        /*!80011 TIMEDIFF(NOW(6),
        IF(TIMEDIFF(s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP) >= 0,
            s.LAST_QUEUED_TRANSACTION_START_QUEUE_TIMESTAMP,
            s.LAST_HEARTBEAT_TIMESTAMP
        )) as time_since_last_message,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        'IDLE',
        'APPLYING') as applier_busy_state,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_ORIGINAL_COMMIT_TIMESTAMP)
        ) as lag_from_original,
        IF(s.LAST_QUEUED_TRANSACTION='' OR s.LAST_QUEUED_TRANSACTION=latest_w.LAST_APPLIED_TRANSACTION,
        NULL,
        TIMEDIFF(latest_w.LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP,
            latest_w.LAST_APPLIED_TRANSACTION_IMMEDIATE_COMMIT_TIMESTAMP)
        ) as lag_from_immediate,
        */
        GTID_SUBTRACT(s.RECEIVED_TRANSACTION_SET, @@global.gtid_executed)
        as queued_gtid_set_to_apply
    FROM performance_schema.replication_connection_configuration c
    JOIN performance_schema.replication_connection_status s
        ON c.channel_name = s.channel_name
    LEFT JOIN performance_schema.replication_applier_status_by_coordinator co
        ON c.channel_name = co.channel_name
    JOIN performance_schema.replication_applier_status a
        ON c.channel_name = a.channel_name
    JOIN performance_schema.replication_applier_status_by_worker w
        ON c.channel_name = w.channel_name
    LEFT JOIN
    /* if parallel replication, fetch owner of most recently applied tx */
        (SELECT *
        FROM performance_schema.replication_applier_status_by_worker
        /*!80011 ORDER BY LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP DESC */
        LIMIT 1) latest_w
        ON c.channel_name = latest_w.channel_name
    LEFT JOIN performance_schema.threads st
        ON s.thread_id = st.thread_id
    LEFT JOIN performance_schema.threads cot
        ON co.thread_id = cot.thread_id
    LEFT JOIN performance_schema.threads wt
        ON w.thread_id = wt.thread_id
    ORDER BY channel_name
    2020-05-25 02:47:56: Info: channel '' at ms83:3388 with source_uuid: f6f42ea6-9b2d-11ea-a229-0242c0a8bc52, master ms82:3388 (running)
    2020-05-25 02:47:56: Info: ms83:3388: SELECT * FROM mysql.slave_master_info WHERE channel_name = ''
    2020-05-25 02:47:56: Info: ms83:3388: SELECT * FROM mysql.slave_relay_log_info WHERE channel_name = ''
    2020-05-25 02:47:56: Info: ms83:3388: SHOW SLAVE HOSTS
    2020-05-25 02:47:56: Info: ms83:3388 has 2 instances replicating from it
    2020-05-25 02:47:56: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:47:56: Debug: ms81:3388 will be promoted to PRIMARY of 'kk'.
    The current PRIMARY is ms82:3388.

    2020-05-25 02:47:56: Debug: * Connecting to replicaset instances
    2020-05-25 02:47:56: Info: ms82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:56: Debug: ** Connecting to ms81:3388
    2020-05-25 02:47:56: Debug: ** Connecting to ms82:3388
    2020-05-25 02:47:56: Debug: ** Connecting to ms83:3388
    2020-05-25 02:47:56: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:47:56: Info: ms81:3388: show GLOBAL variables where `variable_name` in ('version_compile_os')
    2020-05-25 02:47:56: Info: ms81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:47:56: Debug: Acquiring EXCLUSIVE lock ('AdminAPI_instance', 'AdminAPI_lock') on ms81:3388.
    2020-05-25 02:47:56: Info: ms81:3388: SELECT service_get_write_locks('AdminAPI_instance', 'AdminAPI_lock', 0)
    2020-05-25 02:47:56: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:47:56: Info: ms83:3388: SELECT @@server_uuid
    2020-05-25 02:47:56: Info: ms83:3388: show GLOBAL variables where `variable_name` in ('version_compile_os')
    2020-05-25 02:47:56: Info: ms83:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:47:56: Debug: Acquiring EXCLUSIVE lock ('AdminAPI_instance', 'AdminAPI_lock') on ms83:3388.
    2020-05-25 02:47:56: Info: ms83:3388: SELECT service_get_write_locks('AdminAPI_instance', 'AdminAPI_lock', 0)
    2020-05-25 02:47:56: Info: ms82:3388: SELECT i.instance_id, i.cluster_id, c.group_name, am.master_instance_id, am.master_member_id, am.member_role, am.view_id, i.label, i.mysql_server_uuid, i.address, i.endpoint, i.xendpoint, '' as grendpoint FROM mysql_innodb_cluster_metadata.v2_instances i LEFT JOIN mysql_innodb_cluster_metadata.v2_gr_clusters c   ON c.cluster_id = i.cluster_id LEFT JOIN mysql_innodb_cluster_metadata.v2_ar_members am   ON am.instance_id = i.instance_id WHERE i.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:56: Debug: ** Connecting to ms81:3388
    2020-05-25 02:47:56: Info: ms81:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:56: Info: ms81:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:56: Info: ms81:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:56: Info: ms81:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:56: Info: ms81:3388: SELECT @@server_uuid
    2020-05-25 02:47:56: Debug: ** Connecting to ms82:3388
    2020-05-25 02:47:56: Info: ms82:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:56: Info: ms82:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:56: Info: ms82:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:56: Info: ms82:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:56: Info: ms82:3388: SELECT @@server_uuid
    2020-05-25 02:47:56: Debug: ** Connecting to ms83:3388
    2020-05-25 02:47:56: Info: ms83:3388: SET SESSION `autocommit` = 1
    2020-05-25 02:47:56: Info: ms83:3388: SET SESSION `sql_mode` = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
    2020-05-25 02:47:56: Info: ms83:3388: SET SESSION `group_replication_consistency` = 'EVENTUAL'
    2020-05-25 02:47:56: Info: ms83:3388: SELECT COALESCE(@@report_host, @@hostname),  COALESCE(@@report_port, @@port)
    2020-05-25 02:47:56: Info: ms83:3388: SELECT @@server_uuid
    2020-05-25 02:47:56: Debug: * Performing validation checks
    2020-05-25 02:47:56: Debug: ** Checking async replication topology...
    2020-05-25 02:47:56: Debug: ** Checking transaction state of the instance...
    2020-05-25 02:47:56: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:56: Info: ms82:3388: SELECT GTID_SUBTRACT(@@global.gtid_purged, 'f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-5')
    2020-05-25 02:47:56: Info: ms81:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:56: Info: ms82:3388: SELECT GTID_SUBTRACT('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-5', @@global.gtid_executed)
    2020-05-25 02:47:56: Info: ms83:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:56: Info: ms82:3388: SELECT GTID_SUBTRACT(@@global.gtid_purged, 'f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-5')
    2020-05-25 02:47:56: Info: ms83:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:56: Info: ms82:3388: SELECT GTID_SUBTRACT('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-5', @@global.gtid_executed)
    2020-05-25 02:47:56: Debug: * Synchronizing transaction backlog at ms81:3388
    2020-05-25 02:47:56: Info: ms82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:56: Info: ms81:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-5', 10)
    2020-05-25 02:47:56: Debug: * Updating metadata
    2020-05-25 02:47:56: Info: ms82:3388: show GLOBAL variables where `variable_name` in ('server_id')
    2020-05-25 02:47:56: Info: Resetting password for mysql_innodb_rs_823388@% at ms82:3388
    2020-05-25 02:47:56: Info: ms82:3388: SET PASSWORD FOR 'mysql_innodb_rs_823388'@'%' = ****
    2020-05-25 02:47:56: Info: Updating metadata at ms82:3388
    2020-05-25 02:47:56: Info: ms82:3388: START TRANSACTION
    2020-05-25 02:47:56: Info: ms82:3388: SELECT c.cluster_id, c.async_topology_type FROM mysql_innodb_cluster_metadata.v2_ar_clusters c JOIN mysql_innodb_cluster_metadata.v2_ar_members m   ON c.cluster_id = m.cluster_id WHERE m.instance_id = 1
    2020-05-25 02:47:56: Info: ms82:3388: SELECT m.instance_id FROM mysql_innodb_cluster_metadata.v2_ar_members m WHERE m.cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND m.member_role = 'PRIMARY'
    2020-05-25 02:47:56: Info: ms82:3388: SELECT MAX(view_id) FROM mysql_innodb_cluster_metadata.async_cluster_views WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51'
    2020-05-25 02:47:56: Debug: Updating metadata for async cluster SWITCH_ACTIVE view d10f0970-9e2f-11ea-a355-0242c0a8bc51,65539
    2020-05-25 02:47:56: Info: ms82:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_views (cluster_id, view_id, topology_type,  view_change_reason, view_change_time, view_change_info,  attributes) SELECT cluster_id, 65539, topology_type, 'SWITCH_ACTIVE', NOW(6), JSON_OBJECT('user', USER(),   'source', @@server_uuid), attributes FROM mysql_innodb_cluster_metadata.async_cluster_views WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 65538
    2020-05-25 02:47:56: Info: ms82:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_members (cluster_id, view_id, instance_id, master_instance_id,    primary_master, attributes) SELECT cluster_id, 65539, instance_id, NULL, 1, attributes FROM mysql_innodb_cluster_metadata.async_cluster_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 65538 AND instance_id = 1
    2020-05-25 02:47:56: Info: ms82:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_members (cluster_id, view_id, instance_id, master_instance_id,    primary_master, attributes) SELECT cluster_id, 65539, instance_id, 1, 0, attributes FROM mysql_innodb_cluster_metadata.async_cluster_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 65538 AND instance_id = 2
    2020-05-25 02:47:56: Info: ms82:3388: INSERT INTO mysql_innodb_cluster_metadata.async_cluster_members (cluster_id, view_id, instance_id, master_instance_id,    primary_master, attributes) SELECT cluster_id, 65539, instance_id, 1,     IF(instance_id = 1, 1, 0), attributes FROM mysql_innodb_cluster_metadata.async_cluster_members WHERE cluster_id = 'd10f0970-9e2f-11ea-a355-0242c0a8bc51' AND view_id = 65538   AND instance_id NOT IN (1, 2)
    2020-05-25 02:47:56: Info: ms82:3388: COMMIT
    2020-05-25 02:47:56: Debug: * Acquiring locks in replicaset instances
    2020-05-25 02:47:56: Debug: ** Pre-synchronizing SECONDARIES
    2020-05-25 02:47:56: Info: ms82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:56: Info: ms81:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf6f42ea6-9b2d-11ea-a229-0242c0a8bc52:1-2,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-5', 60)
    2020-05-25 02:47:56: Info: ms83:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf6f42ea6-9b2d-11ea-a229-0242c0a8bc52:1-2,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-5', 60)
    2020-05-25 02:47:57: Debug: ** Acquiring global lock at PRIMARY
    2020-05-25 02:47:57: Info: ms82:3388: FLUSH TABLES WITH READ LOCK
    2020-05-25 02:47:57: Info: ms82:3388: SET global super_read_only=1
    2020-05-25 02:47:57: Info: ms82:3388: FLUSH BINARY LOGS
    2020-05-25 02:47:57: Debug: ** Acquiring global lock at SECONDARIES
    2020-05-25 02:47:57: Info: ms82:3388: SELECT @@GLOBAL.GTID_EXECUTED
    2020-05-25 02:47:57: Info: ms81:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf6f42ea6-9b2d-11ea-a229-0242c0a8bc52:1-2,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-5', 60)
    2020-05-25 02:47:57: Info: ms81:3388: FLUSH TABLES WITH READ LOCK
    2020-05-25 02:47:57: Info: ms83:3388: SELECT WAIT_FOR_EXECUTED_GTID_SET('f1847297-9b2d-11ea-ba52-0242c0a8bc51:1-44,\nf6f42ea6-9b2d-11ea-a229-0242c0a8bc52:1-2,\nf8825c7a-9b2d-11ea-8956-0242c0a8bc53:1-5', 60)
    2020-05-25 02:47:57: Info: ms83:3388: FLUSH TABLES WITH READ LOCK
    2020-05-25 02:47:57: Debug: * Updating replication topology
    2020-05-25 02:47:57: Info: Enabling SUPER_READ_ONLY in old PRIMARY ms82:3388
    2020-05-25 02:47:57: Info: ms82:3388: SET PERSIST `SUPER_READ_ONLY` = 'ON'
    2020-05-25 02:47:57: Info: Stopping channel '' at ms81:3388
    2020-05-25 02:47:57: Debug: Stopping slave channel  for ms81:3388...
    2020-05-25 02:47:57: Info: ms81:3388: STOP SLAVE FOR CHANNEL ''
    2020-05-25 02:47:58: Info: ms81:3388: SHOW STATUS LIKE 'Slave_open_temp_tables'
    2020-05-25 02:47:58: Debug: ** Configuring ms82:3388 to replicate from ms81:3388
    2020-05-25 02:47:58: Info: Setting up async master for channel '' of ms82:3388 to ms81:3388 (user 'mysql_innodb_rs_823388')
    2020-05-25 02:47:58: Info: ms82:3388: CHANGE MASTER TO /*!80011 get_master_public_key=1, */ MASTER_HOST=/*(*/ 'ms81' /*)*/, MASTER_PORT=/*(*/ 3388 /*)*/, MASTER_USER='mysql_innodb_rs_823388', MASTER_PASSWORD=****, MASTER_AUTO_POSITION=1 FOR CHANNEL ''
    2020-05-25 02:47:59: Info: Starting replication at ms82:3388 ...
    2020-05-25 02:47:59: Debug: Starting slave channel  for ms82:3388...
    2020-05-25 02:47:59: Info: ms82:3388: START SLAVE FOR CHANNEL ''
    2020-05-25 02:47:59: Info: Clearing SUPER_READ_ONLY in new PRIMARY ms81:3388
    2020-05-25 02:47:59: Info: ms81:3388: SET PERSIST `SUPER_READ_ONLY` = 'OFF'
    2020-05-25 02:47:59: Info: ms81:3388: SET PERSIST `READ_ONLY` = 'OFF'
    2020-05-25 02:47:59: Info: ms83:3388: SET PERSIST `SUPER_READ_ONLY` = 'ON'
    2020-05-25 02:47:59: Debug: ** Changing replication source of ms83:3388 to ms81:3388
    2020-05-25 02:47:59: Info: Stopping replication at ms83:3388 ...
    2020-05-25 02:47:59: Info: Stopping channel '' at ms83:3388
    2020-05-25 02:47:59: Debug: Stopping slave channel  for ms83:3388...
    2020-05-25 02:47:59: Info: ms83:3388: STOP SLAVE FOR CHANNEL ''
    2020-05-25 02:47:59: Info: ms83:3388: SHOW STATUS LIKE 'Slave_open_temp_tables'
    2020-05-25 02:47:59: Info: Changing master address for channel '' of ms83:3388 to ms81:3388
    2020-05-25 02:47:59: Info: ms83:3388: CHANGE MASTER TO  MASTER_HOST=/*(*/ 'ms81' /*)*/, MASTER_PORT=/*(*/ 3388 /*)*/ FOR CHANNEL ''
    2020-05-25 02:47:59: Info: Starting replication at ms83:3388 ...
    2020-05-25 02:47:59: Debug: Starting slave channel  for ms83:3388...
    2020-05-25 02:47:59: Info: ms83:3388: START SLAVE FOR CHANNEL ''
    2020-05-25 02:48:00: Info: PRIMARY changed for instance ms83:3388
    2020-05-25 02:48:00: Info: Resetting slave for channel '' at ms81:3388
    2020-05-25 02:48:00: Debug: Resetting slave ALL channel '' for ms81:3388...
    2020-05-25 02:48:00: Info: ms81:3388: RESET SLAVE ALL FOR CHANNEL ''
    2020-05-25 02:48:00: Debug: Metadata operations will use ms81:3388
    2020-05-25 02:48:00: Debug: ms81:3388 was promoted to PRIMARY.
    2020-05-25 02:48:00: Info: Releasing global locks
    2020-05-25 02:48:00: Info: ms82:3388: UNLOCK TABLES
    2020-05-25 02:48:00: Info: ms81:3388: UNLOCK TABLES
    2020-05-25 02:48:00: Info: ms83:3388: UNLOCK TABLES
    2020-05-25 02:48:00: Info: ms81:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:48:00: Debug: Releasing locks for 'AdminAPI_instance' on ms81:3388.
    2020-05-25 02:48:00: Info: ms81:3388: SELECT service_release_locks('AdminAPI_instance')
    2020-05-25 02:48:00: Info: ms83:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:48:00: Debug: Releasing locks for 'AdminAPI_instance' on ms83:3388.
    2020-05-25 02:48:00: Info: ms83:3388: SELECT service_release_locks('AdminAPI_instance')
    2020-05-25 02:48:00: Info: ms82:3388: SELECT COUNT(*) FROM mysql.func WHERE dl = /*(*/ 'locking_service.so' /*(*/ AND name IN ('service_get_read_locks', 'service_get_write_locks', 'service_release_locks')
    2020-05-25 02:48:00: Debug: Releasing locks for 'AdminAPI_instance' on ms82:3388.
    2020-05-25 02:48:00: Info: ms82:3388: SELECT service_release_locks('AdminAPI_instance')

    ```















