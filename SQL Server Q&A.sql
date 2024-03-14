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

