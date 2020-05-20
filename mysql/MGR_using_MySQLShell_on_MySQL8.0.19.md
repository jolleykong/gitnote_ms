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
 

[TOC]

# 环境信息
|IP|port|role|info|
|-|-|-|-|
|192.168.188.81|3306|node1|null|
|192.168.188.82|3306|node2|null|
|192.168.188.83|3306|node3|null|

- CentOS Linux release 7.6.1810 (Core)
- MySQL Ver 8.0.19 for linux-glibc2.12 on x86_64 (MySQL Community Server - GPL)
- MySQL Router  Ver 8.0.20 for Linux on x86_64 (MySQL Community - GPL)
- MySQL Shell   Ver 8.0.20 for Linux on x86_64 - for MySQL 8.0.20 (MySQL Community Server (GPL))


# 软件位置
在三个节点上部署好MySQL、MySQL Router、MySQL Shell。
```  shell
[root@ms81 ~]# ll /usr/local
total 40
drwxr-xr-x 2 root root 4096 Apr 11  2018 bin
drwxr-xr-x 2 root root 4096 Apr 11  2018 etc
drwxr-xr-x 2 root root 4096 Apr 11  2018 games
drwxr-xr-x 2 root root 4096 Apr 11  2018 include
drwxr-xr-x 2 root root 4096 Apr 11  2018 lib
drwxr-xr-x 2 root root 4096 Apr 11  2018 lib64
drwxr-xr-x 2 root root 4096 Apr 11  2018 libexec
lrwxrwxrwx 1 root root   47 May 13 14:22 myrouter -> /opt/mysql-router-8.0.20-linux-glibc2.12-x86_64
lrwxrwxrwx 1 root root   49 May 13 14:22 myshell -> /opt/mysql-shell-8.0.20-linux-glibc2.12-x86-64bit
lrwxrwxrwx 1 root root   41 May 13 14:23 mysql -> /opt/mysql-8.0.19-linux-glibc2.12-x86_64/
drwxr-xr-x 2 root root 4096 Apr 11  2018 sbin
drwxr-xr-x 5 root root 4096 Dec  4  2018 share
drwxr-xr-x 2 root root 4096 Apr 11  2018 src
```

# 配置my.cnf文件，并初始化各节点mysql实例
- 配置文件配置内容
```
binlog_checksum=none
```
在这里不配置writeset，也不配置loose-group_replication
完全依靠MySQL Shell进行配置

- 初始化操作：略

- 启动各节点实例：
在这里用mysqld_safe来启动实例，这一步非必要，也可以用mysqld拉起服务
用mysqld_safe的好处是：在后面mysqlsh创建集群、通过clone plugin添加节点时，对应节点可以自行重启，而无需手动介入。
``` shell
[root@ms81 ~]# mysqld_safe --defaults-file=/data/mysql/mysql3306/my3306.cnf  &
[root@ms82 ~]# mysqld_safe --defaults-file=/data/mysql/mysql3306/my3306.cnf  &
[root@ms83 ~]# mysqld_safe --defaults-file=/data/mysql/mysql3306/my3306.cnf  &
```

# 为各节点MySQL实例配置MGR用户
- 各节点配置用户
``` shell
# mysql -S /data/mysql/mysql3306/tmp/mysql.sock

mysql> set global super_read_only=0;
Query OK, 0 rows affected (0.00 sec)

mysql> create user mgr@'192.168.188.%' identified by 'mgr';
Query OK, 0 rows affected (0.01 sec)

mysql> grant all privileges on *.* to  mgr@'192.168.188.%' with grant option;
Query OK, 0 rows affected (0.02 sec)

mysql> reset master;
Query OK, 0 rows affected (0.04 sec)

mysql> show master status;
+------------------+----------+--------------+------------------+-------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+------------------+----------+--------------+------------------+-------------------+
| mysql-bin.000001 |      151 |              |                  |                   |
+------------------+----------+--------------+------------------+-------------------+
1 row in set (0.00 sec)
```

# 任一节点进行MySQL Shell配置
在这里使用节点1——ms81
- 创建MGR集群kk
``` shell
[root@ms81 ~]# mysqlsh
MySQL Shell 8.0.20

Copyright (c) 2016, 2020, Oracle and/or its affiliates. All rights reserved.
Oracle is a registered trademark of Oracle Corporation and/or its affiliates.
Other names may be trademarks of their respective owners.

Type '\help' or '\?' for help; '\quit' to exit.
 MySQL  JS > shell.connect('mgr@192.168.188.81:3306')
Creating a session to 'mgr@192.168.188.81:3306'
Please provide the password for 'mgr@192.168.188.81:3306': ***
Save password for 'mgr@192.168.188.81:3306'? [Y]es/[N]o/Ne[v]er (default No): Y
Fetching schema names for autocompletion... Press ^C to stop.
Your MySQL connection id is 10
Server version: 8.0.19 MySQL Community Server - GPL
No default schema selected; type \use <schema> to set one.
<ClassicSession:mgr@192.168.188.81:3306>
 MySQL  192.168.188.81:3306 ssl  JS > var cl = dba.createCluster('kk')
A new InnoDB cluster will be created on instance '192.168.188.81:3306'.

Validating instance configuration at 192.168.188.81:3306...

This instance reports its own address as ms81:3306

Instance configuration is suitable.
NOTE: Group Replication will communicate with other members using 'ms81:33061'. Use the localAddress option to override.

Creating InnoDB cluster 'kk' on 'ms81:3306'...

Adding Seed Instance...
Cluster successfully created. Use Cluster.addInstance() to add MySQL instances.
At least 3 instances are needed for the cluster to be able to withstand up to
one server failure.

 MySQL  192.168.188.81:3306 ssl  JS > cl.status()
{
    "clusterName": "kk",
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
                "version": "8.0.19"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}
```
- 将节点2——ms82加入集群
``` shell
 MySQL  192.168.188.81:3306 ssl  JS > cl.addInstance('mgr@192.168.188.82:3306')
Please provide the password for 'mgr@192.168.188.82:3306': ***
Save password for 'mgr@192.168.188.82:3306'? [Y]es/[N]o/Ne[v]er (default No): Y

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
** Stage RECOVERY: \
NOTE: ms82:3306 is shutting down...

* Waiting for server restart... ready
* ms82:3306 has restarted, waiting for clone to finish...
* Clone process has finished: 151.89 MB transferred in about 1 second (~151.89 MB/s)

State recovery already finished for 'ms82:3306'

The instance '192.168.188.82:3306' was successfully added to the cluster.
```
- 同样加入节点3
``` shell
 MySQL  192.168.188.81:3306 ssl  JS > cl.addInstance('mgr@192.168.188.83:3306')
信息略

 MySQL  192.168.188.81:3306 ssl  JS > cl.status()
{
    "clusterName": "kk",
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
                "version": "8.0.19"
            },
            "ms82:3306": {
                "address": "ms82:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.19"
            },
            "ms83:3306": {
                "address": "ms83:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.19"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}


```
集群创建完成。

# 玩转MGR
- 通过MySQL Shell连接到集群
``` shell
[root@ms82 ~]# mysqlsh
MySQL Shell 8.0.20

Copyright (c) 2016, 2020, Oracle and/or its affiliates. All rights reserved.
Oracle is a registered trademark of Oracle Corporation and/or its affiliates.
Other names may be trademarks of their respective owners.

Type '\help' or '\?' for help; '\quit' to exit.
 MySQL  JS > \c mgr@192.168.188.82:306
Creating a session to 'mgr@192.168.188.82:306'
Please provide the password for 'mgr@192.168.188.82:306': ***
MySQL Error 2003 (HY000): Can't connect to MySQL server on '192.168.188.82' (111)
 MySQL  JS > \c mgr@192.168.188.82:3306
Creating a session to 'mgr@192.168.188.82:3306'
Please provide the password for 'mgr@192.168.188.82:3306': ***
Save password for 'mgr@192.168.188.82:3306'? [Y]es/[N]o/Ne[v]er (default No): Y
Fetching schema names for autocompletion... Press ^C to stop.
Your MySQL connection id is 63
Server version: 8.0.19 MySQL Community Server - GPL
No default schema selected; type \use <schema> to set one.
 MySQL  192.168.188.82:3306 ssl  JS > var kk=dba.getCluster('kk')
 MySQL  192.168.188.82:3306 ssl  JS > kk.status()
{
    "clusterName": "kk",
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
                "version": "8.0.19"
            },
            "ms82:3306": {
                "address": "ms82:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.19"
            },
            "ms83:3306": {
                "address": "ms83:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.19"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}
```
- singlePrimary - MultiPrmary
``` shell
 MySQL  192.168.188.82:3306 ssl  JS > kk.status()
{
    "clusterName": "kk",
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
                "version": "8.0.19"
            },
            "ms82:3306": {
                "address": "ms82:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.19"
            },
            "ms83:3306": {
                "address": "ms83:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.19"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}
 MySQL  192.168.188.82:3306 ssl  JS > kk.switchToMultiPrimaryMode()
Switching cluster 'kk' to Multi-Primary mode...

Instance 'ms81:3306' remains PRIMARY.
Instance 'ms82:3306' was switched from SECONDARY to PRIMARY.
Instance 'ms83:3306' was switched from SECONDARY to PRIMARY.

The cluster successfully switched to Multi-Primary mode.
 MySQL  192.168.188.82:3306 ssl  JS > kk.status()
{
    "clusterName": "kk",
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
                "version": "8.0.19"
            },
            "ms82:3306": {
                "address": "ms82:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.19"
            },
            "ms83:3306": {
                "address": "ms83:3306",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.19"
            }
        },
        "topologyMode": "Multi-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}
 MySQL  192.168.188.82:3306 ssl  JS > kk.switchToSinglePrimaryMode()
Switching cluster 'kk' to Single-Primary mode...

Instance 'ms81:3306' remains PRIMARY.
Instance 'ms82:3306' was switched from PRIMARY to SECONDARY.
Instance 'ms83:3306' was switched from PRIMARY to SECONDARY.

WARNING: Existing connections that expected a R/W connection must be disconnected, i.e. instances that became SECONDARY.

The cluster successfully switched to Single-Primary mode.
 MySQL  192.168.188.82:3306 ssl  JS > kk.status()
{
    "clusterName": "kk",
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
                "version": "8.0.19"
            },
            "ms82:3306": {
                "address": "ms82:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.19"
            },
            "ms83:3306": {
                "address": "ms83:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.19"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}
```

- 冷启动集群
```
[root@ms81 ~]# ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 14:28 ?        00:00:00 /usr/sbin/sshd -D
root         6     1  0 14:28 ?        00:00:00 sshd: root@pts/0
root         8     6  0 14:28 pts/0    00:00:00 -bash
root      1276     1  0 15:05 ?        00:00:00 sshd: root@pts/1
root      1278  1276  0 15:05 pts/1    00:00:00 -bash
root      1313     8  0 15:06 pts/0    00:00:00 ps -ef

[root@ms82 ~]# ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 14:28 ?        00:00:00 /usr/sbin/sshd -D
root         6     1  0 14:28 ?        00:00:00 sshd: root@pts/0
root         8     6  0 14:28 pts/0    00:00:00 -bash
root      1362     8  0 15:06 pts/0    00:00:00 ps -ef

[root@ms83 ~]# ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 14:28 ?        00:00:00 /usr/sbin/sshd -D
root         6     1  0 14:28 ?        00:00:00 sshd: root@pts/0
root         8     6  0 14:28 pts/0    00:00:00 -bash
root      1337     8  0 15:06 pts/0    00:00:00 ps -ef

[root@ms81 ~]# mysqld --defaults-file=/data/mysql/mysql3306/my3306.cnf  &
[root@ms82 ~]# mysqld --defaults-file=/data/mysql/mysql3306/my3306.cnf  &
[root@ms83 ~]# mysqld --defaults-file=/data/mysql/mysql3306/my3306.cnf  &

[root@ms81 ~]# mysql -S /data/mysql/mysql3306/tmp/mysql.sock
mysql> set global group_replication_bootstrap_group=ON;
Query OK, 0 rows affected (0.00 sec)

mysql> start group_replication;
Query OK, 0 rows affected (3.12 sec)

mysql> set global group_replication_bootstrap_group=OFF;
Query OK, 0 rows affected (0.00 sec)

mysql> select * from performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| group_replication_applier | 3361b4d4-94e2-11ea-8228-0242c0a8bc51 | ms81        |        3306 | ONLINE       | PRIMARY     | 8.0.19         |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
1 row in set (0.00 sec)


[root@ms82 ~]# mysql -S /data/mysql/mysql3306/tmp/mysql.sock
mysql>  start group_replication;
Query OK, 0 rows affected (5.94 sec)

[root@ms83 ~]# mysql -S /data/mysql/mysql3306/tmp/mysql.sock
mysql>  start group_replication;
Query OK, 0 rows affected (4.06 sec)

mysql> select * from performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| group_replication_applier | 3361b4d4-94e2-11ea-8228-0242c0a8bc51 | ms81        |        3306 | ONLINE       | PRIMARY     | 8.0.19         |
| group_replication_applier | 5e7d516c-94e2-11ea-b92b-0242c0a8bc52 | ms82        |        3306 | ONLINE       | SECONDARY   | 8.0.19         |
| group_replication_applier | 61445cc9-94e2-11ea-ab28-0242c0a8bc53 | ms83        |        3306 | ONLINE       | SECONDARY   | 8.0.19         |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
3 rows in set (0.00 sec)


[root@ms82 ~]# mysqlsh
MySQL Shell 8.0.20

Copyright (c) 2016, 2020, Oracle and/or its affiliates. All rights reserved.
Oracle is a registered trademark of Oracle Corporation and/or its affiliates.
Other names may be trademarks of their respective owners.

Type '\help' or '\?' for help; '\quit' to exit.
 MySQL  JS > \c mgr@192.168.188.81:3306
Creating a session to 'mgr@192.168.188.81:3306'
Please provide the password for 'mgr@192.168.188.81:3306': ***
Save password for 'mgr@192.168.188.81:3306'? [Y]es/[N]o/Ne[v]er (default No): Y
Fetching schema names for autocompletion... Press ^C to stop.
Your MySQL connection id is 42
Server version: 8.0.19 MySQL Community Server - GPL
No default schema selected; type \use <schema> to set one.
 MySQL  192.168.188.81:3306 ssl  JS > var cl=dba.getCluster('kk')
 MySQL  192.168.188.81:3306 ssl  JS > cl.status()
{
    "clusterName": "kk",
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
                "version": "8.0.19"
            },
            "ms82:3306": {
                "address": "ms82:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.19"
            },
            "ms83:3306": {
                "address": "ms83:3306",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": null,
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.19"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "ms81:3306"
}
```