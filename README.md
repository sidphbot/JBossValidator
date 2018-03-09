# JBossValidator
one click validation for all standalone JBoss instances running on a server

JBoss validator : 

Utility : jboss_status.sh

User : root

Features : 
•	Detects all running jboss standalone instances
•	PID and port information for all instances
•	Netstat listening signature for all instances
•	Webpage browsability through curl for all instances
•	The file descriptor Usage for all instances
•	Checks if the jboss process is hung or not (cli connectivity) for all instances
•	Current Heap Usage Report for all instances
•	Current thread count for all instances

Conditions : the cli ports should not be manually changed, however port-offsets will be automatically recognized

Usage:
$ ./jboss_status.sh

e.g.
[root@[host] user1]# ./jboss_status.sh

