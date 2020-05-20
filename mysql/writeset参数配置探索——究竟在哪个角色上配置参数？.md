关于writeset，一直以来我都是所有节点同时配置下面参数：
```
binlog_transaction_dependency_tracking=WRITESET
transaction_write_set_extraction=xxhash64
```
但是这几天在尝试整理的时候，突然发现writeset的概念并不是想象中的那么清晰，
也想要验证一下老师提到的结论：
1. 8.0的设计是针对从库，==主库开启writeset后（个人补充说明），== 即使主库在串行提交的事务，只要不互相冲突，在slave上也可以并行回放。
2. 如果主库配置了binlog group commit，从库开了writeset，会优先使用writeset。

- 从group commit进化的角度、及writeset的hash表原理来看，参数应该设置在master
- 从结论2的角度来看，参数应该设置在slave

为此，做了一个实验，分别在两个角色上配置以上2个参数，来验证究竟哪一边设置才是有效的。

# 环境简介
|IP|port|role|info|
|-|-|-|-|
|192.168.188.81|3316|node1|master|
|192.168.188.82|3316|node2|slave1|
|192.168.188.83|3316|node3|slave2|
 1主2从， MySQL版本8.0.19 

# 实验一：writeset配置在slave上 
- slave配置writeset：binlog_transaction_dependency_tracking=WRITESET & transaction_write_set_extraction=xxhash64
- master只配置：binlog_group_commit_sync_delay & binlog_group_commit_sync_no_delay_count

## 配置参数
``` shell
master:
binlog_group_commit_sync_delay       =100
binlog_group_commit_sync_no_delay_count = 10 

gtid_mode                           =on
enforce_gtid_consistency            =on
binlog_format                       =row
skip_slave_start                     =1 
master_info_repository               =table 
relay_log_info_repository            =table
```

``` shell
slave:
binlog_transaction_dependency_tracking=WRITESET
transaction_write_set_extraction=xxhash64

skip_slave_start                     =1             
master_info_repository               =table         
relay_log_info_repository            =table         
slave_parallel_type                  =logical_clock 
slave_parallel_workers               =4  
#slave-preserve-commit-order         =ON
```
## 验证实验
- 为方便查看，slave上先切换日志
``` sql
root@slave1 [kk]>flush logs;
Query OK, 0 rows affected (0.05 sec)
```

- 在master上创建1张表，并插入数据
``` sql
root@master [kk]>flush logs;
Query OK, 0 rows affected (0.05 sec)

root@master [kk]>create table k3 (id int auto_increment primary key , dtl varchar(20) default 'a');
Query OK, 0 rows affected (0.05 sec)

root@master [kk]>insert into k3(dtl) values ('a');
Query OK, 1 row affected (0.02 sec)

root@master [kk]>insert into k3(dtl) values ('b');
Query OK, 1 row affected (0.01 sec)

root@master [kk]>insert into k3(dtl) values ('c');
Query OK, 1 row affected (0.01 sec)

root@master [kk]>insert into k3(dtl) values ('d');
Query OK, 1 row affected (0.02 sec)
```

- 解析master的binlog，可以看到，master的binlog上每一个事务都是自成一组（每一个事务一个last_committed）
``` shell
[root@ms81 logs]# mysqlbinlog -vvv --base64-output=decode-rows mysql-bin.000006 |grep last_committed
#200514 11:09:58 server id 813316  end_log_pos 272 CRC32 0xa8811d1b     GTID    last_committed=0        sequence_number=1       rbr_only=no     original_committed_timestamp=1589425798790755immediate_commit_timestamp=1589425798790755      transaction_length=242
#200514 11:10:05 server id 813316  end_log_pos 516 CRC32 0x8f66cd2f     GTID    last_committed=1        sequence_number=2       rbr_only=yes    original_committed_timestamp=1589425805035310immediate_commit_timestamp=1589425805035310      transaction_length=335
#200514 11:10:06 server id 813316  end_log_pos 851 CRC32 0x909932ba     GTID    last_committed=2        sequence_number=3       rbr_only=yes    original_committed_timestamp=1589425806709355immediate_commit_timestamp=1589425806709355      transaction_length=335
#200514 11:10:08 server id 813316  end_log_pos 1186 CRC32 0x50c4e104    GTID    last_committed=3        sequence_number=4       rbr_only=yes    original_committed_timestamp=1589425808607557immediate_commit_timestamp=1589425808607557      transaction_length=335
#200514 11:10:10 server id 813316  end_log_pos 1521 CRC32 0xf074c523    GTID    last_committed=4        sequence_number=5       rbr_only=yes    original_committed_timestamp=1589425810449588immediate_commit_timestamp=1589425810449588      transaction_length=335
```

- 然后去slave上解析binlog，可以看到，slave的binlog上这几个insert的事务成为了一组（几个事务在一个last_committed中）
``` shell
[root@ms82 logs]# mysqlbinlog -vvv --base64-output=decode-rows mysql-bin.000003 |grep last_committed
#200514 11:09:58 server id 813316  end_log_pos 279 CRC32 0xbf39f999     GTID    last_committed=0        sequence_number=1       rbr_only=no     original_committed_timestamp=1589425798790755immediate_commit_timestamp=1589425798840582      transaction_length=249
#200514 11:10:05 server id 813316  end_log_pos 530 CRC32 0x7e0b2634     GTID    last_committed=1        sequence_number=2       rbr_only=yes    original_committed_timestamp=1589425805035310immediate_commit_timestamp=1589425805046566      transaction_length=337
#200514 11:10:06 server id 813316  end_log_pos 867 CRC32 0x79b980e9     GTID    last_committed=1        sequence_number=3       rbr_only=yes    original_committed_timestamp=1589425806709355immediate_commit_timestamp=1589425806723726      transaction_length=337
#200514 11:10:08 server id 813316  end_log_pos 1204 CRC32 0x09b728d3    GTID    last_committed=1        sequence_number=4       rbr_only=yes    original_committed_timestamp=1589425808607557immediate_commit_timestamp=1589425808616207      transaction_length=337
#200514 11:10:10 server id 813316  end_log_pos 1541 CRC32 0x499da890    GTID    last_committed=1        sequence_number=5       rbr_only=yes    original_committed_timestamp=1589425810449588immediate_commit_timestamp=1589425810459612      transaction_length=337
```



- 查看一下master的配置，虽然my.cnf中没配置binlog_transaction_dependency_tracking参数，但是该参数在8.0中默认设置为COMMIT_ORDER
```
root@localhost [kk]>show global variables like '%tracking%';
+----------------------------------------+--------------+
| Variable_name                          | Value        |
+----------------------------------------+--------------+
| binlog_transaction_dependency_tracking | COMMIT_ORDER |
+----------------------------------------+--------------+
1 row in set (0.02 sec)
```
## 实验一的结论
根据实验一的现象，套用复制流程可推测为：  
	1. master生成串行事务日志到binlog，    
	2. 通过复制结构将binlog拉取到slave，称为relay log  
	3. slave会按照master的binlog内容（relay log）进行apply  
	4. apply后再写入到slave的binlog  
那么slave的binlog能说明slave是怎么应用的relay log么？ 还是因为slave配置了writeset，所以slave生成的binlog中发生了write-set？  


# 实验二：writeset配置在master上
- slave**不配置**writeset：binlog_transaction_dependency_tracking=WRITESET & transaction_write_set_extraction=xxhash64
- master增加配置：binlog_transaction_dependency_tracking=WRITESET & transaction_write_set_extraction=xxhash64


## 配置参数，并重启实例
``` shell
master:
binlog_transaction_dependency_tracking=WRITESET
transaction_write_set_extraction=xxhash64

binlog_group_commit_sync_delay       =100
binlog_group_commit_sync_no_delay_count = 10 

gtid_mode                           =on
enforce_gtid_consistency            =on
binlog_format                       =row
skip_slave_start                     =1 
master_info_repository               =table 
relay_log_info_repository            =table
```

``` shell
slave:
#binlog_transaction_dependency_tracking=WRITESET  #注释掉
#transaction_write_set_extraction=xxhash64   #注释掉

skip_slave_start                     =1             
master_info_repository               =table         
relay_log_info_repository            =table         
slave_parallel_type                  =logical_clock 
slave_parallel_workers               =4  
#slave-preserve-commit-order         =ON
```
## 验证实验
- 还是为方便查看，slave上先切换日志
``` sql
root@slave1 [kk]>flush logs;
Query OK, 0 rows affected (0.05 sec)
```

- 在master上创建1张表，并插入数据
``` sql
root@master [(none)]>flush logs;
Query OK, 0 rows affected (0.03 sec)

root@master [kk]>create table k4 (id int auto_increment primary key , dtl varchar(20) default 'a');
Query OK, 0 rows affected (0.05 sec)

root@master [kk]>insert into k4(dtl) values ('a');
Query OK, 1 row affected (0.02 sec)

root@master [kk]>insert into k4(dtl) values ('b');
Query OK, 1 row affected (0.01 sec)

root@master [kk]>insert into k4(dtl) values ('c');
Query OK, 1 row affected (0.01 sec)

root@master [kk]>insert into k4(dtl) values ('d');
Query OK, 1 row affected (0.01 sec)

```

- 解析master的binlog，可以看到，master上insert事务组成了一组（具有相同的last_committed）
``` shell
[root@ms81 logs]# mysqlbinlog -vvv --base64-output=decode-rows mysql-bin.000008 |grep last_committed
#200514 11:25:55 server id 813316  end_log_pos 272 CRC32 0x1a3b45da     GTID    last_committed=0        sequence_number=1       rbr_only=no     original_committed_timestamp=1589426755949559immediate_commit_timestamp=1589426755949559      transaction_length=242
#200514 11:26:06 server id 813316  end_log_pos 516 CRC32 0x9f51382b     GTID    last_committed=1        sequence_number=2       rbr_only=yes    original_committed_timestamp=1589426766237292immediate_commit_timestamp=1589426766237292      transaction_length=335
#200514 11:26:08 server id 813316  end_log_pos 851 CRC32 0xb02fc356     GTID    last_committed=1        sequence_number=3       rbr_only=yes    original_committed_timestamp=1589426768166475immediate_commit_timestamp=1589426768166475      transaction_length=335
#200514 11:26:09 server id 813316  end_log_pos 1186 CRC32 0x615fb932    GTID    last_committed=1        sequence_number=4       rbr_only=yes    original_committed_timestamp=1589426769816765immediate_commit_timestamp=1589426769816765      transaction_length=335
#200514 11:26:12 server id 813316  end_log_pos 1521 CRC32 0x13bceeb8    GTID    last_committed=1        sequence_number=5       rbr_only=yes    original_committed_timestamp=1589426772153679immediate_commit_timestamp=1589426772153679      transaction_length=335
```

**看来writeset在主库上影响了binlog的内容了**，接下来看一下slave的binlog

- 然后去slave上解析binlog，可以看到，slave上这几个insert的事务各自成了一组
``` shell
[root@ms82 logs]# mysqlbinlog -vvv --base64-output=decode-rows mysql-bin.000005 |grep last_committed
#200514 11:25:55 server id 813316  end_log_pos 279 CRC32 0x96a31487     GTID    last_committed=0        sequence_number=1       rbr_only=no     original_committed_timestamp=1589426755949559immediate_commit_timestamp=1589426755999296      transaction_length=249
#200514 11:26:06 server id 813316  end_log_pos 530 CRC32 0x54711cb2     GTID    last_committed=1        sequence_number=2       rbr_only=yes    original_committed_timestamp=1589426766237292immediate_commit_timestamp=1589426766253024      transaction_length=337
#200514 11:26:08 server id 813316  end_log_pos 867 CRC32 0xf20ad235     GTID    last_committed=2        sequence_number=3       rbr_only=yes    original_committed_timestamp=1589426768166475immediate_commit_timestamp=1589426768176639      transaction_length=337
#200514 11:26:09 server id 813316  end_log_pos 1204 CRC32 0xa3b00643    GTID    last_committed=3        sequence_number=4       rbr_only=yes    original_committed_timestamp=1589426769816765immediate_commit_timestamp=1589426769825978      transaction_length=337
#200514 11:26:12 server id 813316  end_log_pos 1541 CRC32 0xce0fd88f    GTID    last_committed=4        sequence_number=5       rbr_only=yes    original_committed_timestamp=1589426772153679immediate_commit_timestamp=1589426772164468      transaction_length=337
```



此时slave的参数binlog_transaction_dependency_tracking为默认值

``` sql
root@slave1 [(none)]>show global variables like '%tracking%';
+----------------------------------------+--------------+
| Variable_name                          | Value        |
+----------------------------------------+--------------+
| binlog_transaction_dependency_tracking | COMMIT_ORDER |
+----------------------------------------+--------------+
1 row in set (0.01 sec)
```


## 实验二结论
根据实验二的现象，套用复制流程可推测为：  
	1. master生成~~串行~~事务，writeset特性将事务按照write-set进行分组，写到binlog中  
	2. 通过复制结构将binlog拉取到slave，称为relay log  
	3. slave会按照master的binlog内容（relay log）进行apply  
	4. apply后再写入到slave的binlog  

参考官方文档，我倾向于认为，slave应用relay log时是按照master的writeset分组进行并行apply的。
那么，目前的实验结论就与前面的结论2相悖了。
> The source of dependency information that the master uses to determine which transactions can be executed in parallel by the slave's multithreaded applier. This variable can take one of the three values described in the following list:
> - COMMIT_ORDER: Dependency information is generated from the master's commit timestamps. This is the default. This mode is also used for any transactions without write sets, even if this variable's is WRITESET or WRITESET_SESSION; this is also the case for transactions updating tables without primary keys and transactions updating tables having foreign key constraints.

> - WRITESET: Dependency information is generated from the master's write set, and any transactions which write different tuples can be parallelized.

> - WRITESET_SESSION: Dependency information is generated from the master's write set, but no two updates from the same session can be reordered.


