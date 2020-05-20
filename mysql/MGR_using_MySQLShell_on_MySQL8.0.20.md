> 本篇知识点：
> - 配置MGR所需的参数
> - 使用MySQL Shell配置MGR
> 	- shell.connect()
> 	- var 设定临时变量
> 	- dba.createCluster()
> 	- dba.getCluster()
> 	- dba.addInstance()
>	- dba.removeInstance()
>	- dba.switchToMultiPrimaryMode()
>	- dba.switchToSinglePrimaryMode()
> - 完全依靠MySQL Shell自动生成参数究竟靠不靠谱？
>	- 可以在一定程度上靠谱，不要完全依赖这东西。
> - MGR 原理探索  

[TOC]

# 环境信息
|IP|port|role|info|
|-|-|-|-|
|192.168.188.81|3306|node1|null|
|192.168.188.82|3306|node2|null|
|192.168.188.83|3306|node3|null|

- CentOS Linux release 7.6.1810 (Core)
- MySQL Ver 8.0.20 for Linux on x86_64 (MySQL Community Server - GPL)
- MySQL Router  Ver 8.0.20 for Linux on x86_64 (MySQL Community - GPL)
- MySQL Shell   Ver 8.0.20 for Linux on x86_64 - for MySQL 8.0.20 (MySQL Community Server (GPL))


# 软件位置
在三个节点上部署好MySQL、MySQL Router、MySQL Shell。
```
[root@ms81 opt]# ln -s /opt/mysql-router-8.0.20-linux-glibc2.12-x86_64 /usr/local/myrouter
[root@ms81 opt]# ln -s /opt/mysql-shell-8.0.20-linux-glibc2.12-x86-64bit /usr/local/mysh
[root@ms81 opt]# ln -s /opt/mysql-8.0.20-linux-glibc2.12-x86_64 /usr/local/mysql
[root@ms81 opt]# ll /usr/local/
total 40
drwxr-xr-x 2 root root 4096 Apr 11  2018 bin
drwxr-xr-x 2 root root 4096 Apr 11  2018 etc
drwxr-xr-x 2 root root 4096 Apr 11  2018 games
drwxr-xr-x 2 root root 4096 Apr 11  2018 include
drwxr-xr-x 2 root root 4096 Apr 11  2018 lib
drwxr-xr-x 2 root root 4096 Apr 11  2018 lib64
drwxr-xr-x 2 root root 4096 Apr 11  2018 libexec
lrwxrwxrwx 1 root root   47 May  3 20:18 myrouter -> /opt/mysql-router-8.0.20-linux-glibc2.12-x86_64
lrwxrwxrwx 1 root root   49 May  3 20:18 mysh -> /opt/mysql-shell-8.0.20-linux-glibc2.12-x86-64bit
lrwxrwxrwx 1 root root   41 May  3 20:12 mysql -> /opt/mysql-8.0.20-linux-glibc2.12-x86_64/
drwxr-xr-x 2 root root 4096 Apr 11  2018 sbin
drwxr-xr-x 5 root root 4096 Dec  4  2018 share
drwxr-xr-x 2 root root 4096 Apr 11  2018 src
```

# 配置MySQL参数
以支持启用MGR.
```
[root@ms81 ~]# uuidgen
78cba89c-7a2c-4442-ba43-51aa387a4fd0

## add to my3306.cnf
binlog_checksum=none
binlog_transaction_dependency_tracking=WRITESET
transaction_write_set_extraction=XXHASH64
loose-group_replication_group_name="78cba89c-7a2c-4442-ba43-51aa387a4fd0"  #must be use UUID format
loose-group_replication_start_on_boot=off
loose-group_replication_local_address="192.168.188.81:13306"
loose-group_replication_group_seeds="192.168.188.81:13306,192.168.188.82:13306,192.168.188.83:13306"
loose-group_replication_bootstrap_group=off

```
启动实例。

# 配置数据库
以下操作需要在所有节点进行。
```
[root@ms81 ~]# mysql -S /data/mysql/mysql3306/tmp/mysql.sock
mysql> set global super_read_only=0;
Query OK, 0 rows affected (0.00 sec)

mysql> create user kk@'%' identified by 'kk';
Query OK, 0 rows affected (0.02 sec)

mysql> grant all privileges on *.* to kk@'%' with grant option;
Query OK, 0 rows affected (0.02 sec)

mysql> reset master;
Query OK, 0 rows affected (0.04 sec)

```

# 使用MySQL Shell配置MGR

操作只需要在node1上操作即可。
```
[root@ms81 ~]# mysqlsh
\MySQL Shell 8.0.20

Copyright (c) 2016, 2020, Oracle and/or its affiliates. All rights reserved.
Oracle is a registered trademark of Oracle Corporation and/or its affiliates.
Other names may be trademarks of their respective owners.

Type '\help' or '\?' for help; '\quit' to exit.
 MySQL  JS >
```
不要慌。

mysh支持tab补齐。

- 下面开始配置
```
 MySQL  JS > shell.connect('kk@192.168.188.81:3306')    #连接到实例
Creating a session to 'kk@192.168.188.81:3306'
Please provide the password for 'kk@192.168.188.81:3306': **
Save password for 'kk@192.168.188.81:3306'? [Y]es/[N]o/Ne[v]er (default No): y
Fetching schema names for autocompletion... Press ^C to stop.
Your MySQL connection id is 10
Server version: 8.0.20 MySQL Community Server - GPL
No default schema selected; type \use <schema> to set one.
<ClassicSession:kk@192.168.188.81:3306>

 MySQL  192.168.188.81:3306 ssl  JS > var c = dba.createCluster('kkcc')   #创建cluster
A new InnoDB cluster will be created on instance '192.168.188.81:3306'.

Validating instance configuration at 192.168.188.81:3306...

This instance reports its own address as ms81:3306

Instance configuration is suitable.
NOTE: Group Replication will communicate with other members using 'ms81:33061'. Use the localAddress option to override.

Creating InnoDB cluster 'kkcc' on 'ms81:3306'...

Adding Seed Instance...
Cluster successfully created. Use Cluster.addInstance() to add MySQL instances.
At least 3 instances are needed for the cluster to be able to withstand up to
one server failure.

 MySQL  192.168.188.81:3306 ssl  JS > c.  		#试一下tab补齐
addInstance()                    listRouters()                    setInstanceOption()
checkInstanceState()             name                             setOption()
describe()                       options()                        setPrimaryInstance()
disconnect()                     rejoinInstance()                 setupAdminAccount()
dissolve()                       removeInstance()                 setupRouterAccount()
forceQuorumUsingPartitionOf()    removeRouterMetadata()           status()
getName()                        rescan()                         switchToMultiPrimaryMode()
help()                           resetRecoveryAccountsPassword()  switchToSinglePrimaryMode()

 MySQL  192.168.188.81:3306 ssl  JS > c.addInstance('kk@192.168.188.82:3306')	#添加节点到集群
Please provide the password for 'kk@192.168.188.82:3306': **
Save password for 'kk@192.168.188.82:3306'? [Y]es/[N]o/Ne[v]er (default No): y

NOTE: The target instance 'ms82:3306' has not been pre-provisioned (GTID set is empty). The Shell is unable to decide whether incremental state recovery can correctly provision it.
The safest and most convenient way to provision a new instance is through automatic clone provisioning, which will completely overwrite the state of 'ms82:3306' with a physical snapshot from an existing cluster member. To use this method by default, set the 'recoveryMethod' option to 'clone'.

The incremental state recovery may be safely used if you are sure all updates ever executed in the cluster were done with GTIDs enabled, there are no purged transactions and the new instance contains the same GTID set as the cluster or a subset of it. To use this method by default, set the 'recoveryMethod' option to 'incremental'.


Please select a recovery method [C]lone/[I]ncremental recovery/[A]bort (default Clone): C
NOTE: Group Replication will communicate with other members using 'ms82:33061'. Use the localAddress option to override.

Validating instance configuration at 192.168.188.82:3306...

This instance reports its own address as ms82:3306

Instance configuration is suitable.
A new instance will be added to the InnoDB cluster. Depending on the amount of
data on the cluster this might take from a few seconds to several hours.

Adding instance to the cluster...

Monitoring recovery process of the new cluster member. Press ^C to stop monitoring and let it continue in background.
Clone based state recovery is now in progress.

NOTE: A server restart is expected to happen as part of the clone process. If the
server does not support the RESTART command or does not come back after a
while, you may need to manually start it back.

* Waiting for clone to finish...
NOTE: ms82:3306 is being cloned from ms81:3306
** Stage DROP DATA: Completed
** Clone Transfer
    FILE COPY  ############################################################  100%  Completed
    PAGE COPY  ############################################################  100%  Completed
    REDO COPY  ############################################################  100%  Completed

NOTE: ms82:3306 is shutting down...


##############然后等待一会……漫长的等待
##############结果出现了奇怪的提示：

* Waiting for server restart... timeout
WARNING: Clone process appears to have finished and tried to restart the MySQL server, but it has not yet started back up.

Please make sure the MySQL server at 'ms82:3306' is restarted and call <Cluster>.rescan() to complete the process. To increase the timeout, change shell.options["dba.restartWaitTimeout"].
Cluster.addInstance: Timeout waiting for server to restart (MYSQLSH 51156)
```
MySQL实例自己完成Clone，而后重启，然而重启失败。

仔细想想，mysqld启动的服务进程怎么做到重启呢？
后经过查询得知，该提示并不是失败，只是没有监控进程重启mysqld而已。
那么用mysqld_safe是不是就好了？一会试一下。

- 查看一下状态
```
 MySQL  192.168.188.81:3306 ssl  JS > c.status()
{
    "clusterName": "kkcc",
    "defaultReplicaSet": {
        "name": "default",
        "primary": "ms81:3306",
        "ssl": "REQUIRED",
        "status": "OK_NO_TOLERANCE",
        "statusText": "Cluster is NOT tolerant to any failures.",
        "topology": {
            "ms81:3306": {
                "address": "ms81:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}
 MySQL  192.168.188.81:3306 ssl  JS >
```
- 手动去node2上启动mysqld
```
[root@ms82 ~]#  mysqld --defaults-file=/data/mysql/mysql3306/my3306.cnf  &
```
- 再回来node1上使用mysh查询MGR状态
```
 MySQL  192.168.188.81:3306 ssl  JS > c.status()
{
    "clusterName": "kkcc",
    "defaultReplicaSet": {
        "name": "default",
        "primary": "ms81:3306",
        "ssl": "REQUIRED",
        "status": "OK_NO_TOLERANCE",
        "statusText": "Cluster is NOT tolerant to any failures.",
        "topology": {
            "ms81:3306": {
                "address": "ms81:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}
```
怎么回事呢？没加上？
重加一下试试
```
 MySQL  192.168.188.81:3306 ssl  JS > c.addInstance('kk@192.168.188.82:3306')
ERROR: Instance 'ms82:3306' is part of the Group Replication group but is not in the metadata. Please use <Cluster>.rescan() to update the metadata.
Cluster.addInstance: Metadata inconsistent (RuntimeError)
```
不得不说mysh做的还不错，提示信息非常给力。
```
 MySQL  192.168.188.81:3306 ssl  JS > c.rescan()
Rescanning the cluster...

Result of the rescanning operation for the 'kkcc' cluster:
{
    "name": "kkcc",
    "newTopologyMode": null,
    "newlyDiscoveredInstances": [
        {
            "host": "ms82:3306",
            "member_id": "12a0149c-8d3a-11ea-b02e-0242c0a8bc52",
            "name": null,
            "version": "8.0.20"
        }
    ],
    "unavailableInstances": []
}

A new instance 'ms82:3306' was discovered in the cluster.
Would you like to add it to the cluster metadata? [Y/n]: y
Adding instance to the cluster metadata...
The instance 'ms82:3306' was successfully added to the cluster metadata.

 MySQL  192.168.188.81:3306 ssl  JS > c.status()
{
    "clusterName": "kkcc",
    "defaultReplicaSet": {
        "name": "default",
        "primary": "ms81:3306",
        "ssl": "REQUIRED",
        "status": "OK_NO_TOLERANCE",
        "statusText": "Cluster is NOT tolerant to any failures.",
        "topology": {
            "ms81:3306": {
                "address": "ms81:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            },
            "ms82:3306": {
                "address": "ms82:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}
```

就是这么简单？！

- 故技重施，将node3加进来。

在这里我决定验证一下自己的猜测，将node3使用mysqld_safe的方式启动后，再加入集群。
```
[root@ms83 ~]#  mysqld_safe --defaults-file=/data/mysql/mysql3306/my3306.cnf  &
[2] 68
[root@ms83 ~]# 2020-05-03T12:49:40.439139Z mysqld_safe Logging to '/data/mysql/mysql3306/logs/error.log'.
2020-05-03T12:49:40.471550Z mysqld_safe Starting mysqld daemon with databases from /data/mysql/mysql3306/data

[root@ms83 ~]#  mysql -S /data/mysql/mysql3306/tmp/mysql.sock
mysql> set global super_read_only=0;
Query OK, 0 rows affected (0.00 sec)


 MySQL  192.168.188.81:3306 ssl  JS > c.addInstance('kk@192.168.188.83:3306')

NOTE: The target instance 'ms83:3306' has not been pre-provisioned (GTID set is empty). The Shell is unable to decide whether incremental state recovery can correctly provision it.
The safest and most convenient way to provision a new instance is through automatic clone provisioning, which will completely overwrite the state of 'ms83:3306' with a physical snapshot from an existing cluster member. To use this method by default, set the 'recoveryMethod' option to 'clone'.

The incremental state recovery may be safely used if you are sure all updates ever executed in the cluster were done with GTIDs enabled, there are no purged transactions and the new instance contains the same GTID set as the cluster or a subset of it. To use this method by default, set the 'recoveryMethod' option to 'incremental'.


Please select a recovery method [C]lone/[I]ncremental recovery/[A]bort (default Clone): C
NOTE: Group Replication will communicate with other members using 'ms83:33061'. Use the localAddress option to override.

Validating instance configuration at 192.168.188.83:3306...

This instance reports its own address as ms83:3306

Instance configuration is suitable.
A new instance will be added to the InnoDB cluster. Depending on the amount of
data on the cluster this might take from a few seconds to several hours.

Adding instance to the cluster...

ERROR: Unable to enable clone on the instance 'ms82:3306': Recovery user 'mysql_innodb_cluster_813306' not created by InnoDB Cluster

Monitoring recovery process of the new cluster member. Press ^C to stop monitoring and let it continue in background.
WARNING: Error while waiting for recovery of the added instance: MySQL Error 2013: Lost connection to MySQL server at 'reading initial communication packet', system error: 104
Cluster.addInstance: Cannot set Group Replication recovery user to 'mysql_innodb_cluster_833306'. Error executing CHANGE MASTER statement: ms83:3306: MySQL server has gone away (RuntimeError)
```

```
mysql> select user,host from mysql.user;
+-----------------------------+-----------+
| user                        | host      |
+-----------------------------+-----------+
| kk                          | %         |
| mysql_innodb_cluster_813306 | %         |
| mysql.infoschema            | localhost |
| mysql.session               | localhost |
| mysql.sys                   | localhost |
| root                        | localhost |
+-----------------------------+-----------+
6 rows in set (0.00 sec)
```

不得其解。

准备通过跟踪node3的mysql日志，所以使用removeInstance() ，再重新添加回来。
```
 MySQL  192.168.188.81:3306 ssl  JS > c.removeInstance('kk@192.168.188.83:3306')
The instance will be removed from the InnoDB cluster. Depending on the instance
being the Seed or not, the Metadata session might become invalid. If so, please
start a new session to the Metadata Storage R/W instance.

Instance '192.168.188.83:3306' is attempting to leave the cluster...

The instance '192.168.188.83:3306' was successfully removed from the cluster.

 MySQL  192.168.188.81:3306 ssl  JS > c.addInstance('kk@192.168.188.83:3306')
The safest and most convenient way to provision a new instance is through automatic clone provisioning, which will completely overwrite the state of 'ms83:3306' with a physical snapshot from an existing cluster member. To use this method by default, set the 'recoveryMethod' option to 'clone'.

The incremental state recovery may be safely used if you are sure all updates ever executed in the cluster were done with GTIDs enabled, there are no purged transactions and the new instance contains the same GTID set as the cluster or a subset of it. To use this method by default, set the 'recoveryMethod' option to 'incremental'.

Incremental state recovery was selected because it seems to be safely usable.

NOTE: Group Replication will communicate with other members using 'ms83:33061'. Use the localAddress option to override.

Validating instance configuration at 192.168.188.83:3306...

This instance reports its own address as ms83:3306

Instance configuration is suitable.
A new instance will be added to the InnoDB cluster. Depending on the amount of
data on the cluster this might take from a few seconds to several hours.

Adding instance to the cluster...

Monitoring recovery process of the new cluster member. Press ^C to stop monitoring and let it continue in background.
State recovery already finished for 'ms83:3306'

The instance '192.168.188.83:3306' was successfully added to the cluster.
```

结果成功了？我还没跟踪呢啊！！！！
？？？？？

- 查看下集群状态
有些不可思议。

这东西看来还是薛定谔的successful。
```
 MySQL  192.168.188.81:3306 ssl  JS > c.status()
{
    "clusterName": "kkcc",
    "defaultReplicaSet": {
        "name": "default",
        "primary": "ms81:3306",
        "ssl": "REQUIRED",
        "status": "OK",
        "statusText": "Cluster is ONLINE and can tolerate up to ONE failure.",
        "topology": {
            "ms81:3306": {
                "address": "ms81:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            },
            "ms82:3306": {
                "address": "ms82:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            },
            "ms83:3306": {
                "address": "ms83:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}
 MySQL  192.168.188.81:3306 ssl  JS >
```
node3刚才忘了关闭super read only， 
关闭后再查看集群状态
```
 MySQL  192.168.188.81:3306 ssl  JS > c.status()
{
    "clusterName": "kkcc",
    "defaultReplicaSet": {
        "name": "default",
        "primary": "ms81:3306",
        "ssl": "REQUIRED",
        "status": "OK",
        "statusText": "Cluster is ONLINE and can tolerate up to ONE failure.",
        "topology": {
            "ms81:3306": {
                "address": "ms81:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            },
            "ms82:3306": {
                "address": "ms82:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            },
            "ms83:3306": {
                "address": "ms83:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}
```
这时候我发现node1的mysql datadir中的自动参数文件有了变化：
```
[root@ms81 data]# cat !$
cat mysqld-auto.cnf
{
        "Version" : 1 ,
        "mysql_server" : {
                "super_read_only" : {
                        "Value" : "ON" ,
                        "Metadata" : {
                                "Timestamp" : 1588509644223646 , "User" : "kk" , "Host" : "ms81" } } ,
                "auto_increment_increment" : {
                        "Value" : "1" ,
                        "Metadata" : {
                                "Timestamp" : 1588509644226925 , "User" : "kk" , "Host" : "ms81" } } ,
                "auto_increment_offset" : {
                        "Value" : "2" ,
                        "Metadata" : {
                                "Timestamp" : 1588509644227187 , "User" : "kk" , "Host" : "ms81" } } ,
                "mysql_server_static_options" : {
                        "group_replication_enforce_update_everywhere_checks" : {
                                "Value" : "OFF" ,
                                "Metadata" : {
                                        "Timestamp" : 1588509644225058 , "User" : "kk" , "Host" : "ms81" } } ,
                        "group_replication_exit_state_action" : {
                                "Value" : "READ_ONLY" ,
                                "Metadata" : {
                                        "Timestamp" : 1588509644226310 , "User" : "kk" , "Host" : "ms81" } } ,
                        "group_replication_group_name" : {
                                "Value" : "4e28262a-8d3b-11ea-b463-0242c0a8bc51" ,
                                "Metadata" : {
                                        "Timestamp" : 1588509644224103 , "User" : "kk" , "Host" : "ms81" } } ,
                        "group_replication_group_seeds" : {
                                "Value" : "192.168.188.81:13306,192.168.188.82:13306,192.168.188.83:13306,ms83:33061" ,
                                "Metadata" : {
                                        "Timestamp" : 1588510707329774 , "User" : "kk" , "Host" : "ms81" } } ,
                        "group_replication_local_address" : {
                                "Value" : "ms81:33061" ,
                                "Metadata" : {
                                        "Timestamp" : 1588509644225954 , "User" : "kk" , "Host" : "ms81" } } ,
                        "group_replication_recovery_use_ssl" : {
                                "Value" : "ON" ,
                                "Metadata" : {
                                        "Timestamp" : 1588509644225355 , "User" : "kk" , "Host" : "ms81" } } ,
                        "group_replication_single_primary_mode" : {
                                "Value" : "ON" ,
                                "Metadata" : {
                                        "Timestamp" : 1588509644224519 , "User" : "kk" , "Host" : "ms81" } } ,
                        "group_replication_ssl_mode" : {
                                "Value" : "REQUIRED" ,
                                "Metadata" : {
                                        "Timestamp" : 1588509644225700 , "User" : "kk" , "Host" : "ms81" } } ,
                        "group_replication_start_on_boot" : {
                                "Value" : "ON" ,
                                "Metadata" : { 
					"Timestamp" : 1588509644226625 , "User" : "kk" , "Host" : "ms81" } }
                 }
        }
}
```
是否可以在开始阶段无需在my3306.cnf中配置MGR的参数了呢？
尝试一下。

## 插曲：探索自动参数配置

- 只在my3306.cnf 增加下列配置，不添加任何MGR的参数配置
然后重新初始化实例并通过MySQL Shell配置MGR。
```
binlog_checksum=none
transaction_write_set_extraction=XXHASH64
binlog_transaction_dependency_tracking=WRITESET

#下面的无需添加
####: for MGR
#MGR
## remomber change binlog_checksum to none.
#loose-group_replication_group_name="78cba89c-7a2c-4442-ba43-51aa387a4fd0"  #must be use UUID format
#loose-group_replication_start_on_boot=off
#loose-group_replication_local_address="192.168.188.81:13306"
#loose-group_replication_group_seeds="192.168.188.81:13306,192.168.188.82:13306,192.168.188.83:13306"
#loose-group_replication_bootstrap_group=off
#
##MGR multi master
##loose-group_replication_single_primary_mode=off
##loose-group_replication_enforce_update_everywhere_checks=on
#
```
配置过程同上一样，略。

结果是——搭建亲测可行！但是会不会有隐患？来探索一下！

mysh执行每一步操作后，都去观察一下节点的自动参数文件。

- node1 执行 dba.createCluster('kkcc')

只摘取部分关注内容。
可以看到自动生成了UUID的group_name，并配置了local_address。
```
[root@ms81 ~]# cat /data/mysql/mysql3306/data/mysqld-auto.cnf
{ 
	...
	...
	 "group_replication_exit_state_action" : { 
		"Value" : "READ_ONLY" , 
		"Metadata" : { "Timestamp" : 1588580303031336 , "User" : "kk" , "Host" : "ms81" } } , 
	"group_replication_group_name" : { 
		"Value" : "d21637cb-8ddf-11ea-80c5-0242c0a8bc51" , 
		"Metadata" : { "Timestamp" : 1588580303028133 , "User" : "kk" , "Host" : "ms81" } } , 
	"group_replication_local_address" : { 
		"Value" : "ms81:33061" , 
		"Metadata" : { "Timestamp" : 1588580303030759 , "User" : "kk" , "Host" : "ms81" } } , 
	...
	...
}
```
- node1 cluster.addInstance('kk@192.168.188.82:3306')
```
[root@ms81 ~]# cat /data/mysql/mysql3306/data/mysqld-auto.cnf
{ 
	...
	...
	"group_replication_exit_state_action" : { 
		"Value" : "READ_ONLY" , 
		"Metadata" : { "Timestamp" : 1588580303031336 , "User" : "kk" , "Host" : "ms81" } } , 
	"group_replication_group_name" : { 
		"Value" : "d21637cb-8ddf-11ea-80c5-0242c0a8bc51" , 
		"Metadata" : { "Timestamp" : 1588580303028133 , "User" : "kk" , "Host" : "ms81" } } , 
	"group_replication_group_seeds" : { 
		"Value" : "ms82:33061" , 
		"Metadata" : { "Timestamp" : 1588580470437362 , "User" : "kk" , "Host" : "ms81" } } ,
	"group_replication_local_address" : { 
		"Value" : "ms81:33061" , 
		
	...
	...
}
```
- node1 cluster.addInstance('kk@192.168.188.83:3306')
```
[root@ms81 ~]# cat /data/mysql/mysql3306/data/mysqld-auto.cnf
{ 
	...
	...
	"group_replication_exit_state_action" : { 
		"Value" : "READ_ONLY" , 
		"Metadata" : { "Timestamp" : 1588580303031336 , "User" : "kk" , "Host" : "ms81" } } , 
	"group_replication_group_name" : { 
		"Value" : "d21637cb-8ddf-11ea-80c5-0242c0a8bc51" , 
		"Metadata" : { "Timestamp" : 1588580303028133 , "User" : "kk" , "Host" : "ms81" } } , 
	"group_replication_group_seeds" : { 
		"Value" : "ms82:33061" , 
		"Metadata" : { "Timestamp" : 1588580470437362 , "User" : "kk" , "Host" : "ms81" } } , 
	"group_replication_local_address" : { 
		"Value" : "ms81:33061" , 
		"Metadata" : { "Timestamp" : 1588580303030759 , "User" : "kk" , "Host" : "ms81" } } , 
	...
	...
}
```
可以发现，在自动参数文件中，group_replication_group_seeds 参数随着addInstance()的进行，不停在变化，但添加完三个节点后，参数值并不符合预期。
	预期：添加完全部节点后，group_replication_group_seeds.value列表应该包含全部节点信息。
	实际：列表中只保存了一个值。

- 检查一下node2的自动参数文件
```
[root@ms82 ~]# cat /data/mysql/mysql3306/data/mysqld-auto.cnf
{
	...
	...
	"group_replication_group_name" : { 
		"Value" : "d21637cb-8ddf-11ea-80c5-0242c0a8bc51" , 
		"Metadata" : { "Timestamp" : 1588580461884041 , "User" : "kk" , "Host" : "ms81.net188" } } , 
	"group_replication_group_seeds" : { 
		"Value" : "ms81:33061" , 
		"Metadata" : { "Timestamp" : 1588580461885900 , "User" : "kk" , "Host" : "ms81.net188" } } , 
	"group_replication_local_address" : { 
		"Value" : "ms82:33061" , 
		"Metadata" : { "Timestamp" : 1588580461885604 , "User" : "kk" , "Host" : "ms81.net188" } } , 
	...
	...
}
```
- 检查一下node3的自动参数文件
```
[root@ms83 ~]# cat /data/mysql/mysql3306/data/mysqld-auto.cnf
{
	...
	...
	"group_replication_group_name" : { 
		"Value" : "d21637cb-8ddf-11ea-80c5-0242c0a8bc51" , 
		"Metadata" : { "Timestamp" : 1588580588630977 , "User" : "kk" , "Host" : "ms81.net188" } } , 
	"group_replication_group_seeds" : { 
		"Value" : "ms81:33061,ms82:33061" , 
		"Metadata" : { "Timestamp" : 1588580588632583 , "User" : "kk" , "Host" : "ms81.net188" } } , 
	"group_replication_local_address" : { 
		"Value" : "ms83:33061" , 
		"Metadata" : { "Timestamp" : 1588580588632308 , "User" : "kk" , "Host" : "ms81.net188" } } , 
	...
	...
}
```
各节点的自动参数配置文件中对于group_replication_group_seeds.value的定义都不同，初步感觉这样虽然能够搭建，但是有很大的坑的样子。
_经过后来总结整理，由MySQL Shell创建的MGR，就由MySQL Shell维护就好，不需要手动接入，而且即使在my.cnf中进行了配置，mysqld-auto.cnf的优先级也更高，参数会覆盖手动定义内容。_

- 重启MGR所有节点，然后查看集群状态

这里看到的东西就很不专业。
```
mysql> select * from performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| group_replication_applier | ba635fa9-8dde-11ea-a514-0242c0a8bc51 | ms81        |        3306 | OFFLINE      |             |                |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
1 row in set (0.01 sec)

mysql> select * from performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| group_replication_applier | cffc069a-8dde-11ea-934f-0242c0a8bc52 | ms82        |        3306 | OFFLINE      |             |                |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
1 row in set (0.01 sec)

mysql> select * from performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| group_replication_applier | de51695d-8dde-11ea-b113-0242c0a8bc53 | ms83        |        3306 | OFFLINE      |             |                |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
1 row in set (0.01 sec)
```

- 手动在node3上启动GR，
因为看着node3的配置seeds是最全的
```
mysql> set global group_replication_bootstrap_group=on;
Query OK, 0 rows affected (0.00 sec)

mysql> start group_replication;
Query OK, 0 rows affected (3.10 sec)

mysql>  select * from performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| group_replication_applier | de51695d-8dde-11ea-b113-0242c0a8bc53 | ms83        |        3306 | ONLINE       | PRIMARY     | 8.0.20         |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
1 row in set (0.00 sec)
```
- 在node1、node2上手动启动GR，失败
```
mysql>  start group_replication;
ERROR 3092 (HY000): The server is not configured properly to be an active member of the group. Please see more details on error log.
```
- 查看node1、node2节点error.log

一种啼笑皆非的感觉油然而生。

node1
```
2020-05-04T17:10:13.226575+08:00 0 [ERROR] [MY-011735] [Repl] Plugin group_replication reported: '[GCS] Error on opening a connection to ms82:33061 on local port: 33061.'
2020-05-04T17:10:13.227234+08:00 0 [ERROR] [MY-011735] [Repl] Plugin group_replication reported: '[GCS] Error on opening a connection to ms82:33061 on local port: 33061.'
```

node2
```
2020-05-04T17:11:57.005830+08:00 0 [ERROR] [MY-011735] [Repl] Plugin group_replication reported: '[GCS] Error on opening a connection to ms81:33061 on local port: 33061.'
2020-05-04T17:11:57.006773+08:00 0 [ERROR] [MY-011735] [Repl] Plugin group_replication reported: '[GCS] Error on opening a connection to ms81:33061 on local port: 33061.'
```

node3
```
2020-05-04T17:08:42.787670+08:00 0 [ERROR] [MY-011735] [Repl] Plugin group_replication reported: '[GCS] Error on opening a connection to ms81:33061 on local port: 33061.'
2020-05-04T17:08:42.788441+08:00 0 [ERROR] [MY-011735] [Repl] Plugin group_replication reported: '[GCS] Error on opening a connection to ms82:33061 on local port: 33061.'
2020-05-04T17:08:42.788545+08:00 0 [ERROR] [MY-011735] [Repl] Plugin group_replication reported: '[GCS] Error connecting to all peers. Member join failed. Local port: 33061'
```
**看来直接依靠mysh搞出来的集群，要想通过手动方式启动是不可能的（除非修改cnf文件哈）**

那试试用mysh启动这个集群。

- 再次重启全部节点，尝试使用mysh进行管理
```
 MySQL  JS > shell.connect('kk@192.168.188.81:3306')
 MySQL  192.168.188.81:3306 ssl  JS > var c = dba.getCluster('kkcc')
Dba.getCluster: This function is not available through a session to a standalone instance (metadata exists, instance belongs to that metadata, but GR is not active) (RuntimeError)
```
看来MySQL Shell自己并不能启动GR的样子……
那这个设计就很傻了不是？

- node1上手动启动GR
```
mysql>  set global group_replication_bootstrap_group=on;
Query OK, 0 rows affected (0.00 sec)

mysql> start group_replication;
Query OK, 0 rows affected (3.11 sec)

mysql>  select * from performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| group_replication_applier | ba635fa9-8dde-11ea-a514-0242c0a8bc51 | ms81        |        3306 | ONLINE       | PRIMARY     | 8.0.20         |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
1 row in set (0.00 sec)
```
- mysh上查看集群状态
```
 MySQL  192.168.188.81:3306 ssl  JS > dba.getCluster()
<Cluster:kkcc>
 MySQL  192.168.188.81:3306 ssl  JS > var c = dba.getCluster('kkcc')
 MySQL  192.168.188.81:3306 ssl  JS > c.status()
{
    "clusterName": "kkcc",
    "defaultReplicaSet": {
        "name": "default",
        "primary": "ms81:3306",
        "ssl": "REQUIRED",
        "status": "OK_NO_TOLERANCE",
        "statusText": "Cluster is NOT tolerant to any failures. 1 member is not active",
        "topology": {
            "ms81:3306": {
                "address": "ms81:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            },
            "ms82:3306": {
                "address": "ms82:3306",
                "mode": "R/O",
                "readReplicas": {},
                "role": "HA",
                "status": "(MISSING)"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}
```
这么说来……mysh果然还是个初级中的初级啊。

- node2 手动启动GR
```
mysql>  start group_replication;
Query OK, 0 rows affected (5.93 sec)

mysql>  select * from performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| group_replication_applier | ba635fa9-8dde-11ea-a514-0242c0a8bc51 | ms81        |        3306 | ONLINE       | PRIMARY     | 8.0.20         |
| group_replication_applier | cffc069a-8dde-11ea-934f-0242c0a8bc52 | ms82        |        3306 | ONLINE       | SECONDARY   | 8.0.20         |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
2 rows in set (0.00 sec)

 MySQL  192.168.188.81:3306 ssl  JS > c.status()
{
    "clusterName": "kkcc",
    "defaultReplicaSet": {
        "name": "default",
        "primary": "ms81:3306",
        "ssl": "REQUIRED",
        "status": "OK_NO_TOLERANCE",
        "statusText": "Cluster is NOT tolerant to any failures.",
        "topology": {
            "ms81:3306": {
                "address": "ms81:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            },
            "ms82:3306": {
                "address": "ms82:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}
```
- node3 手动启动GR
```
mysql> start group_replication;
Query OK, 0 rows affected (4.67 sec)

mysql>  select * from performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| group_replication_applier | ba635fa9-8dde-11ea-a514-0242c0a8bc51 | ms81        |        3306 | ONLINE       | PRIMARY     | 8.0.20         |
| group_replication_applier | cffc069a-8dde-11ea-934f-0242c0a8bc52 | ms82        |        3306 | ONLINE       | SECONDARY   | 8.0.20         |
| group_replication_applier | de51695d-8dde-11ea-b113-0242c0a8bc53 | ms83        |        3306 | ONLINE       | SECONDARY   | 8.0.20         |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
3 rows in set (0.00 sec)

 MySQL  192.168.188.81:3306 ssl  JS > c.status()
{
    "clusterName": "kkcc",
    "defaultReplicaSet": {
        "name": "default",
        "primary": "ms81:3306",
        "ssl": "REQUIRED",
        "status": "OK",
        "statusText": "Cluster is ONLINE and can tolerate up to ONE failure.",
        "topology": {
            "ms81:3306": {
                "address": "ms81:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            },
            "ms82:3306": {
                "address": "ms82:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}
```
mysh这一段反而找不到node3了…… 我的天呐，您是要笑死我嘛？

- 重新扫描node3
```
 MySQL  192.168.188.81:3306 ssl  JS > c.rescan()
Rescanning the cluster...

Result of the rescanning operation for the 'kkcc' cluster:
{
    "name": "kkcc",
    "newTopologyMode": null,
    "newlyDiscoveredInstances": [
        {
            "host": "ms83:3306",
            "member_id": "de51695d-8dde-11ea-b113-0242c0a8bc53",
            "name": null,
            "version": "8.0.20"
        }
    ],
    "unavailableInstances": []
}

A new instance 'ms83:3306' was discovered in the cluster.
Would you like to add it to the cluster metadata? [Y/n]: y
Adding instance to the cluster metadata...
The instance 'ms83:3306' was successfully added to the cluster metadata.

 MySQL  192.168.188.81:3306 ssl  JS > c.status()
{
    "clusterName": "kkcc",
    "defaultReplicaSet": {
        "name": "default",
        "primary": "ms81:3306",
        "ssl": "REQUIRED",
        "status": "OK",
        "statusText": "Cluster is ONLINE and can tolerate up to ONE failure.",
        "topology": {
            "ms81:3306": {
                "address": "ms81:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            },
            "ms82:3306": {
                "address": "ms82:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            },
            "ms83:3306": {
                "address": "ms83:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}
```
**问题回顾：可能是添加node3的问题，也可能是本身mysh就有问题。**
**插曲的结论：还是老老实实自己手动写配置文件吧，祝愿MySQL Shell早日长大成人。**

# 使用mysh切换MGR模式
```
 MySQL  192.168.188.81:3306 ssl  JS > c.switchToMultiPrimaryMode() #切换为多主模式
Switching cluster 'kkcc' to Multi-Primary mode...

Instance 'ms81:3306' remains PRIMARY.
Instance 'ms82:3306' was switched from SECONDARY to PRIMARY.
Instance 'ms83:3306' was switched from SECONDARY to PRIMARY.

The cluster successfully switched to Multi-Primary mode.
 MySQL  192.168.188.81:3306 ssl  JS > c.status()
{
    "clusterName": "kkcc",
    "defaultReplicaSet": {
        "name": "default",
        "ssl": "REQUIRED",
        "status": "OK",
        "statusText": "Cluster is ONLINE and can tolerate up to ONE failure.",
        "topology": {
            "ms81:3306": {
                "address": "ms81:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            },
            "ms82:3306": {
                "address": "ms82:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            },
            "ms83:3306": {
                "address": "ms83:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            }
        },
        "topologyMode": "Multi-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}
 MySQL  192.168.188.81:3306 ssl  JS > c.switchToSinglePrimaryMode()		#切换为单主模式
Switching cluster 'kkcc' to Single-Primary mode...

Instance 'ms81:3306' remains PRIMARY.
Instance 'ms82:3306' was switched from PRIMARY to SECONDARY.
Instance 'ms83:3306' was switched from PRIMARY to SECONDARY.

WARNING: Existing connections that expected a R/W connection must be disconnected, i.e. instances that became SECONDARY.

The cluster successfully switched to Single-Primary mode.
 MySQL  192.168.188.81:3306 ssl  JS > c.status()			
{
    "clusterName": "kkcc",
    "defaultReplicaSet": {
        "name": "default",
        "primary": "ms81:3306",
        "ssl": "REQUIRED",
        "status": "OK",
        "statusText": "Cluster is ONLINE and can tolerate up to ONE failure.",
        "topology": {
            "ms81:3306": {
                "address": "ms81:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            },
            "ms82:3306": {
                "address": "ms82:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            },
            "ms83:3306": {
                "address": "ms83:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.20"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}
```


# MGR 原理探索

## 事务探索
node1
```
mysql> show master status;
+------------------+----------+--------------+------------------+-------------------------------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                         |
+------------------+----------+--------------+------------------+-------------------------------------------+
| mysql-bin.000001 |    47924 |              |                  | 4e28262a-8d3b-11ea-b463-0242c0a8bc51:1-78 |
+------------------+----------+--------------+------------------+-------------------------------------------+
1 row in set (0.00 sec)

mysql> create database kk;
Query OK, 1 row affected (0.03 sec)

mysql> show master status;
+------------------+----------+--------------+------------------+-------------------------------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                         |
+------------------+----------+--------------+------------------+-------------------------------------------+
| mysql-bin.000001 |    48107 |              |                  | 4e28262a-8d3b-11ea-b463-0242c0a8bc51:1-79 |
+------------------+----------+--------------+------------------+-------------------------------------------+
1 row in set (0.00 sec)
```

node2
```
mysql> show master status;
+------------------+----------+--------------+------------------+-------------------------------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                         |
+------------------+----------+--------------+------------------+-------------------------------------------+
| mysql-bin.000002 |    22955 |              |                  | 4e28262a-8d3b-11ea-b463-0242c0a8bc51:1-79 |
+------------------+----------+--------------+------------------+-------------------------------------------+
1 row in set (0.00 sec)

mysql> show slave status\G
Empty set (0.00 sec)

mysql> use kk
Database changed
mysql> create table k1(id int);
Query OK, 0 rows affected (0.06 sec)

mysql> create table k3(id int);
Query OK, 0 rows affected (0.06 sec)

mysql> use kk
Database changed
mysql> show slave status\G
Empty set (0.00 sec)

mysql> show master status;
+------------------+----------+--------------+------------------+-----------------------------------------------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set
    |
+------------------+----------+--------------+------------------+-----------------------------------------------------------+
| mysql-bin.000002 |    23519 |              |                  | 4e28262a-8d3b-11ea-b463-0242c0a8bc51:1-80:1000074-1000075 |
+------------------+----------+--------------+------------------+-----------------------------------------------------------+
1 row in set (0.00 sec)
```

node3
```
mysql> create table k4(id int);
Query OK, 0 rows affected (0.06 sec)

mysql> show master status;
+------------------+----------+--------------+------------------+-------------------------------------------------------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                                                 |
+------------------+----------+--------------+------------------+-------------------------------------------------------------------+
| mysql-bin.000002 |    10442 |              |                  | 4e28262a-8d3b-11ea-b463-0242c0a8bc51:1-80:1000074-1000075:2000074 |
+------------------+----------+--------------+------------------+-------------------------------------------------------------------+
1 row in set (0.00 sec)
```

**结论：每个节点自己有一个gtid区间， 当用完了还会再申请新的区间**

MGR原理的内容后续再追加，太长了。