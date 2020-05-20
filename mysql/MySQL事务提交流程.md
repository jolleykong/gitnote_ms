有binlog的CR方式（重点核心！！）：
有binlog情况下，commit动作开始时，会有一个Redo XID 的动作记录写到redo，然后写data到binlog，binlog写成功后，会将binlog的filename，日志写的位置position再写到redo(position也会写到pos文件里)，此时才表示该事务完成（committed）。如果只有XID，没有后面的filename和position，则表示事务为prepare状态。

流程：
      commit; --> write XID to redo. --> write data to Binlog. --> write filename,postsion of binlog to redo. --> commited.
　　记录Binlog是在InnoDB引擎Prepare（即Redo Log写入磁盘）之后，这点至关重要。

 ![title](https://raw.githubusercontent.com/jolleykong/img_host/master/imghost/2020/05/03/1588514376896-1588514376898.png)



如果事务在不同阶段崩溃,recovery时会发——

|crash发生阶段|事务状态|事务结果|
|-|-|-|
|当事务在prepare阶段crash|该事务未写入Binary log，引擎层也未写redo到磁盘。|该事务rollback。|
|当事务在binlog写阶段crash|此时引擎层redo已经写盘，但Binlog日志还没有成功写入到磁盘中。|该事务rollback。|
|当事务在binlog日志写磁盘后crash，但是引擎层没有来得及commit|此时引擎层redo已经写盘，server层binlog已经写盘，但redo中事务状态未正确结束。|读出binlog中的xid，并通知引擎层提交这些XID的事务。引擎提交这些后，会回滚其他的事务，使引擎层redo和binlog日志在事务上始终保持一致。事务通过recovery自动完成提交。|

 

 

总结起来说就是如果一个事务在prepare阶段中落盘成功，并在MySQL Server层中的binlog也写入成功，那这个事务必定commit成功。

**（redolog 写成功 && binlog 写成功 == commit，缺一不可。）**