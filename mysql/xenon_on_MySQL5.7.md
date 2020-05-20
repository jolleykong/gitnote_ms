> 20200501   

[TOC]


# 环境信息

|IP|port|role|hostname|
|-|-|-|-|
|192.168.188.51|3306|node1|ms51|
|192.168.188.52|3306|node2|ms52|
|192.168.188.53|3306|node3|ms53|
|192.168.188.54|3306|node4|ms54|
|192.168.188.50|3306|s-ip|null|

- CentOS Linux release 7.6.1810
- mysql-5.7.30-linux-glibc2.12-x86_64
- xtrabackup version 2.4.20
	
由于Xenon本身架构的限制，暂不支持单节点多实例的方式建立高可用。可以使用docker，本来Xenon就是基于docker架构设计的。
	
# 操作系统配置
1.创建mysql用户，如果之前已经配置，可能需要调整mysql账号
使mysql用户可以login
```
[root@ms51 data]# sed -i  's#/sbin/nologin#/bin/bash#' /etc/passwd  &&  grep mysql /etc/passwd
	mysql:x:2000:2000::/usr/local/mysql:/bin/bash
[root@ms51 data]#  echo mysql | passwd --stdin mysql

```	



补充建立一下home目录
```
[root@ms51 data]# usermod -d /home/mysql mysql && mkdir /home/mysql  && cp -f /root/.bash* /home/mysql/ && chown -R mysql:mysql /home/mysql && chmod -R 700 /home/mysql
```	
配置并验证mysql的ssh互信
```
[mysql@ms51 ~]$ ssh-keygen
[mysql@ms51 ~]$ cat .ssh/id_rsa.pub  >> .ssh/authorized_keys

[mysql@ms52 ~]$ scp .ssh/id_rsa.pub  192.168.188.201:/tmp/2
[mysql@ms53 ~]$ scp .ssh/id_rsa.pub  192.168.188.201:/tmp/3

[mysql@ms51 ~]$ cat /tmp/2  >> .ssh/authorized_keys
[mysql@ms51 ~]$ cat /tmp/3  >> .ssh/authorized_keys
[mysql@ms51 ~]$ chmod 600 .ssh/authorized_keys

[mysql@ms51 ~]$ scp .ssh/authorized_keys  192.168.188.202:~/.ssh/
[mysql@ms51 ~]$ scp .ssh/authorized_keys  192.168.188.203:~/.ssh/

	#注意selinux， 如果开启的话，ssh互信是不生效的。
```
配置sudoers
```
#将mysql加入sudoer中
[root@ms51 ~]# visudo    # 或者直接vi /etc/sudoers
mysql   ALL=(ALL)       NOPASSWD:/usr/sbin/ip
```		
验证一下
```
[root@ms51 data]# su - mysql -c "sudo ip a"
	#有结果就ok。
```
# 软件安装
- xtrabackup
	略
- mysql安装
	略
	
# MySQL层面的配置
这一环节主要是确认复制、半同步复制可用，配置结束后可以关闭实例。实际启用Xenon后，主从关系由Xenon选举得出，与这里的角色配置关系不大。
- 记得修改server-id。
- 配置3个实例。
	
## 启动三个数据库实例并完成基础配置
```
shell# mysqld --defaults-file=/data/mysql/mysql3306/my3306.cnf &

mysql> set global super_read_only=0;
mysql> alter user user() identified by 'mysql';
```	
		
	
## 配置GTID+半同步、创建复制架构

node1、node2、node3 检查下列参数，以支持半同步开启
- gtid_mode
- enforce_gtid_consistency
- binlog_format=row
```
mysql> show global variables like '%GTID%';
+----------------------------------+----------------------------------------+
| Variable_name                    | Value                                  |
+----------------------------------+----------------------------------------+
| binlog_gtid_simple_recovery      | ON                                     |
| enforce_gtid_consistency         | ON                                     |
| gtid_executed                    | 5ea86dca-8b58-11ea-86d8-0242c0a8bc33:1 |
| gtid_executed_compression_period | 1000                                   |
| gtid_mode                        | ON                                     |
| gtid_owned                       |                                        |
| gtid_purged                      |                                        |
| session_track_gtids              | OFF                                    |
+----------------------------------+----------------------------------------+
8 rows in set (0.00 sec)

mysql> show global variables like '%binlog_format%';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| binlog_format | ROW   |
+---------------+-------+
1 row in set (0.01 sec)
```		
		
## 创建复制用户
node1、node2、node3上都进行创建
```
mysql> create user 'rep'@'192.168.188.%' identified by 'rep';
Query OK, 0 rows affected (0.17 sec)

mysql> grant replication slave on *.* to 'rep'@'192.168.188.%';
Query OK, 0 rows affected (0.14 sec)
```
	
## 配置复制架构
node1、node2、node3重置一下master status：
```
mysql> reset master;
```
node2、node3配置复制：
```
mysql> change master to master_host='192.168.188.51',master_port=3306,master_user='rep',master_password='rep',master_auto_position=1;
```

## 配置半同步
node1、node2、node3所有节点加载半同步库
```
mysql> install plugin rpl_semi_sync_slave soname 'semisync_slave.so';
Query OK, 0 rows affected (0.01 sec)

mysql> install plugin rpl_semi_sync_master soname 'semisync_master.so';
Query OK, 0 rows affected (0.00 sec)

mysql> show plugins;
	+----------------------------+----------+--------------------+--------------------+---------+
	| Name                       | Status   | Type               | Library            | License |
	+----------------------------+----------+--------------------+--------------------+---------+
	| rpl_semi_sync_slave        | ACTIVE   | REPLICATION        | semisync_slave.so  | GPL     |
	| rpl_semi_sync_master       | ACTIVE   | REPLICATION        | semisync_master.so | GPL     |
	+----------------------------+----------+--------------------+--------------------+---------+
```

node1（临时master）启用半同步
```
mysql> set global rpl_semi_sync_master_enabled=1;
Query OK, 0 rows affected (0.00 sec)

mysql> set global rpl_semi_sync_master_timeout=10000000;
Query OK, 0 rows affected (0.00 sec)

mysql> show global status like '%semi%';
+--------------------------------------------+-------+
| Variable_name                              | Value |
+--------------------------------------------+-------+
| Rpl_semi_sync_master_status                | ON    |
+--------------------------------------------+-------+
15 rows in set (0.00 sec)
```

node2、node3（临时从库）启用半同步
```
mysql> set global rpl_semi_sync_slave_enabled=1;
Query OK, 0 rows affected (0.00 sec)

mysql> start slave;
Query OK, 0 rows affected (0.01 sec)

mysql> show global status like '%SEMI%';
+--------------------------------------------+-------+
| Variable_name                              | Value |
+--------------------------------------------+-------+
| Rpl_semi_sync_slave_status                 | ON    |
+--------------------------------------------+-------+
15 rows in set (0.00 sec)
```
看下node1，已经注册了2个半同步slave
```
mysql> show global status like '%semi%';
+--------------------------------------------+-------+
| Variable_name                              | Value |
+--------------------------------------------+-------+
| Rpl_semi_sync_master_clients               | 2     |
| Rpl_semi_sync_master_status                | ON    |
+--------------------------------------------+-------+
15 rows in set (0.00 sec)
```
半同步复制架构配置完成。

## 创建数据库用户root@127.0.0.1
Xenon会用到这个用户，与后面配置文件的设定有关。
由于已经配置主从复制，直接在master上执行就可以了，让它自己复制到所有节点。
```
root@localhost [(none)]>create user root@127.0.0.1 identified by 'mysql';
Query OK, 0 rows affected (0.04 sec)

root@localhost [(none)]>GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1'  WITH GRANT OPTION;
Query OK, 0 rows affected (0.04 sec)

root@localhost [(none)]>grant super on *.* TO 'root'@'127.0.0.1';
Query OK, 0 rows affected (0.04 sec)

```
MySQL层面配置完成，接下来可以关闭全部mysql，去搞Xenon了
```
mysql> shutdown;
```

		

# 配置xenon
## 安装依赖
Xenon需要安装sshpass、golang。
需要在全部节点上安装依赖。
```
[root@ms51 data]# curl -s https://mirror.go-repo.io/centos/go-repo.repo | tee /etc/yum.repos.d/go-repo.repo
[root@ms51 data]# yum install go sshpass -y
```
确保go在PATH中
```
[root@ms51 data]# go version
go version go1.14.2 linux/amd64
```
## 获取、部署Xenon
可以直接通过git拉取项目，也可以通过其它途径（直接去github上下载zip）获取到项目后直接上传到每一个服务器。
- 通过git方式，需安装git
```
[root@ms51 data]# yum install git -y

#git clone
[root@ms51 data]# pwd
/data/
[root@ms51 data]# git clone https://github.com/radondb/xenon
```
clone后可以直接scp给其它节点。

- 通过zip方式：
```
#从github下载zip后，依次部署到所有节点上
[root@ms51 data]# unzip /ofiles/xenon-master.zip -d /data/
```
## 编译（所有节点）
```
[root@ms51 data]# pwd
/data

[root@ms51 data]# ls
mysql  xenon-master

[root@ms51 data]# cd xenon-master/

[root@ms51 xenon-master]# ls
conf  docs  LICENSE  makefile  README.md  src

[root@ms51 xenon-master]# make
..

[root@ms51 xenon-master]# ls
bin  conf  docs  LICENSE  makefile  README.md  src

[root@ms51 xenon-master]# ls bin/
xenon  xenoncli
```
## 完成编译后， 规划文件目录结构（也可以不做）
可以复制或移动bin/ conf/ 目录， 但是不要删除或改变git项目目录及src/目录

## 建立config.path文件，以指定默认配置文件位置（所有节点）
后续xenoncli 命令依赖config.path文件，该文件里指定了配置文件的路径
```
[root@ms51 xenon-master]# cp conf/xenon-sample.conf.json xenon.json
[root@ms52 xenon-master]# cp conf/xenon-sample.conf.json xenon.json
[root@ms53 xenon-master]# cp conf/xenon-sample.conf.json xenon.json
[root@ms53 xenon-master]# echo "/etc/xenon/xenon.json" > /data/xenon-master/bin/config.path && mkdir /etc/xenon && ln -sf /data/xenon-master/xenon.json  /etc/xenon/xenon.json
[root@ms52 xenon-master]# echo "/etc/xenon/xenon.json" > /data/xenon-master/bin/config.path && mkdir /etc/xenon && ln -sf /data/xenon-master/xenon.json  /etc/xenon/xenon.json
[root@ms53 xenon-master]# echo "/etc/xenon/xenon.json" > /data/xenon-master/bin/config.path && mkdir /etc/xenon && ln -sf /data/xenon-master/xenon.json  /etc/xenon/xenon.json
```
## 将整个xenon目录所有者给mysql（所有节点）
```
[root@ms51 xenon-master]#  chown -R mysql:mysql /data/xenon-master/
[root@ms52 xenon-master]#  chown -R mysql:mysql /data/xenon-master/
[root@ms53 xenon-master]#  chown -R mysql:mysql /data/xenon-master/
```
## 配置xenon.json（所有节点）
说明：
- server段：本机IP
- raft段：s-ip，要绑定s-ip的网卡名称
- mysql段：指定本机mysql相关配置，host段和admin拼合起来就是前面创建root@127.0.0.1的用途。两个sysvars可以根据实际需求配置角色所需的配置动作。考虑到半同步enabled放在my.cnf文件中没有在动作中灵活，便将半同步设定也放在动作里了。
- replication段：
- backup段：本机IP，backupdir需要注意，这个指定为mysql实例的datadir，以供xtrabackup使用。另外在执行rebuildme的时候，xenon会清空该目录以重建实例。
```
[root@ms51 xenon]# cat xenon.json
{
	"server":
	{
		"endpoint":"192.168.188.51:8801"
	},

	"raft":
	{
		"meta-datadir":"raft.meta",
		"heartbeat-timeout":1000,
		"election-timeout":3000,
		"leader-start-command":"sudo /sbin/ip a a 192.168.188.50/16 dev eth0 && arping -c 3 -A  192.168.188.50  -I eth0",
		"leader-stop-command":"sudo /sbin/ip a d 192.168.188.50/16 dev eth0 "
	},

	"mysql":
	{
		"admin":"root",
		"passwd":"mysql",
		"host":"127.0.0.1",
		"port":3306,
		"basedir":"/usr/local/mysql",
		"defaults-file":"/data/mysql/mysql3306/my3306.cnf",
		"ping-timeout":1000,
		"master-sysvars":"super_read_only=0;read_only=0;sync_binlog=default;innodb_flush_log_at_trx_commit=defaulti;rpl_semi_sync_slave_enabled=0;rpl_semi_sync_master_enabled=1",
		"slave-sysvars": "super_read_only=1;read_only=1;sync_binlog=1000;innodb_flush_log_at_trx_commit=2;rpl_semi_sync_slave_enabled=1;rpl_semi_sync_master_enabled=0"

	},

	"replication":
	{
		"user":"rep",
		"passwd":"rep"
	},

	"backup":
	{
		"ssh-host":"192.168.188.51",
		"ssh-user":"mysql",
		"ssh-passwd":"mysql",
		"basedir":"/usr/local/mysql",
		"backupdir":"/data/mysql/mysql3306/data",
		"xtrabackup-bindir":"/usr/bin"
	},

	"rpc":
	{
		"request-timeout":500
	},

	"log":
	{
		"level":"INFO"
	}
}

#slave替换hostIP即可。
```		
		
	
# 启动集群
mysqld可以关掉。
	
## 稳妥起见，在全部节点测试一下——切换到mysql用户，测试一下json文件的可读性及动作是否能够执行
```
[mysql@ms51 ~]$ cat /etc/xenon/xenon.json
	..
	..
[mysql@ms51 ~]$ sudo /sbin/ip a a 192.168.188.50/16 dev eth0 && arping -c 3 -A 192.168.188.50 -I eth0
	ARPING 192.168.188.50 from 192.168.188.50 eth0
	Sent 3 probes (3 broadcast(s))
Received 0 response(s)

[mysql@ms51 ~]$ ip a
	..
	36: eth0@if37: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
	link/ether 02:42:c0:a8:bc:33 brd ff:ff:ff:ff:ff:ff link-netnsid 0
	inet 192.168.188.51/24 brd 192.168.188.255 scope global eth0
	valid_lft forever preferred_lft forever
	inet 192.168.188.50/16 scope global eth0
	valid_lft forever preferred_lft forever

[mysql@ms51 ~]$ sudo /sbin/ip a d 192.168.188.50/16 dev eth0
[mysql@ms51 ~]$ ip a
	..
	2: sit0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1000
	link/sit 0.0.0.0 brd 0.0.0.0
	36: eth0@if37: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
	link/ether 02:42:c0:a8:bc:33 brd ff:ff:ff:ff:ff:ff link-netnsid 0
	inet 192.168.188.51/24 brd 192.168.188.255 scope global eth0
	valid_lft forever preferred_lft forever
```
测试通过。
启动集群吧。
		
## 启动Xenon
目前mysql没运行

### 【node1】启动Xenon
```
[mysql@ms51 ~]$ cd /data/xenon-master/

[mysql@ms51 xenon-master]$ ls
bin  conf  docs  LICENSE  makefile  README.md  src  xenon.json

[mysql@ms51 xenon-master]$ bin/xenon -c /etc/xenon/xenon.json  > ./xenon.log 2>&1 &

[mysql@ms51 xenon-master]$ less xenon.log
```

检查xenon日志，可以看到xenon自己去通过mysqld_safe去启动mysql实例了，并设置为只读模式，检测了一下slave配置。
![title](https://raw.githubusercontent.com/jolleykong/img_host/master/imghost/2020/05/03/a-1588482017360.png)

通过ps命令可以看到本机mysqld和mysqld_safe 进程，可以通过PID看出，mysqld进程是被mysqld_safe进程拉起的。

```
[mysql@ms51 xenon-master]$ ps -ef|grep mysql
root       607   594  0 11:48 pts/0    00:00:00 su - mysql
mysql      608   607  0 11:48 pts/0    00:00:00 -bash
mysql      637   608  0 11:51 pts/0    00:00:01 bin/xenon -c /etc/xenon/xenon.json
mysql      648     1  0 11:51 pts/0    00:00:00 /bin/sh /usr/local/mysql/bin/mysqld_safe --defaults-file=/data/mysql/mysql3306/my3306.cnf
mysql     1766   648  0 11:51 pts/0    00:00:00 /usr/local/mysql/bin/mysqld --defaults-file=/data/mysql/mysql3306/my3306.cnf --basedir=/usr/local/mysql/ --datadir=/data/mysql/mysql3306/data --plugin-dir=/usr/local/mysql//lib/plugin --log-error=/data/mysql/mysql3306/logs/error.log --open-files-limit=65536 --pid-file=ms51.pid --socket=/data/mysql/mysql3306/tmp/mysql.sock --port=3306
```

Xenon进程
```
[mysql@ms51 xenon-master]$ ps -ef|grep xenon
mysql      637   608  0 11:51 pts/0    00:00:01 bin/xenon -c /etc/xenon/xenon.json
```
在node1本地可以登录MySQL实例了
```
[mysql@ms51 xenon-master]$ mysql -S /data/mysql/mysql3306/tmp/mysql.sock -pmysql
```

启动集群后， 可以发现Xenon目录结构有新对象
```[mysql@ms51 xenon-master]$ ls
bin  conf  docs  LICENSE  makefile  raft.meta  README.md  src  xenon.json  xenon.log
[mysql@ms51 xenon-master]$ ls raft.meta/
[mysql@ms51 xenon-master]$
```
这个目录在xenon添加成员后会保存一个json文件peers.json，里面记录成员信息。


node1查看Xenon集群状态
```
[mysql@ms51 xenon-master]$ bin/xenoncli cluster status
+---------------------+-------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
|         ID          |             Raft              | Mysqld  | Monitor |          Backup          |       Mysql        | IO/SQL_RUNNING | MyLeader |
+---------------------+-------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
| 192.168.188.51:8801 | [ViewID:0 EpochID:0]@FOLLOWER | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY] | [true/true]    |          |
|                     |                               |         |         | LastError:               |                    |                |          |
+---------------------+-------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
(1 rows)
#如果mysql列为空， 检查Xenon日志。应该是连接用户有问题，没连接上——这就是前面创建root@127.0.0.1的原因。
```


在node1中添加其它节点
就是xenon.json中的host段的内容，先添加node2
```
[mysql@ms51 xenon-master]$ bin/xenoncli cluster add 192.168.188.51:8801,192.168.188.52:8801
 2020/05/01 12:03:23.654459       [WARNING]     cluster.prepare.to.add.nodes[192.168.188.51:8801,192.168.188.52:8801].to.leader[]
 2020/05/01 12:03:23.654522       [WARNING]     cluster.canot.found.leader.forward.to[192.168.188.51:8801]
 2020/05/01 12:03:23.655442       [WARNING]     cluster.add.nodes.to.leader[].done
```
再检查集群状态
```
[mysql@ms51 xenon-master]$ bin/xenoncli cluster status
+---------------------+-------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
|         ID          |             Raft              | Mysqld  | Monitor |          Backup          |       Mysql        | IO/SQL_RUNNING | MyLeader |
+---------------------+-------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
| 192.168.188.51:8801 | [ViewID:0 EpochID:1]@FOLLOWER | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY] | [true/true]    |          |
|                     |                               |         |         | LastError:               |                    |                |          |
+---------------------+-------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
| 192.168.188.52:8801 | UNKNOW                        | UNKNOW  | UNKNOW  | UNKNOW                   | UNKNOW             | UNKNOW         | UNKNOW   |
+---------------------+-------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
(2 rows)
```
启动node2的xenon节点
```
[mysql@ms52 ~]$  ps -ef|grep mysql
root       576    24  0 12:07 pts/0    00:00:00 su - mysql
mysql      577   576  0 12:07 pts/0    00:00:00 -bash
mysql      594   577  0 12:07 pts/0    00:00:00 ps -ef
mysql      595   577  0 12:07 pts/0    00:00:00 grep --color=auto mysql

[mysql@ms52 ~]$ cd /data/xenon-master/
[mysql@ms52 xenon-master]$  bin/xenon -c /etc/xenon/xenon.json  > ./xenon.log 2>&1 &

[mysql@ms52 xenon-master]$  ps -ef|grep mysql
root       576    24  0 12:07 pts/0    00:00:00 su - mysql
mysql      577   576  0 12:07 pts/0    00:00:00 -bash
mysql      596   577  0 12:07 pts/0    00:00:00 bin/xenon -c /etc/xenon/xenon.json
mysql      608     1  0 12:07 pts/0    00:00:00 /bin/sh /usr/local/mysql/bin/mysqld_safe --defaults-file=/data/mysql/mysql3306/my3306.cnf
mysql     1726   608  0 12:07 pts/0    00:00:00 /usr/local/mysql/bin/mysqld --defaults-file=/data/mysql/mysql3306/my3306.cnf --basedir=/usr/local/mysql/ --datadir=/data/mysql/mysql3306/data --plugin-dir=/usr/local/mysql//lib/plugin --log-error=/data/mysql/mysql3306/logs/error.log --open-files-limit=65536 --pid-file=ms52.pid --socket=/data/mysql/mysql3306/tmp/mysql.sock --port=3306
```

回到node1上查看集群状态，能看到node2状态了
但是此时node2并未添加成员，所以集群并未真正建立。此时不会开启选举，因此二者都是readonly状态，myleader列也都是空值。
```
[mysql@ms51 xenon-master]$ bin/xenoncli cluster status
+---------------------+---------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
|         ID          |              Raft               | Mysqld  | Monitor |          Backup          |       Mysql        | IO/SQL_RUNNING | MyLeader |
+---------------------+---------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
| 192.168.188.51:8801 | [ViewID:34 EpochID:2]@CANDIDATE | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY] | [true/true]    |          |
|                     |                                 |         |         | LastError:               |                    |                |          |
+---------------------+---------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
| 192.168.188.52:8801 | [ViewID:0 EpochID:0]@FOLLOWER   | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY] | [true/true]    |          |
|                     |                                 |         |         | LastError:               |                    |                |          |
+---------------------+---------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
(2 rows)
```

node2上查看集群状态，只能看到自己
```
[mysql@ms52 xenon-master]$ bin/xenoncli cluster status
+---------------------+-------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
|         ID          |             Raft              | Mysqld  | Monitor |          Backup          |       Mysql        | IO/SQL_RUNNING | MyLeader |
+---------------------+-------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
| 192.168.188.52:8801 | [ViewID:0 EpochID:0]@FOLLOWER | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY] | [true/true]    |          |
|                     |                               |         |         | LastError:               |                    |                |          |
+---------------------+-------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
(1 rows)
```

在node2上添加集群成员node1
```
[mysql@ms52 xenon-master]$  bin/xenoncli cluster add 192.168.188.51:8801,192.168.188.52:8801
 2020/05/01 14:49:28.836254       [WARNING]     cluster.prepare.to.add.nodes[192.168.188.51:8801,192.168.188.52:8801].to.leader[]
 2020/05/01 14:49:28.836297       [WARNING]     cluster.canot.found.leader.forward.to[192.168.188.52:8801]
 2020/05/01 14:49:28.837039       [WARNING]     cluster.add.nodes.to.leader[].done

[mysql@ms52 xenon-master]$ bin/xenoncli cluster status
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
|         ID          |             Raft              | Mysqld  | Monitor |          Backup          |        Mysql        | IO/SQL_RUNNING |      MyLeader       |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.52:8801 | [ViewID:4 EpochID:1]@FOLLOWER | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY]  | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.51:8801 | [ViewID:4 EpochID:1]@LEADER   | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READWRITE] | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
(2 rows)
```

这个过程中node1上查看集群状态，可以发现随着选举的进行，两节点状态角色的转变
```
[mysql@ms51 xenon-master]$ bin/xenoncli cluster status
+---------------------+--------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
|         ID          |              Raft              | Mysqld  | Monitor |          Backup          |       Mysql        | IO/SQL_RUNNING | MyLeader |
+---------------------+--------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
| 192.168.188.51:8801 | [ViewID:1 EpochID:1]@CANDIDATE | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY] | [true/true]    |          |
|                     |                                |         |         | LastError:               |                    |                |          |
+---------------------+--------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
| 192.168.188.52:8801 | [ViewID:0 EpochID:0]@FOLLOWER  | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY] | [true/true]    |          |
|                     |                                |         |         | LastError:               |                    |                |          |
+---------------------+--------------------------------+---------+---------+--------------------------+--------------------+----------------+----------+
(2 rows)
[mysql@ms51 xenon-master]$ bin/xenoncli cluster status
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
|         ID          |             Raft              | Mysqld  | Monitor |          Backup          |        Mysql        | IO/SQL_RUNNING |      MyLeader       |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.51:8801 | [ViewID:4 EpochID:1]@LEADER   | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READWRITE] | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.52:8801 | [ViewID:4 EpochID:1]@FOLLOWER | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY]  | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
(2 rows)
```

**这一步可以得出结论：
	Xenon集群创建时，需要至少保证2个节点之间彼此添加对方为成员，才会开始选举。	否则都read only。**

在node1和node2上添加成员node3，并启动node3的Xenon
```
[mysql@ms51 xenon-master]$ bin/xenoncli cluster add 192.168.188.51:8801,192.168.188.52:8801,192.168.188.53:8801
 2020/05/01 15:00:52.517000       [WARNING]     cluster.prepare.to.add.nodes[192.168.188.51:8801,192.168.188.52:8801,192.168.188.53:8801].to.leader[192.168.188.51:8801]
 2020/05/01 15:00:52.518164       [WARNING]     cluster.add.nodes.to.leader[192.168.188.51:8801].done
[mysql@ms51 xenon-master]$ bin/xenoncli cluster status
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
|         ID          |             Raft              | Mysqld  | Monitor |          Backup          |        Mysql        | IO/SQL_RUNNING |      MyLeader       |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.51:8801 | [ViewID:6 EpochID:2]@LEADER   | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READWRITE] | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.52:8801 | [ViewID:6 EpochID:2]@FOLLOWER | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY]  | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.53:8801 | UNKNOW                        | UNKNOW  | UNKNOW  | UNKNOW                   | UNKNOW              | UNKNOW         | UNKNOW              |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
(3 rows)

[mysql@ms53 xenon-master]$  bin/xenon -c /etc/xenon/xenon.json  > xenon.log  2>&1 &
[mysql@ms53 xenon-master]$  bin/xenoncli cluster status
+---------------------+-------------------------------+------------+---------+--------------------------+--------------------+----------------+----------+
|         ID          |             Raft              |   Mysqld   | Monitor |          Backup          |       Mysql        | IO/SQL_RUNNING | MyLeader |
+---------------------+-------------------------------+------------+---------+--------------------------+--------------------+----------------+----------+
| 192.168.188.53:8801 | [ViewID:0 EpochID:0]@FOLLOWER | NOTRUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY] | [true/true]    |          |
|                     |                               |            |         | LastError:               |                    |                |          |
+---------------------+-------------------------------+------------+---------+--------------------------+--------------------+----------------+----------+
(1 rows)
```

通过node1查看集群状态
```
[mysql@ms51 xenon-master]$ bin/xenoncli cluster status
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
|         ID          |             Raft              | Mysqld  | Monitor |          Backup          |        Mysql        | IO/SQL_RUNNING |      MyLeader       |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.51:8801 | [ViewID:6 EpochID:2]@LEADER   | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READWRITE] | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.52:8801 | [ViewID:6 EpochID:2]@FOLLOWER | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY]  | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.53:8801 | [ViewID:0 EpochID:0]@FOLLOWER | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY]  | [true/true]    |                     |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
(3 rows)
```

node3添加集群成员，然后立即通过node1查看集群状态
```
[mysql@ms53 xenon-master]$  bin/xenoncli cluster add 192.168.188.51:8801,192.168.188.52:8801,192.168.188.53:8801
 2020/05/01 15:04:39.640015       [WARNING]     cluster.prepare.to.add.nodes[192.168.188.51:8801,192.168.188.52:8801,192.168.188.53:8801].to.leader[]
 2020/05/01 15:04:39.640080       [WARNING]     cluster.canot.found.leader.forward.to[192.168.188.53:8801]
 2020/05/01 15:04:39.641207       [WARNING]     cluster.add.nodes.to.leader[].done

[mysql@ms51 xenon-master]$ bin/xenoncli cluster status
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
|         ID          |             Raft              | Mysqld  | Monitor |          Backup          |        Mysql        | IO/SQL_RUNNING |      MyLeader       |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.51:8801 | [ViewID:6 EpochID:2]@LEADER   | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READWRITE] | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.52:8801 | [ViewID:6 EpochID:2]@FOLLOWER | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY]  | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.53:8801 | [ViewID:6 EpochID:2]@FOLLOWER | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY]  | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
(3 rows)
```

可以发现，在node3添加集群成员前，在集群中查看node3节点的MyLeader是空值。在node3添加集群成员后，集群状态中MyLeader列才有值。

**这一步可以得出结论：MyLeader非空时才意味着节点接入了Xenon集群的业务。**

			
# 启动集群后
因为踩过坑，一定要检查一下各节点半同步的状态
由于timeout设置的非常大，如果半同步未建立成功，那么数据库操作会hang，生产的话就出大事了。
- node1：
```
mysql> show master status;
+------------------+----------+--------------+------------------+------------------------------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                        |
+------------------+----------+--------------+------------------+------------------------------------------+
| mysql-bin.000005 |      194 |              |                  | 5ea86dca-8b58-11ea-86d8-0242c0a8bc33:1-5 |
+------------------+----------+--------------+------------------+------------------------------------------+
1 row in set (0.00 sec)

mysql> show slave status\G
Empty set (0.00 sec)

mysql> show global status like '%semi%';
+--------------------------------------------+-------+
| Variable_name                              | Value |
+--------------------------------------------+-------+
| Rpl_semi_sync_master_clients               | 2     |
| Rpl_semi_sync_master_status                | ON    |
+--------------------------------------------+-------+
15 rows in set (0.01 sec)
```

- node2:
```
mysql> show master status;
+------------------+----------+--------------+------------------+------------------------------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                        |
+------------------+----------+--------------+------------------+------------------------------------------+
| mysql-bin.000006 |      194 |              |                  | 5ea86dca-8b58-11ea-86d8-0242c0a8bc33:1-5 |
+------------------+----------+--------------+------------------+------------------------------------------+
1 row in set (0.00 sec)

mysql> show slave status \G
..
*************************** 1. row ***************************
1 row in set (0.00 sec)

mysql>
mysql> show global status like '%semi%';
+--------------------------------------------+-------+
| Variable_name                              | Value |
+--------------------------------------------+-------+
| Rpl_semi_sync_slave_status                 | ON    |
+--------------------------------------------+-------+
15 rows in set (0.01 sec)
```

- node3：
```
mysql>  show master status;
+------------------+----------+--------------+------------------+------------------------------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                        |
+------------------+----------+--------------+------------------+------------------------------------------+
| mysql-bin.000005 |      194 |              |                  | 5ea86dca-8b58-11ea-86d8-0242c0a8bc33:1-5 |
+------------------+----------+--------------+------------------+------------------------------------------+
1 row in set (0.00 sec)

mysql> show slave status \G
*************************** 1. row ***************************
..
1 row in set (0.00 sec)

mysql> show global status like '%semi%';
+--------------------------------------------+-------+
| Variable_name                              | Value |
+--------------------------------------------+-------+
| Rpl_semi_sync_slave_status                 | ON    |
+--------------------------------------------+-------+
15 rows in set (0.00 sec)
```

- 测试一下
前面配置Xenon参数的时候已经额外增加了主从角色的sysvars，以灵活启用半同步参数。
```	
mysql> create database kk;
Query OK, 1 row affected (0.15 sec)

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| kk                 |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
5 rows in set (0.00 sec)
```

Xenon集群到这里就搭建完了。

		
# 通过Xenon集群进行备份、扩容节点
思路：
	1. 模拟业务运行：使用循环，通过sip(vip)访问数据库，并不断的插入数据。
	2. 建立一个新环境，配置好os、mysql和xenon，不初始化mysql实例
	3. 在新环境中配置xen
	4. 尝试通过xen的backup和rebuildme建立新节点并加入到集群
		
先说结论：
	- 备份
		- 使用Xenon备份时，备份位置必须指定绝对路径，且mysql用户对该路径具有写权限。
		- 使用Xenon备份时，备份位置目录不存在时Xenon会自动通过ssh通道创建目录。
	- 重建/扩容
		- 为Xenon集群添加新节点时，新节点无需初始化MySQL实例，可以基于xenon backup直接rebuildme建立新节点。
		- Xenon rebuildme基于xtrabackup，因此在通过rebuildme添加新节点时，需要创建好mysql datadir和my.cnf ，与xenon.json中mysql section对应参数相符合。
				
## 扩容节点的初步尝试
- 查看当前集群情况
```
[mysql@ms52 xenon-master]$ bin/xenoncli cluster status
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
|         ID          |             Raft              | Mysqld  | Monitor |          Backup          |        Mysql        | IO/SQL_RUNNING |      MyLeader       |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.51:8801 | [ViewID:3 EpochID:0]@LEADER   | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READWRITE] | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.52:8801 | [ViewID:3 EpochID:0]@FOLLOWER | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY]  | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.53:8801 | [ViewID:3 EpochID:0]@FOLLOWER | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY]  | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
(3 rows)
```


- 集群里创建一个用户，供client角色使用
```
mysql>  create user kk@'192.168.188.%' identified by 'kk';
Query OK, 0 rows affected (0.02 sec)

mysql> grant super on *.* to  kk@'192.168.188.%';
Query OK, 0 rows affected (0.02 sec)

mysql> grant all privileges on *.* to kk@'192.168.188.%';
Query OK, 0 rows affected (0.01 sec)
```

随便找一个节点作为client角色，通过sip访问xen集群
这里选择使用ms53节点作为client
```
[mysql@ms53 xenon-master]$ mysql -h 192.168.188.50 -ukk -pkk
		
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| kk                 |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
5 rows in set (0.00 sec)

mysql> use kk
Database changed
mysql> show tables;
Empty set (0.00 sec)

mysql> create table k1(id int primary key auto_increment, numbers int);
Query OK, 0 rows affected (0.04 sec)

mysql> exit
```
- 模拟业务运行，不停产生事务
```
[mysql@ms53 xenon-master]$ while : ;do echo "insert into kk.k1(numbers) values(round(rand()*10086));" |mysql -h  192.168.188.50 -ukk -pkk ;sleep 10 ;done
```
- 另外起一个session ，查看一下表的状态
```
mysql> select count(*) from kk.k1;
+----------+
| count(*) |
+----------+
|     2779 |
+----------+
1 row in set (0.00 sec)
```
okay，让它先插着吧，我们去创建新环境。

- 创建新节点
[kk@kk ]# datadir docker run -d --name ms54 -h ms54 --privileged \
			--network net188 --ip 192.168.188.54 -p 9054:22 \
			-v /data/mysql57/:/opt \
			-v /data/datadir/57-4/:/data \
			-v /data/ofiles:/ofiles 
			cos:latest
- 配置新节点
	- 创建mysql用户
	步骤略。
	- 配置mysql环境
	步骤略。
	- 配置mysql用户ssh互信
	步骤略。
	- 安装xtrabackup
	步骤略。
	- 部署xenon
	步骤略。

- 尝试启动xenon
```
[mysql@ms54 xenon-master]$ bin/xenon -c /etc/xenon/xenon.json  > xenon.log 2>&1 &
[1] 18042
[mysql@ms54 xenon-master]$ bin/xenoncli cluster status
	cluster.go:227: unexpected error: get.client.error[dial tcp 192.168.188.54:8801: connect: connection refused]
	
	 2020/05/01 13:45:11.234158       [PANIC]        get.client.error[dial tcp 192.168.188.54:8801: connect: connection refused]
	panic:    [PANIC]        get.client.error[dial tcp 192.168.188.54:8801: connect: connection refused]
	
	goroutine 1 [running]:
	xbase/xlog.(*Log).Panic(0xc000184300, 0x8d111e, 0x2, 0xc000197b28, 0x1, 0x1)
	        /data/xenon-master/src/xbase/xlog/xlog.go:142 +0x153
	cli/cmd.ErrorOK(0x9796e0, 0xc000184880)
	        /data/xenon-master/src/cli/cmd/common.go:35 +0x245
	cli/cmd.clusterStatusCommandFn(0xc0001e4fc0, 0xcac370, 0x0, 0x0)
	        /data/xenon-master/src/cli/cmd/cluster.go:227 +0xaa
	vendor/github.com/spf13/cobra.(*Command).execute(0xc0001e4fc0, 0xcac370, 0x0, 0x0, 0xc0001e4fc0, 0xcac370)
	        /data/xenon-master/src/vendor/github.com/spf13/cobra/command.go:603 +0x22e
	vendor/github.com/spf13/cobra.(*Command).ExecuteC(0xc78820, 0x1, 0xc000197f78, 0x40744f)
	        /data/xenon-master/src/vendor/github.com/spf13/cobra/command.go:689 +0x2bc
	vendor/github.com/spf13/cobra.(*Command).Execute(...)
	        /data/xenon-master/src/vendor/github.com/spf13/cobra/command.go:648
	main.main()
	        /data/xenon-master/src/cli/cli.go:43 +0x31
```
会报错，查看日志是无法访问本地mysql

- 无视错误，直接添加集群成员
```
[mysql@ms54 xenon-master]$  bin/xenoncli cluster add 192.168.188.51:8801,192.168.188.52:8801,192.168.188.53:8801,192.168.188.54:8801
 2020/05/01 13:46:11.930873       [WARNING]     cluster.prepare.to.add.nodes[192.168.188.51:8801,192.168.188.52:8801,192.168.188.53:8801,192.168.188.54:8801].to.leader[]
 2020/05/01 13:46:11.930963       [WARNING]     cluster.canot.found.leader.forward.to[192.168.188.54:8801]
 2020/05/01 13:46:11.933108       [WARNING]     cluster.add.nodes.to.leader[].done
[mysql@ms54 xenon-master]$ bin/xenoncli cluster status
+---------------------+-------------------------------+------------+---------+--------------------------+---------------------+----------------+---------------------+
|         ID          |             Raft              |   Mysqld   | Monitor |          Backup          |        Mysql        | IO/SQL_RUNNING |      MyLeader       |
+---------------------+-------------------------------+------------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.54:8801 | [ViewID:0 EpochID:3]@FOLLOWER | NOTRUNNING | ON      | state:[NONE]␤            | []                  | [false/false]  |                     |
|                     |                               |            |         | LastError:               |                     |
+---------------------+-------------------------------+------------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.51:8801 | [ViewID:3 EpochID:0]@LEADER   | RUNNING    | ON      | state:[NONE]␤            | [ALIVE] [READWRITE] | [true/true]    | 192.168.188.51:8801 |
|                     |                               |            |         | LastError:               |                     |
+---------------------+-------------------------------+------------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.52:8801 | [ViewID:3 EpochID:0]@FOLLOWER | RUNNING    | ON      | state:[NONE]␤            | [ALIVE] [READONLY]  | [true/true]    | 192.168.188.51:8801 |
|                     |                               |            |         | LastError:               |                     |
+---------------------+-------------------------------+------------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.53:8801 | [ViewID:3 EpochID:0]@FOLLOWER | RUNNING    | ON      | state:[NONE]␤            | [ALIVE] [READONLY]  | [true/true]    | 192.168.188.51:8801 |
|                     |                               |            |         | LastError:               |                     |
+---------------------+-------------------------------+------------+---------+--------------------------+---------------------+----------------+---------------------+
(4 rows)
```
竟然成功了，好像有戏！

- 尝试无备份情况下直接rebuild
```
[mysql@ms54 xenon-master]$ bin/xenoncli mysql rebuildme
 2020/05/01 13:47:36.300229       [WARNING]     =====prepare.to.rebuildme=====
                        IMPORTANT: Please check that the backup run completes successfully.
                                   At the end of a successful backup run innobackupex
                                   prints "completed OK!".

 2020/05/01 13:47:36.300912       [WARNING]     S1-->check.raft.leader
 2020/05/01 13:47:36.315906       [WARNING]     rebuildme.found.best.slave[192.168.188.52:8801].leader[192.168.188.51:8801]
 2020/05/01 13:47:36.315973       [WARNING]     S2-->prepare.rebuild.from[192.168.188.52:8801]....
 2020/05/01 13:47:36.317637       [WARNING]     S3-->check.bestone[192.168.188.52:8801].is.OK....
 2020/05/01 13:47:36.317689       [WARNING]     S4-->set.learner
 2020/05/01 13:47:36.319220       [WARNING]     S5-->stop.monitor
 2020/05/01 13:47:36.320562       [WARNING]     S6-->kill.mysql
 2020/05/01 13:47:36.347934       [WARNING]     S7-->check.bestone[192.168.188.52:8801].is.OK....
 2020/05/01 13:47:36.351788       [WARNING]     S8-->rm.datadir[/data/mysql/mysql3306/data]
 2020/05/01 13:47:36.351846       [WARNING]     S9-->xtrabackup.begin....
 2020/05/01 13:47:36.352273       [WARNING]     rebuildme.backup.req[&{From: BackupDir:/data/mysql/mysql3306/data SSHHost:192.168.188.54 SSHUser:mysql SSHPasswd:mysql SSHPort:22 IOPSLimits:100000 XtrabackupBinDir:/usr/bin}].from[192.168.188.52:8801]
 2020/05/01 13:47:36.862121       [PANIC]        rsp[cmd.outs.[completed OK!].found[1]!=expects[2]] != [OK]
panic:    [PANIC]        rsp[cmd.outs.[completed OK!].found[1]!=expects[2]] != [OK]

goroutine 1 [running]:
xbase/xlog.(*Log).Panic(0xc000094300, 0x8d8f06, 0xf, 0xc000191d88, 0x1, 0x1)
        /data/xenon-master/src/xbase/xlog/xlog.go:142 +0x153
cli/cmd.RspOK(...)
        /data/xenon-master/src/cli/cmd/common.go:41
cli/cmd.mysqlRebuildMeCommandFn(0xc0000e8b40, 0xcac370, 0x0, 0x0)
        /data/xenon-master/src/cli/cmd/mysql.go:268 +0x847
vendor/github.com/spf13/cobra.(*Command).execute(0xc0000e8b40, 0xcac370, 0x0, 0x0, 0xc0000e8b40, 0xcac370)
        /data/xenon-master/src/vendor/github.com/spf13/cobra/command.go:603 +0x22e
vendor/github.com/spf13/cobra.(*Command).ExecuteC(0xc78820, 0x1, 0xc000191f78, 0x40744f)
        /data/xenon-master/src/vendor/github.com/spf13/cobra/command.go:689 +0x2bc
vendor/github.com/spf13/cobra.(*Command).Execute(...)
        /data/xenon-master/src/vendor/github.com/spf13/cobra/command.go:648
main.main()
        /data/xenon-master/src/cli/cli.go:43 +0x31
```
毫无意外的失败了，是因为没有备份吗？

那备份一下再试试

- 直接在新节点上执行备份
```
[mysql@ms54 xenon-master]$ bin/xenoncli mysql backup --to=/data/backup
 2020/05/01 13:49:02.476638       [WARNING]     rebuildme.found.best.slave[192.168.188.52:8801].leader[192.168.188.51:8801]
 2020/05/01 13:49:02.476764       [WARNING]     S1-->found.the.best.backup.host[192.168.188.52:8801]....
 2020/05/01 13:49:02.483030       [WARNING]     S2-->rm.and.mkdir.backupdir[/data/backup]
 2020/05/01 13:49:02.483097       [WARNING]     S3-->xtrabackup.begin....
 2020/05/01 13:49:02.483672       [WARNING]     rebuildme.backup.req[&{From: BackupDir:/data/backup SSHHost:192.168.188.54 SSHUser:mysql SSHPasswd:mysql SSHPort:22 IOPSLimits:100000 XtrabackupBinDir:/usr/bin}].from[192.168.188.52:8801]
 2020/05/01 13:49:09.695471       [WARNING]     S3-->xtrabackup.end....
 2020/05/01 13:49:09.695495       [WARNING]     S4-->apply-log.begin....
 2020/05/01 13:49:15.592119       [WARNING]     S4-->apply-log.end....
 2020/05/01 13:49:15.592178       [WARNING]     completed OK!
 2020/05/01 13:49:15.592183       [WARNING]     backup.all.done....
```

- 再次尝试rebuildme
依然失败。

突然想到，xtrabackup恢复的时候是需要指定my.cnf文件的， 而我当前新环境并没有！也没创建实例的数据目录！

- 创建目录，创建my3306.cnf
```
[mysql@ms54 xenon-master]$ mkdir /data/mysql/mysql3306/{data,logs,tmp} -p
[mysql@ms54 xenon-master]$ vi /data/mysql/mysql3306/my3306.cnf
```
- 终于成功了
```
[mysql@ms54 xenon-master]$ bin/xenoncli mysql rebuildme
 2020/05/01 14:04:53.910063       [WARNING]     =====prepare.to.rebuildme=====
                        IMPORTANT: Please check that the backup run completes successfully.
                                   At the end of a successful backup run innobackupex
                                   prints "completed OK!".

 2020/05/01 14:04:53.910476       [WARNING]     S1-->check.raft.leader
 2020/05/01 14:04:53.921750       [WARNING]     rebuildme.found.best.slave[192.168.188.52:8801].leader[192.168.188.51:8801]
 2020/05/01 14:04:53.921809       [WARNING]     S2-->prepare.rebuild.from[192.168.188.52:8801]....
 2020/05/01 14:04:53.923227       [WARNING]     S3-->check.bestone[192.168.188.52:8801].is.OK....
 2020/05/01 14:04:53.923273       [WARNING]     S4-->set.learner
 2020/05/01 14:04:53.924674       [WARNING]     S5-->stop.monitor
 2020/05/01 14:04:53.926274       [WARNING]     S6-->kill.mysql
 2020/05/01 14:04:53.942920       [WARNING]     S7-->check.bestone[192.168.188.52:8801].is.OK....
 2020/05/01 14:04:53.945976       [WARNING]     S8-->rm.datadir[/data/mysql/mysql3306/data]
 2020/05/01 14:04:53.946023       [WARNING]     S9-->xtrabackup.begin....
 2020/05/01 14:04:53.946406       [WARNING]     rebuildme.backup.req[&{From: BackupDir:/data/mysql/mysql3306/data SSHHost:192.168.188.54 SSHUser:mysql SSHPasswd:mysql SSHPort:22 IOPSLimits:100000 XtrabackupBinDir:/usr/bin}].from[192.168.188.52:8801]
 2020/05/01 14:05:00.153294       [WARNING]     S9-->xtrabackup.end....
 2020/05/01 14:05:00.153352       [WARNING]     S10-->apply-log.begin....
 2020/05/01 14:05:05.228702       [WARNING]     S10-->apply-log.end....
 2020/05/01 14:05:05.228755       [WARNING]     S11-->start.mysql.begin...
 2020/05/01 14:05:05.229831       [WARNING]     S11-->start.mysql.end...
 2020/05/01 14:05:05.229890       [WARNING]     S12-->wait.mysqld.running.begin....
 2020/05/01 14:05:08.238027       [WARNING]     wait.mysqld.running...
 2020/05/01 14:05:08.247805       [WARNING]     S12-->wait.mysqld.running.end....
 2020/05/01 14:05:08.247866       [WARNING]     S13-->wait.mysql.working.begin....
 2020/05/01 14:05:11.250009       [WARNING]     wait.mysql.working...
 2020/05/01 14:05:11.250786       [WARNING]     S13-->wait.mysql.working.end....
 2020/05/01 14:05:11.250863       [WARNING]     S14-->stop.and.reset.slave.begin....
 2020/05/01 14:05:11.354249       [WARNING]     S14-->stop.and.reset.slave.end....
 2020/05/01 14:05:11.354321       [WARNING]     S15-->reset.master.begin....
 2020/05/01 14:05:11.429591       [WARNING]     S15-->reset.master.end....
 2020/05/01 14:05:11.430310       [WARNING]     S15-->set.gtid_purged[5ea86dca-8b58-11ea-86d8-0242c0a8bc33:1-97741
].begin....
 2020/05/01 14:05:11.441819       [WARNING]     S15-->set.gtid_purged.end....
 2020/05/01 14:05:11.441889       [WARNING]     S16-->enable.raft.begin...
 2020/05/01 14:05:11.443257       [WARNING]     S16-->enable.raft.done...
 2020/05/01 14:05:11.443320       [WARNING]     S17-->wait[3000 ms].change.to.master...
 2020/05/01 14:05:11.443833       [WARNING]     S18-->start.slave.begin....
 2020/05/01 14:05:11.494324       [WARNING]     S18-->start.slave.end....
 2020/05/01 14:05:11.494404       [WARNING]     completed OK!
 2020/05/01 14:05:11.494422       [WARNING]     rebuildme.all.done....
```
成功了！

- 检查一下集群状态
```
[mysql@ms53 xenon-master]$ bin/xenoncli cluster status
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
|         ID          |             Raft              | Mysqld  | Monitor |          Backup          |        Mysql        | IO/SQL_RUNNING |      MyLeader       |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.51:8801 | [ViewID:5 EpochID:1]@LEADER   | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READWRITE] | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.52:8801 | [ViewID:5 EpochID:1]@FOLLOWER | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY]  | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.53:8801 | [ViewID:5 EpochID:1]@FOLLOWER | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY]  | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
| 192.168.188.54:8801 | [ViewID:5 EpochID:1]@FOLLOWER | RUNNING | ON      | state:[NONE]␤            | [ALIVE] [READONLY]  | [true/true]    | 192.168.188.51:8801 |
|                     |                               |         |         | LastError:               |                     |                |                     |
+---------------------+-------------------------------+---------+---------+--------------------------+---------------------+----------------+---------------------+
(4 rows)
```

- 检查一下master和新节点的数据状态、同步状态
新节点：
```
[mysql@ms54 xenon-master]$ mysql -S /data/mysql/mysql3306/tmp/mysql.sock  -pmysql

mysql> select count(*) from kk.k1;
+----------+
| count(*) |
+----------+
|   104875 |
+----------+
1 row in set (0.01 sec)
```
master：
```
mysql> select count(*) from kk.k1;
+----------+
| count(*) |
+----------+
|   104875 |
+----------+
1 row in set (0.01 sec)
```
	
集群扩容成功！


		
# Xenon集群的搭建总结：
1. 集群节点数要奇数，不然影响选举。
2. 半同步的status非常值得关注，由于timeout设置的非常大，如果半同步未建立成功，那么数据库操作会hang（等待ACK，但是slave永远不会发出ACK，且slave已经完成了复制过来的动作）。解决办法是手动将master复制降级为异步复制：在master上直接运行 set global rpl_semi_sync_master_enabled=0; 之后master会立即完成动作，此时再去调整各节点参数以启用半同步。


# Xenon集群节点状态的探索总结：
	验证过程太过冗长，直接上结论。
1. 初始化集群阶段， 启动xenon@node1。此时xenon中查看集群状态，node1节点恒为read only。
2. 在node1上增加成员节点node2、node3 ，启动xenon@node2。此时xenon中查看集群状态，node1节点恒为read only，node2节点恒为read only，MyLeader都为空。
3. 在node2上增加成员节点node1、node3。此时通过node1查看集群状态，node1、node2节点会短时间内完成选举，胜出者成为master，节点状态变更为read/write。
4. 如果3节点集群突然s2个slave都死掉， xenon在10次重试后，master会解除vip（sip），唯一存活的实例切换为read only。
5. 集群内单节点存活时，单节点永远ro；大于等于2个节点时会选举master，master会rw。
6. 如果所有节点上的xenon进程都被杀掉，那么sip会残留在最后绑定sip的节点上（暂称为旧master）。如果不理会旧master的xen状态，只对其它节点重启xenon后，新master会持有sip。此时两个节点查看ip的话，会发现都持有sip。但是由于arping动作，网络内其它机器都会连接到新master上。
7. 接6，通过在旧master上ssh sip及mysql -h sip， 会发现旧master依然毫不知情的连接给自己， 哈哈。从这一步可以明白xenon的一个逻辑——加入xenon集群后，经过选举，落选者执行会被raft执行leader-stop-command，释放掉sip。

	


# Xenon backup/rebuild 探索总结：
- backup 备份
	- 使用Xenon备份时，备份位置必须指定绝对路径，且mysql用户对该路径具有写权限。
	- 使用Xenon备份时，备份位置目录不存在时Xenon会自动通过ssh通道创建目录。
- rebuileme 重建/扩容
	- 为Xenon集群添加新节点时，新节点无需初始化MySQL实例，可以基于xenon backup直接rebuildme建立新节点。
	- Xenon rebuildme基于xtrabackup，因此在通过rebuildme添加新节点时，需要创建好mysql datadir和my.cnf ，与xenon.json中mysql section对应参数相符合。


