#!/bin/bash
#*************************************************************************************************
# A useful script for automatic setup MySQL 8.0 on Linux. 
# v3.0	Create by KK. 20190830
#
# 	Usage: mysql_onekey.sh [SOURCE_PATH]... [PORT]...
#
#	-SOURCE_PATH:	MySQL binary package unpack directory location
#	-PORT:		MySQL Instance Port (number)
#
# How to use ?  						| Example:
#	1.Download MySQL_Binary_Package;  	| bash> wget xxxxxxx/mysql_80.tar.gz
#	2.Unpack the package;				| bash> tar zxf mysql_80.tar.gz -C /opt
#	3.Run me! with UNPACK_PATH and Port;| bash> bash ./mysql_onekey.sh /opt/mysql_80 3306
#	4.Enjoy it!
#
# 中文简介：
#     MySQL初始化脚本，基于CentOS7.6 + MySQL 8.0 编写。
# 特性：
#   *.如果OS中已经有部署过MySQL，且配置了PATH，那么就直接沿用MySQL配置，仅仅在数据目录进行新增。
#   *.使用规则目录命名，如果端口对应目录已存在，那么会检测对应目录是否包含数据文件，如果包含数据文件，基于安全考虑拒绝继续运行。
#	*.考虑到交互输入解压路径的不便利，直接使用参数传入，这样可以在运行时直接补齐路径。
#	*.考虑到批量初始化（如果可能）的便利性，将参数2设置为端口号，这样的话更懒一些。
###################################################################################################
# v3.0	ADD OS parameters -- ulimit,io_scheduler,NUMA etc.
# v3.1	ulimit写在sysctl.conf文件中并不能完成预期目标，改为修改/etc/security/limits.conf
# v3.2	修复了一个神奇的NC的问题，先建立用户，否则新系统初始化时会失败一次。
# v3.2.1	改动server-id生成逻辑，现在根据ip最末尾和实例端口号来设定server-id，应该就不会再出现冲突了。
###################################################################################################
# 想象空间
# #自动配置init.d #定制内存参数

#######################################OS INITIALIZE#################################################
# Modify sysctl.conf
if grep -q 'vm\.swappiness' /etc/sysctl.conf ;then
	sed -i '/vm\.swappiness/c vm.swappiness=1' /etc/sysctl.conf
else
	echo "vm.swappiness=1" >> /etc/sysctl.conf
fi

#if grep -q '^ulimit \-n' /etc/rc.local ;then
#	sed -i '/^ulimit \-n/c ulimit -n 65535' /etc/rc.local
#else
#	echo "ulimit -n 65535" >> /etc/rc.local
cat <<EOE >> /etc/security/limits.conf
* soft nofile 65535
* hard nofile 65535
EOE
ulimit -n 65535

#fi
sysctl -p >/dev/null

# Change io scheduler to DEADLINE on CentOS/RHEL 7+
echo deadline > /sys/block/sda/queue/scheduler
grubby --update-kernel=ALL --args="elevator=deadline" &>/dev/null

# Turn off NUMA
sed -i '/^numa/c numa=off'  /etc/default/grub
grub2-mkconfig -o /etc/grub2.cfg >/dev/null

# Give me a sign
echo -e "==============================================================================\n`date '+%h %d %H:%m:%S'` OS INITIALIZED!\n"

#######################################MYSQL INSTALL#################################################
# Step 0
# create os account and group
id mysql &>/dev/null
if [ $? -ne 0 ] ;then
	egrep "^mysql" /etc/group &> /dev/null
	if [ $? -ne 0 ] ;then 
		groupadd -g 2000 mysql
	fi
	useradd -g mysql -u 2000 -s /sbin/nologin -d /usr/local/mysql -MN mysql
fi
# Give me a sign
echo -e "`date '+%h %d %H:%m:%S'` MySQL User Created!\n"

# Step 1
# get arguments 
arg1=$1
arg2=$2
let portnum=$arg2*1
# make $sourcedir key
if [[ $# -ne 2 ]] ;then
        echo -e "Arguments error! usage: \n\tmysql_onekey.sh [source_path] [port] \nScript Exited.\n"
        exit 1;
else
        if [[ "$arg1" =~ ^/ ]] ;then
                # loop
                while :
                do
			# 判断是否为真实的mysql目录，并补充完整路径
                        if [[ "$arg1" =~ /$  ]] ;then
                                ls ${arg1}bin/mysqld &> /dev/null
                                if [[ $? -ne 0 ]] ;then
                                        echo "It's not a mysql basedir!"
                                        break 1;
                                else
                                        sourcedir=${arg1}
                                        break 1;
                                fi
                        else
                                arg1=${arg1}/
                        fi
                done
        else
                echo "Need full path!"
				exit 1;
        fi
fi
#
#echo $sourcedir
# Give me a sign
echo -e "`date '+%h %d %H:%m:%S'` MySQL DIR Founded!\n"

# Step 2
# 检查依赖
ldd ${sourcedir}/bin/mysqld &>/dev/null
if [[ $? -ne 0 ]] ;then
	echo "Missing Library and Packages!"
	ldd ${sourcedir}/bin/mysqld
	exit 2;
fi
# Give me a sign
echo -e "`date '+%h %d %H:%m:%S'` MySQL Dependency Checked!\n"



# Step 3
# 判断是否有数据库使用了该端口号
ls /data/mysql/mysql${portnum} &> /dev/null
# 如果目录不存在，则进入判断
# make $datapath key
if [[ $? -ne 0 ]] ;then
	while :
	do
		# 判断端口是否非法
		if [[ "${portmun}" =~ ^[0-9]*$ ]] ;then
			if [[ "${portmun}" -gt "65535" ]] ;then		# 这块遇到了问题，如果再加上 "${portmun}" -lt 1，就会出现奇怪的事情。 
				echo "Wrong port! Between 1 and 65535!"
				read -p "Type port number (default 3306):" portnum
			else
				# Making directories
				# 此处未来可以针对端口号做更多合理的判断
				mkdir -p /data/mysql/mysql${portnum}/{data,logs,tmp}
				touch /data/mysql/mysql${portnum}/my${portnum}.cnf
				chown -R mysql:mysql /data/mysql/mysql${portnum}
				#chmod -R 700 /data/mysql/mysql${portnum}
				datapath=/data/mysql/mysql${portnum}
				break 3;
			fi
		else
		# 如果端口号非法，则退出。
			echo "Wrong port! Between 1 and 65535!"
			# 觉得直接重输入端口号更友好，但是整体上不合理。
			#read -p "Type port number (default 3306):" portnum
			exit 3;
		fi
	done
else
	# 如果目录已经存在，通过判断data是否为空来确认是空目录还是已经初始化。如果data非空则直接退出。
	datadircount=`ls /data/mysql/mysql${portnum}/data|wc -l`
	if [[ "${datadircount}" -ne 0 ]] ;then
		echo "port:${portnum} already initialized,this maybe rewrite the DB,please check again,now exit..."
		exit 3;
	fi
fi
# Give me a sign
echo -e "`date '+%h %d %H:%m:%S'` MySQL Port Avaliable!\n"
echo -e "`date '+%h %d %H:%m:%S'` MySQL Data DIR Created!\n"


# Step 4
# 获取mysqld的路径，如果不存在，则视为未配置的新机器，进行配置 
# make $basepath key
which mysqld &>/dev/null
if [ $? -ne 0 ] ;then
	ln -sf ${sourcedir}  /usr/local/mysql
	echo 'PATH=/usr/local/mysql/bin:$PATH' >> /etc/profile
	basepath=/usr/local/mysql
else
	# 如果已经机器已经配置了环境变量，则获取mysql base dir
	basepath=`which mysqld`
	basepath=${basepath%/*}	#cut last : .../mysqld
	basepath=${basepath%/*}	#cut last : .../bin
fi

source /etc/profile
# Give me a sign
echo -e "`date '+%h %d %H:%m:%S'` MySQL Base DIR Defined!\n"





# Step 5
# make my.cnf with current setting
ip4bit=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"|head -1|cut -d"." -f4`
mycnffile=${datapath}/my${portnum}.cnf

cat <<EOF > ${mycnffile} 
[client]
port            = v_port_num
socket          = v_datadir_path/tmp/mysql.sock                #	/tmp/mysql.sock
prompt="\\u@\\h [\\d]>"

[mysql]
## 8.0
auto-rehash
prompt="\\u@\\h [\\d]>"
#pager="less -i -n -S"
#tee=/opt/mysql/query.log

[mysqld]
####: for global
user                                =mysql             		#	mysql
basedir                             =v_basedir_path/    	#	/usr/local/mysql/
datadir                             =v_datadir_path/data    #	/usr/local/mysql/data01
server_id                           =v_ip_4bitv_port_num        		#	0
port                                =v_port_num        		#	3306
character_set_server                =utf8mb4           		#	latin1
explicit_defaults_for_timestamp     =on                		#    off
log_timestamps                      =system
default_time_zone		    ='+08:00'          				#	utc
socket                              =v_datadir_path/tmp/mysql.sock                #	/tmp/mysql.sock
read_only                           =1                             #   off		比较有用，防止主备时误操作。确定主库后手动解除，提升安全性。
super_read_only                     =1								# 同上
skip_name_resolve                   =off                             #   0
auto_increment_increment            =1                              #	1
auto_increment_offset               =1                              #	1
lower_case_table_names              =1                              #	0
secure_file_priv                    =v_datadir_path/tmp/                         #	null
open_files_limit                    =65536                          #   1024
max_connections                     =1000                           #   151
thread_cache_size                   =64                             #   9
table_open_cache                    =81920                          #   2000
table_definition_cache              =4096                           #   1400
table_open_cache_instances          =64                             #   16
max_prepared_stmt_count             =1048576                        #

#mysqlx
mysqlx_socket				=v_datadir_path/tmp/xplugin.sock
#mysqlx-port				=

####: for binlog
binlog_format                       =row                          #	row
log_bin                             =v_datadir_path/logs/mysql-bin                      #	off
binlog_rows_query_log_events        =on                             #	off
log_slave_updates                   =on                             #	off
#expire_logs_days                   =7                              #	0
binlog_expire_logs_seconds          =604800       # mysql5.7 需要注释
binlog_cache_size                   =65536                          #	65536(64k)
#binlog_checksum                    =none                           #	CRC32
sync_binlog                         =1                              #	1
slave-preserve-commit-order         =ON                             #

####: for error-log
log_error                           =v_datadir_path/logs/error.log                        #	/usr/local/mysql/data01/localhost.localdomain.err

general_log                         =off                            #   off
general_log_file                    =v_datadir_path/logs/general.log                    #   hostname.log

####: for slow query log
slow_query_log                      =on                             #    off
slow_query_log_file                 =v_datadir_path/logs/slow_query.log                       #    hostname.log
log_queries_not_using_indexes       =on                             #    off
long_query_time                     =1.000000                       #    10.000000

####: for gtid
#gtid_executed_compression_period   =1000                          #	1000
gtid_mode                           =on                            #	off
enforce_gtid_consistency            =on                            #	off


####: for replication
skip_slave_start                     =1                              #
master_info_repository               =table                         #	file
relay_log_info_repository            =table                         #	file
slave_parallel_type                  =logical_clock                 #    database | LOGICAL_CLOCK
slave_parallel_workers               =4                             #    0
#rpl_semi_sync_master_enabled        =1                             #    0
#rpl_semi_sync_slave_enabled         =1                             #    0
#rpl_semi_sync_master_timeout        =1000                          #    1000(1 second)
#plugin_load_add                     =semisync_master.so            #
#plugin_load_add                     =semisync_slave.so             #
binlog_group_commit_sync_delay       =100                           #    500(0.05%秒)、默认值0
binlog_group_commit_sync_no_delay_count = 10                       #    0

####: for MGR
#MGR
#transaction_write_set_extraction=XXHASH64
#loose-group_replication_group_name="6e84d643-a0be-4e66-826e-96465d3d6397"  #must be use UUID format
#loose-group_replication_start_on_boot=off
#loose-group_replication_local_address="192.168.188.81:13306"
#loose-group_replication_group_seeds="192.168.188.81:13306,192.168.188.81:13307,192.168.188.81:13308,192.168.188.81:13309"
#loose-group_replication_bootstrap_group=off
#binlog_transaction_dependency_tracking= WRITESET
#
##MGR multi master
##loose-group_replication_single_primary_mode=off
##loose-group_replication_enforce_update_everywhere_checks=on
#

####: for innodb
innodb_data_file_path                           =ibdata1:100M:autoextend    #	ibdata1:12M:autoextend
innodb_temp_data_file_path                      =ibtmp1:12M:autoextend      #	ibtmp1:12M:autoextend
innodb_buffer_pool_filename                     =ib_buffer_pool             #	ib_buffer_pool
innodb_log_files_in_group                       =3                          #	2
innodb_log_file_size                            =100M                       #	50331648(48M)
innodb_file_per_table                           =on                         #	on
innodb_online_alter_log_max_size                =128M                       #   134217728(128M)
innodb_open_files                               =65535                      #   2000
innodb_page_size                                =16k                        #	16384(16k)
innodb_thread_concurrency                       =0                          #	0
innodb_read_io_threads                          =4                          #	4
innodb_write_io_threads                         =4                          #	4
innodb_purge_threads                            =4                          #	4(垃圾回收)
innodb_page_cleaners                            =4                          #   4(刷新lru脏页)
innodb_print_all_deadlocks                      =on                         #	off
innodb_deadlock_detect                          =on                         #	on
innodb_lock_wait_timeout                        =20                         #	50
innodb_spin_wait_delay                          =128                          #	6
innodb_autoinc_lock_mode                        =2                          #	1
innodb_io_capacity                              =200                        #   200
innodb_io_capacity_max                          =2000                       #   2000
#--------Persistent Optimizer Statistics
innodb_stats_auto_recalc                        =on                         #   on
innodb_stats_persistent                         =on                         #	on
innodb_stats_persistent_sample_pages            =20                         #	20

innodb_change_buffer_max_size                   =25                         #	25
innodb_flush_neighbors                          =1                          #	1
#innodb_flush_method                             =                           #
innodb_doublewrite                              =on                         #	on
innodb_log_buffer_size                          =128M                        #	16777216(16M)
innodb_flush_log_at_timeout                     =1                          #	1
innodb_flush_log_at_trx_commit                  =1                          #	1
innodb_buffer_pool_size                         =100M                  #	134217728(128M)
innodb_buffer_pool_instances                    =4
#--------innodb scan resistant
innodb_old_blocks_pct                           =37                         #    37
innodb_old_blocks_time                          =1000                       #    1000
#--------innodb read ahead
innodb_read_ahead_threshold                     =56                         #    56 (0..64)
innodb_random_read_ahead                        =OFF                        #    OFF
#--------innodb buffer pool state
innodb_buffer_pool_dump_pct                     =25                         #    25
innodb_buffer_pool_dump_at_shutdown             =ON                         #    ON
innodb_buffer_pool_load_at_startup              =ON                         #    ON
innodb_flush_method								=O_DIRECT
EOF

sed -i "s@v_basedir_path@${basepath}@g" ${mycnffile} 
sed -i "s@v_datadir_path@${datapath}@g" ${mycnffile} 
sed -i "s@v_port_num@${portnum}@g" ${mycnffile} 
sed -i "s@v_ip_4bit@${ip4bit}@g" ${mycnffile} 
# Give me a sign
echo -e "`date '+%h %d %H:%m:%S'` MySQL Configured!\n"

# Step 6
# initialize current database instance
#--initialize
#--initialize-insecure
mysqld --defaults-file=${mycnffile} --initialize-insecure
# Give me a sign
echo -e "`date '+%h %d %H:%m:%S'` MySQL Initialized! Lookup the password!!!!"

# print password of root
grep password ${datapath}/logs/error.log 
# Step 7
# startup database instance
mysqld --defaults-file=${mycnffile} &
# Give me a sign
echo  "`date '+%h %d %H:%m:%S'` MySQL ${portnum} Instance Now Running!"

# Step 8
# unlock privilege and etc.
# 后续再完善。


# Step 9
# make service to init.d
# 后续再完善。

# others
# version less than 5.7 
# # delete from mysql.user where user != 'root' or host != 'localhost';
# # truncate mysql.db;
# # drop database test;
