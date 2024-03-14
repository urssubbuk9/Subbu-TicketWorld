1) can we have AD group for job owner?   
ANS: NO

2) What does checkdb with estimateonly will give us?
ANS: checkdb with estimateonly will give only how much space it would require in temp db for the user database

3)When we need to keep DB in emergency mode? Do we need to do this for all DB corruptions?
ANS: We need to this when the DB is not accesible (Say like Suspect)

4)if the corruption happened and you ran repair allow data loss how will ensure that there is no loss inside your database?
ANS: Once we perform repair allow data loss we need to check at least the row count as there are chances for the rows to get deleted. 
Hence taking a copy of row count for all the tables will help us to verify which table got affected.

5)Can we have DB owner as AD group?
ANS: NO

6)Will sp_change_users_login report gives back orphan users at windows level?
ANS: NO only SQL logins. We should use sp_validatelogins to find windows orphan users

7)how will you change the password for the distributor admin in replication?
ANS: using sp_changedistributor_password  we can change and restart the distruber agent and moniter the replication monitor.

8) what happens if we disable the clustered index?
ANS: It won't allow you to run DML opeartions

9)Can we consider Log shipping as reporting solution?
ANS: If you reporting queries are acceptable for delays

10) In transactional replication will we get non clustered indexes by default to Subscribers?
ANS: NO, by default. But we can create separate index for reporting queries
  
==========================================================================================================================================  
  
1)How to find out when checkdb was last run?
ANS: Dbcc dbinfo with table results

2) What's the difference between Covering index and included columns?
ANS: Covering index will cover all the columns which are used in the query and the data is present in the root,intermediate,leaf level
where as with included columns what are the columns which we mentioned with included are only present in the leaf level of that non clustered index

3)what are incremental statistics?
ANS: When incremental statistics is enabled then SQL Server tracks changes to the data and only updates the impacted statistics subsets instead of rebuilding the full statistics.

4) what are the 3 modes inside sys.dm_db_index_physical_stats  and can you run them during business hours for very large tables?
ANS: we are having 3 modes
  sampled: which is default one
  detailed mode 
  limted mode.
we can run in the production since sample is default beacuse it will anaylse the sample the index depth but may not accurate
detailed more we cant run the prodcution hours on larger tables.
limited mode... we can run but not accurate ... 

Again its all depends on your environment and client. 

limited -->super super fast  -->Not accurate -->
Sample -->fast --> near to accurate but not
Detailed -->slow -->accurate

5)How will you track the percentage completion of index creation?
ANS:  Set statistics profile on

6) What is the difference between Availability Groups and Distributed Availability Groups?
ANS:  DAG operates on 2 different windows clusters and even if windows OS is different
      AG operates on same cluster and usually OS should be same (unless in case of Migration)

7) when will you get Compute scalar operator inside Execution Plans?
ANS: This is one of the example the best one is when we convert the data or usage of functions to RHS of Equality operator with the where clause predicate
      We have two columns and we need a thrid columns by combiming by two columns
          month salary , pF total salary 
          1000000       10000   Select (month salary + PF)
8) What is cost threshold for parallelism and the things that prevent SQL to make use of Parallelism?
ANS: when query subtree cost is more than cost threshild for parallelism then the query utlizie the maxdop.  There is a session in our recordings which helps to understand the reasons that prevent Parallelism

9)How do you know whether the stats were run  with Full scan or sampling?
ANS: we can use dbcc show statistics(index name) here inside the stats header if we notice rows and rows sampled are same then we can say it happened with full. 

10)How will you Synchronize the objects in Always ON that are outside the scope of the database?
ANS:  we can use dba tools. or from 2022 we can use contained availibity group features

==========================================================================================================================================  

1) what's your understanding with Dbcc checkdb messages that gets logged inside the error logs?
 ANS:  When we restart the instance or server inside error logs we will find checkdb messages. It doesn't mean that checkdb has run it just reports the last run date.

2) On Managed instance how many tempdb files would get created?
ANS:  By default, Azure SQL Managed Instance creates 12 tempdb data files, and 1 tempdb log file, but it's possible to modify this configuration.

3) Do we need to create High Availability for Managed instance? If so how?
ANS:  By Default MI has HA configured. For example if we take BC we will get 3 replicas leaving out primary and you can use 1 for reporting using Application Intent=readonly hint

4) What's the difference between General Purpose and Business Critical Architectures?
ANS:  GP has remote storage for data files and the architecture is similar to Failover cluster and BC has local storage for data files and it has 4 replicas(In built always on)

5) What are different ways to connect to Azure Managed instance?
ANS:  Public Endpoint, Vnet Endpoint and Private Endpoint

6) Have you ever made use of partitioned views in SQL Server?
ANS:  I am planning to take Deep Dive session on Partitioning.

7)How will you adjust the memory when we have multiple instances in case of stand alone and clustered environments?
ANS:  I explained this in the class 38

8) What's your take if total server memory is greater than target server memory?
ANS:  Total Server Memory= The memory that SQL Server is currently utilizing
           taget server memory= The value what we configure inside Max memory

If total < target it means the instance would have been restarted. If we see the memory usage is still less despite being restarted after many days it means you over allocated
the max server memory.  In general total will be equal to target but in case if it is more then it's a sign to see if there is memory pressure. 

9) What are few reasons that you think of for Always On Connection time outs?
ANS:  We can think of Vm Snapshots which are usually the culprits and there are chances of anti Virus and sometimes blocking on secondary due to redo thread

10)I need to make a change for one of the columns from int to bigint it is of 1 TB how can you do this operation in seconds?
ANS:  We need to enable compression on the table (no matter if it is Row or page) then we need to enable compression for all NCI as well. 
      If you do this then this will happen as metadata operation. Usually it takes several hours but if we make this it takes a second for its completion

========================================================================================================================================== 

1) If you are making use of Azure VM's what are the settings that you need to keep for Host caching with respect to data and log files?
Ans: For Data File drives it should be read-only and for log files  drive it should be none.  We will never use Read/Write settings

2)If you’re on-premises source version is anything less than 2016 and your target is PAAS(Azure Managed instance) and you need to move more than 50 databases with minimal
downtime what technology will you make use of?
Ans: The best way is to Automate and it can be done using Log Replay Service Mechanism

3) If you’re on-premises source version is 2016/2019 and your target is PAAS (Azure Managed instance) and the downtime is less than 5 minutes what technology will you
make use of?
Ans: Azure Managed Instance link is a feature which creates Distributed availability group internally between our on-premises Database to Azure Managed instance. We don't need to have Always ON with our on-premises setup.

4)How will you access the data from one Azure SQL DB to another DB?
Ans: Unlike on-prem or IAAS or AZure MI we can't access one DB from another DB on Azure SQL. We need to make use of External tables.

5)What's the difference between Bacpac and Dacpac?
Ans: Bacpac -> Schema +data . Dacpac->only Schema

6)How will Sargable expressions contribute to High CPU usage?
Ans: They negate the performance as they will not make use of the index which  leads index scan and there by increasing CPU.

7) How will you find out if sqlservr.exe is the real contributor for high CPU usage if it happened in the past?
Ans: For every 1 min inside Ring buffers we will get the usage of SQL Server and it stores 4 hours of CPU inofrmation. This can be used incase if you are not running perfmon counters.
The best way is to with perfmon counters.

8)How will you find out Always on Failover History?
Ans:  This gets recorded inside Always ON Extended event health session. We need to write bit of tsql script to extract the events based on event ID 1480

9)Will there be any default statistics on Secondary replicas? if so when would they get created and where will they be stored as the DB is read-only on secondary side?
Ans: They will get created on TempdB 

10) Will there be any overhead on tempdb if we turn on readable secondaries?
Ans: yes there will be 14 byte Overhead for any DML operations as a result this will cause Row versioning inside TEMPDB.

========================================================================================================================================== 

1) which File group is the Database Log file created in?
Ans: Log files will not have any FG

2)s it a good idea to keep "auto update statistics" enabled in Sql Server? Why?  HOW?
Ans: In General yes....however for any important tables( of huge sizes) that business needs it's sometimes advisable to
turn them off as if they get triggerred there are chances of performance degradation as stats updates consume lots of resources.

3)Is disabling " parameter sniffing" a good performance tuning practice?
Ans: No it is not....As every time the Execution plan gets the estimates from Density vector which is not ideal
for usual workloads.

4)I have a 2 node Alwayson setup. I received a request to create a login and grant permission on a
database which is part of that alwayson setup. Should i create "LOGIN" on both nodes or only primary
node?
Ans : It's Okay to create on only one node and you can use DBA tools to sync that up. If it is manual then we need to create on both and if it is SQL login then we need to ensure SID's are same.

5)Can we create statistics under database tables or only the SQL server can do that?
Ans: We have 2 types index stats and columns stats which gets created automatically by SQL. If we need 
manual stats it can be done as well however it is very rare though.

6)What is the default value of the connection_timeout property of an "Availability Group" in SQL Server
Alwayson Availability Group configuration?
Ans 10 seconds

7)Should i create user on both nodes or only on primary node in Always ON?
Ans: on Primary it is enough as the users would get transferred automatically

8)Should i also grant permission on both nodes or just primary node?
Ans: on primary it is enough

9) is it possible to get the actual execution plan from the cache?
Ans: Yes from 2019 by setting the option turned on at DB level

10)what is subtree cost inside the execution plan?
Ans: it's the total cost of all the operators inside execution plan.

========================================================================================================================================== 

1) Is it Possible in Always ON to have Full backups to run on primary replica and log backups on secondary replica?
Ans:  We can use sys.fn_hadr_is_primary_replica and if it returns primary then do full backups else do log backups. On secondary replicas that function will give you the result as 0 

2) We know that Differential's are not possible on Secondary replicas....So In case if I wanted to restore DB can I use copy-only full backup then Differential and then log backup?
Ans: We can't restore differentials on top of copy only full backups. Only Normal full backups are allowed

3) What do you understand with the term forwarded fetches? Will it happen for all the tables?
Ans: A forwarded record occurs when a row within a heap, has been moved from its original page to a new page. This leaves behind a forwarding pointer at the original location those points to the new page. This happens only with heap tables

4) How will you transfer the logins from on-premises to Azure SQL?
Ans: It's not possible using any of the existing mechanisms. It is recommended to create logins with new password.

5) How will you identify forwarded fetches across all the databases and how to avoid them?
Ans: There are few ways but the simplest being sp_blitizndex @getalldatabases=1. Either we need to create clustered index or perform rebuild using alter table <tablename> rebuild

6) Can we make use of sp_help_revlogin to transfer logins from on-premises to Azure Managed Instance?
Ans: Yes we can and it's recommended to use Azure DMS

7) Say if we migrate a DB from on-premises to Azure MI and the performance has been degraded what are the things that you cross check?
Ans:1) Azure Managed instance supports only full recovery models where as in on-premises we can have our databases in simple and Bulk logged which means we got an option for Minimally logged operations.
2) All the databases are part of TDE automatically which is not the case for on-premises
3) The general purpose tier uses remote storage that can't match your on-premises environment if it uses local SSD or a high-performance SAN. In this case you would need to use the business critical tier as a target.
4) Check for DB Engine settings like compatibility levels, trace flags, system configurations (‘cost threshold for parallelism’, ’max degree of parallelism’), database scoped configurations (LEGACY_CARDINALITY_ESTIMATOR, PARAMETER_SNIFFING, QUERY_OPTIMIZER_HOTFIXES, etc.), and database settings (AUTO_UPDATE_STATISTICS, DELAYED_DURABILITY)
5) Remember that log Backup happens for every 5 or 10 minutes automatically on MI which might not be the case in your on-premises.
6) SQL Database managed instance enforces SSL/TLS transport encryption which is always enabled. Encryption can introduce overhead in case of a large number of queries. If your on-premises environment does not enforce SSL encryption you will see additional network overhead in the SQL Database managed instance.

8) Why we don't see any IP's for Always on Listener Names in case of DNN?
Ans: It works on the concept of DNS hence the replica IP's itself will act as Listener IP's.

9) Do we need to enable trace flags 1117 and 1118 on tempdb?
Ans: We don't need these flags from SQL server 2016
-T1117 - When growing a data file grow all files at the same time so they remain the same size, reducing allocation contention points.
-T1118 - When doing allocations for user tables always allocate full extents.  Reducing contention of mixed extent allocations

10) How many rows would SQL Server estimates if you use table variables?
Ans:  It always estimates only one row until SQL Server 2017 which used to cause performance issues. From 2019 due to deferred compilation now we get better estimates.

========================================================================================================================================== 

1) What are the advantages of DAG over traditional AG?
Ans: We don't need to have same Windows cluster and same Operating systems when building the cluster. In fact we can configure DAG even on cluster less Environments as well. Also we have the concept of forwarder hence the primary replica need not send the log records to all the secondaries. It needs to send that only to the replicas in the primary DC and to the primary replica in another DC.

2) How many rows SQL Server DB engine would estimate if you use multi statement table valued functions?
Ans: Until 2012 it was 1 row and from 2014 to 2016 it was 100 rows and from 2017 due to concept of intelligent query processing we will get the correct estimates.

3) What is the difference between object allocation contention and Metadata contention in tempdb?

TempDB metadata contention occurs when many sessions try to access the SQL Server TempDB’s system tables at the same time during the creation of the temp tables. (This mainly occurs within Memory-->Buffer).
you are more likely to see the contention occurring on index and data pages and the page number in the wait resource will be a higher value such as 2:1:111, 2:1:118, or 2:1:122

if you see a lot of PAGELATCH waits on page resources 2:X:1 (PFS), 2:X:2 (GAM), 2:X:3 (SGAM), or 2:X:<some multiple of 8088> (also PFS) where X is a file number. Then it is Object allocation contention. It is mainly related to I/O.
During object creation, two (2) pages must be allocated from a mixed extent and assigned to the new object. One page is for the Index Allocation Map (IAM), and the second is for the first page for the object.
To allocate a page from the mixed extent, SQL Server must scan the Page Free Space (PFS) page to determine which mixed page is free to be allocated.When SQL Server searches for a mixed page to allocate, it always starts the scan on the same file and SGAM page.

4) What port needs to be enabled for to connect to MI using Public End Point?
Ans 3343

5) Do we have virtual Network for Azure SQL?
Ans: There is no dedicated VNET like Azure VM's or Managed instance. We need to make use of Private End point or else you should use service end points from the virtual networks.

6) How much Ram will we get inside Azure Managed Instance?
Ans: As we don't have OS we don't have an option to choose the amount of memory we need. It depends on the Vcore.
For standard series one Vcore is 5.1 GB RAM, premium series one Vcore is 7 GB Ram and finally premium series memory optimized one Vcore is 13.6 GB of RAM

7) When we make use of Azure Managed instance link feature for Migration from on-premises to MI do we need to have Always ON enabled in On-premises?
Ans: NO.....We can do this even on standalone machines as it creates DAG between on-premises and MI

8) How will you achieve the requirement where at the migration from on-premises to Azure managed instance and need to have reporting solution on MI before the cutover?
Ans: We can make use of Azure Managed instance link feature as it establishes DAG behind the scenes you can read that on MI even at the restoration.

9) What are the max no of steps that would get created in Histogram and will it create it on all the columns of the index?
Ans: The max no of steps are 201 and the histogram would get created only on the leading column of the index

10) What are different ways to connect 2 different networks on Azure?
Ans: Peering and Vnet Gateways

========================================================================================================================================== 

1) Can we configure publisher in on-premises and Distributor in Azure Managed Instance and subscriber on Azure SQL?
Ans: No it is not possible as MI needs publisher and distributor to be either local or remote. It's not possible to blend

2)when creating the Always On (not DAG) do we need to have same operating system provided I am not carrying any Migration?
Ans: For DAG we can have different OS as part of windows cluster however for traditional AG we should have same OS.

3) What is the default isolation level for databases on Secondary replicas?
Ans: Snapshot Isolation level

4) if we use Variables inside the stored procedures or in case of adhoc queries from where SQL Server would get the estimates from?
Ans: If we use variables SQL Server estimates always comes from Density Vector.

5)Whats the difference between proxy and redirect connection policy?
Ans: For the initial connection both proxy and redirect hits the Gateway and it transfer the requests to the node. However, in case of redirect once the initial connection gets established then it communicates directly and it doesn't need Gateway any more.MS recommends to make use of redirect especially for chatty Applications as clients establish connections directly to the node hosting the database, leading to reduced latency and improved throughput.

6)What ports need to be enabled for the redirect connection policy to work?
Ans: 11000-11999

7)What are some of the log files that we need to verify in case if Always ON databases are not in sync or replicas out of sync?
Ans: 
(i)Cluster logs
(ii)SQL Server Error logs
(iii)Always on Extended Health Event sessions
(iv)System Health Extended event sessions
(v)SQL DIAG extended event files

8) what are different ways to overcome the performance issues with Scalar UDF?
Ans 
(i) Avoid using functions and expanding the code
(ii) By using Schemabinding
(iii)By using NULL on NULL input
(iv)by making it memory optimized (native _compilation)
(v)by making it inline

9) Is it possible to create an Alias for Managed instance?
Ans: Yes, we can and it can be something like <dnsaliasname>.<domainname.com> instead of MIname. database.windows.net

10)What are the different types of replication that is supported with Azure Managed instance?
Ans: It supports only Snapshot, uni and bi directional transactional replication.

==========================================================================================================================================

1) How will you Migrate a DB from standalone instance which is on 2017 instance with 4 TB to 2019 instance in less than 1 minute of downtime?

Ans: Firstly DAG was introduced from SQL 2016 and on 2016 we need the databases to be part of Always ON. 
However from SQL Server 2017 even for standalone machines we can configure DAG. You don't need to configure even windows failover cluster for this and also no need for availability group listener. As we are using DAG it transfers the log records instantly and once we are ready with the cutover it is an instant flip.

2) Can we configure Log shipping to/from Azure Managed instance?

Ans: We can't configure traditional log shipping....You may ask why because we need to place the backups on to storage container so we should use backups to URL and while restoring 
RESTORE ... FROM URL will implicitly add WITH RECOVERY and so there will be no opportunity for logs to be applied after the initial restore. 
The only option is to use Log replay Service.

3) Is it possible to configure the replication where publisher is on 2019 instance and distributor on SQL 2017 and subscriber on 2022 instance?

Ans: No it's not possible to configure. Because a publisher server version can't be greater than to that of Distributor. 
Always remember our publisher server version should be <=Distributor server version.

4) How will you get to know if the latency in replication is happening from Publisher to Distributor or from Distributor to Subscriber?

Ans: By Inserting tracker tokens we can figure out where the latency is as in transactional replication apart from the snapshot agent which is used for initial sync. The other 2 agents Log reader and distributor agent will run continuoulsy (can be tweaked based on our requirements) and we need to see where the lag is. We need to figure out whether the problem is from Log reader agent to Distributor or from Distributor to Subscriber.

5)If you got to know that replication lag is happening from publisher to Distributor what will be your steps to overcome that?

Ans: Well internally there are 4 threads that runs when we configure replication.

Log Reader Agent Reader Thread – It scans the publisher database transaction log using sp_replcmds

Log Reader Agent writer Thread -Add the queued transactions to the Distribution database using sp_MSadd_repl_commands

Distribution Agent Reader Thread – It finds the watermark from the table Msreplication_subscriptions(on subscriber) and uses this information to retrieve pending commands from the Distribution database. It basically uses the stored procedure sp_MSget_replcommands to achieve it.

Distribution Agent Writer Thread – Writer thread uses the Batched RPC calls to write the information to subscriber database.

when we have Log Reader Reader-Thread Latency then the possibe causes are: High VLFS, Slow Network I/O, Slow Read I/O and large batch of replicated transaction.
when we have Log Reader Writer-Thread Latency then the possibe causes are: Blocking,  High I/O, Slow Write I/O and Slow Network I/O.


6) is it possible to Configure DAG on top of Always On configured with DNN?
Ans: for the moment it is not possible to configure DAG on top of Always configured with Distributed Network Name

7)suppose I have 3 nodes using Node Majority configuration and because of some unforeseen issues say 2 nodes went down at the same time then what will happen to our Always ON Databases?

Ans: Microsoft has done various enhancements to the quorum right from windows 2003. With windows 2012 we have the concept of  Dynamic quorum and with 2012 R2 we have Dynamic witness. However all of these works only if the servers are turned off using graceful approach. if it is ungraceful shutdown like what we have in the question then to prevent the split Brain situtation the windows cluster would shutdown itself. To resolve this we need to make use of Force quorum.Below are the steps for single site or Multi site 

(i) Log in to the only node that is up and running and then shutdown the cluster service -->Net stop clussvc
(ii) Bring up cluster service with Forcequorum-->Net start clussvc /forcequorum
(iii) Failover AG to the node which is up now (as other 2 nodes are down) with Allow Data Loss-->ALTER AVAILABILITY GROUP AGTest FORCE_FAILOVER_ALLOW_DATA_LOSS;
(iv) This will bring AG up and once the other 2 servers are backup you need to resume the data movement-->ALTER DATABASE [AGplaceHolder] SET HADR RESUME;

Note: Most importantly, be aware that log truncation will be delayed on a given primary database while any of its secondary databases is suspended. Therefore, if the outage period is prolonged, consider removing the failed replica from the AG to avoid running out of disk space due to log truncation delay.

8) Say we have sensitive information in one of the columns and you encrypted that column then can I restore this DB with out exporting Private Keys?

Ans: Many people are getting confused between TDE and column level encryption....in case of TDE we have the concept of private keys but in case of column level that is not so we can backup the database and restore it happily. The problem comes only if you don't know the password for DMK and if the clients are accessing the table that contains column level encryption.

9) Can we create multiple passwords for Database master key?

Ans:  yes we can create multiple passwords unlike SMK where it is not possible.

10)Can we configure  automatic seeding when we opt DAG?

Ans: Distributed availability groups were designed with automatic seeding to be the main method used to initialize the primary replica on the second availability group. 
For simplicity, the target SQL Server instance should match the version of the source SQL Server instance. If you choose to upgrade during the migration process by using a higher version of SQL Server on the target, then you will need to manually seed your database rather than relying on autoseeding

==========================================================================================================================================

1) What is persisted Version store in SQL?

Ans: The persistent_version_store table is maintained by the Accelerated Database Recovery option. It is a persistent store of database changes over time.
This feature (ADR) has been introduced from SQL 2019 .This ensures that the recovery time remains unaffected by long running transactions, regardless of the number or size of active transactions. ADR is particularly recommended for workloads that have experienced significant growth of the transaction log due to active transactions.

2) Why a query would use a SORT Operator in our execution plans?

Ans:

ORDER BY 

GROUP BY  may introduce a sort operator in a query plan prior to grouping if an underlying index isn't present that orders the grouped columns.

DISTINCT  behaves similarly to GROUP BY. To identify distinct rows, the intermediate results are ordered, and then duplicates are removed. The optimizer uses a Sort operator prior to this operator if the data isn't already sorted due to an ordered index seek or scan.

The Merge Join operator, when selected by the query optimizer, requires that both joined inputs are sorted. SQL Server may trigger a sort if a clustered index isn't available on the join column in one of the tables.

3) Why a query would use a HASH query Plan operator in our execution plans?

Ans:

JOIN : When joining tables, SQL Server has a choice between three physical operators, Nested Loop, Merge Join, and Hash Join. If SQL Server ends up choosing a Hash Join, it needs QE memory for intermediate results to be stored and processed. Typically, a lack of good indexes may lead to this most resource-expensive join operator, Hash Join. 

DISTINCT : A Hash Aggregate operator could be used to eliminate duplicates in a rowset. 

UNION : This is similar to DISTINCT. A Hash Aggregate could be used to remove the duplicates for this operator.

SUM/AVG/MAX/MIN : Any aggregate operation could potentially be performed as a Hash Aggregate. 

4) will there be any performance impact if I am comparing nvarchar with Varchar and what will happen with the other way around?

Ans: There will be no performance impact if we are doing any comparision with nvarchar to varchar however not the other way as every field needs to be converted this causes implicit conversion and results in High CPU usage. Also there are chances for us to witness SOS Scheduler Yield waits.

5) Say I have thousands of databases and don't want to manually turn on LEGACY_CARDINALITY_ESTIMATION for each. Is there an alternative method?

Ans: For SQL Server 2014, we need to enable trace flag 9481 to use the legacy CE for all databases irrespective of the compatibility level. For SQL Server 2016 and later versions, execute the following query to iterate through databases. 

SELECT [name], 0 AS [isdone]
INTO #tmpDatabases
FROM master.sys.databases WITH (NOLOCK)
WHERE database_id > 4 AND source_database_id IS NULL AND is_read_only = 0

DECLARE @dbname sysname, @sqlcmd NVARCHAR(500);

WHILE (SELECT COUNT([name]) FROM #tmpDatabases WHERE isdone = 0) > 0
BEGIN
    SELECT TOP 1 @dbname = [name] FROM #tmpDatabases WHERE isdone = 0

    SET @sqlcmd = 'USE ' + QUOTENAME(@dbname) + '; 
        IF (SELECT [value] FROM sys.database_scoped_configurations WHERE [name] = ''LEGACY_CARDINALITY_ESTIMATION'') = 0
        ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = ON;'
 
    BEGIN TRY
        EXECUTE sp_executesql @sqlcmd
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity,
            ERROR_STATE() AS ErrorState, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH

    UPDATE #tmpDatabases
    SET isdone = 1
    WHERE [name] = @dbname
END;

6) What is lock escalation and how will you overcome that?

Ans: Lock escalation is the process of converting many fine-grained locks (such as row or page locks) to table locks. Microsoft SQL Server dynamically determines when to do lock escalation. Note: There is no conversion from Row->page it happens directly from row->table or page->table

To prevent that 

(i)Break up large batch operations into several smaller operations. 

say instead of running like this DELETE FROM LogMessages WHERE LogDate < '20020102'; use the below method 
DECLARE @done bit = 0;
WHILE (@done = 0)
BEGIN
    DELETE TOP(1000) FROM LogMessages WHERE LogDate < '20020102';
    IF @@rowcount < 1000 SET @done = 1;
END;

(ii) Eliminate lock escalation caused by lack of SARGability This may occur if there's a function or computation in the left side of a WHERE clause. 

(iii)Reduce the query's lock footprint by making the query as efficient as possible. Large scans or many bookmark lookups can increase the chance of lock escalation. Additionally, these increase the chance of deadlocks, and adversely affect concurrency and performance.  We need to create new indexes or to add columns to an existing index to remove index or table scans and to maximize the efficiency of index seeks.

7) How will you troubleshoot HADR SYNC commit wait types?

Ans: HADR_SYNC_COMMIT indicates the time between when a transaction ready to commit in the primary replica, and all secondary synchronous-commit replicas have acknowledged the hardening of the transaction commit LSN in an AG. It means a transaction in the primary replica cannot be committed, until the primary replica received greater hardened LSNs from all secondary synchronous-commit replicas.

It could be because of slow I/O, High CPU or Network issues.

8) In case of SQL Server Failover clustered instance do we need storage when you configure MSDTC?
Ans: Yes, we need Storage and IP Address...But in general even if we don't configure MSDTC as a separate resource SQL can leverage local MSDTC on the node.

9)What is the concept of last man standing in SQL Server when we configure Clusters( SQL FCI or AG)?

Ans: The quorum configuration in a failover cluster determines the number of failures that the cluster can sustain while still remaining online.  If an additional failure occurs beyond this threshold, the cluster will stop running.

quorum is design to handle the scenario when there is a problem with communication between sets of cluster nodes, so that two servers do not try to simultaneously host a resource group and write to the same disk at the same time.  This is known as a “split brain” and we want to prevent this to avoid any potential corruption to a disk my having two simultaneous group owners.

The total number of votes required for a quorum is now determined based on the number of nodes available. Therefore, with a dynamic quorum, the cluster will stay up even if you lose less than majority of the nodes. This situation is called as last-man-standing in which cluster works with a single node as well.

10) What are narrow and wide plans in SQL Server?
Ans: 

When you execute an UPDATE statement against a clustered index column, SQL Server updates not only the clustered index itself but also all the non-clustered indexes because the non-clustered indexes contain the cluster index key.

SQL Server has two options to do the update:

Narrow plan: Do the non-clustered index update along with the clustered index key update. This straightforward approach is easy to understand; update the clustered index and then update all non-clustered indexes at the same time. SQL Server will update one row and move to the next until all are complete. This approach is called a narrow plan update or a Per-Row update. However, this operation is relatively expensive because the order of non-clustered index data that will be updated may not be in the order of clustered index data. If many index pages are involved in the update, when the data is on disk, a large number of random I/O requests may occur.

Wide plan: To optimize performance and reduce random I/O, SQL Server may choose a wide plan. It doesn't do the non-clustered indexes update along with the clustered index update together. Instead, it sorts all non-clustered index data in memory first and then updates all indexes in that order. This approach is called a wide plan (also called a Per-Index update).
