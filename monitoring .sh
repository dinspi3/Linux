


#!/bin/bash

#Author:Alex Spivak
#Modify : 10/03/2020
#Copy script to the server
#chmod +x loading_proccess.sh
#dos2unix loading_proccess.sh
#Description :This script is monitoring clearsee backend  process .

PS3='Please enter your choice: '
options=( "Last Version" "Total NO Tables" "License" "cs_admin status" "Files Status" "Failed jobs status" "Failed scheduled task" "Failed Ri jobs" "DWH primary" "CONV last loading" "Cluster status" "MSTR status" "Disk Space Usage" "Backlog 7 day" "Tomcat Status" "Refresh Cubes" "Postgres" "Vertica" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Last Version")
		echo "==========Last Versions==============================================="

/usr/bin/psql central_repository dbadmin -c "select * from etl.version -- where component='clearsee'"

echo "****************************************ACP Last Version*************************************"
allottype -v | grep ACP

            ;;

"Total NO Tables")

echo"****************************************************Total NO TABLES IN SCHEMA*************************************"
  sudo -u dbadmin /opt/vertica/bin/vsql -d dbadmin -w dbadmin  -c " SELECT count(table_schema) as TABLES_OF_PROD_SCHEMA
    FROM tables
    where table_schema='prod';" 


;;

"License")

	/usr/bin/psql central_repository dbadmin -c "select * from etl.license_key"
	/usr/bin/psql central_repository dbadmin -c "select * from etl.lk_enforcement"
;;

"cs_admin status")

su - dbadmin -c "/usr/local/bin/cs_admin status"
;;

"Files Status")

/usr/bin/psql central_repository dbadmin -c " select b.data_source_name,count(*),a.state,a.data_source_id
    from etl.files a
    inner join etl.data_sources b
    on a.data_source_id=b.data_source_id
    and discovery_time > current_timestamp - interval '1 day'
     group by b.data_source_name , 
     a.state,
     a.data_source_id
     order by b.data_source_name"
	;;

"Failed jobs status")

/usr/bin/psql central_repository dbadmin -c "
select target_table,worker_id,status 
from etl.aggregation_jobs where status='job_failed'
and Job_key > current_timestamp - interval '1 day'"
;;

"Failed scheduled task")
/usr/bin/psql central_repository dbadmin -c "
     select  * from etl.scheduled_task where status not in ( 'successful','init','running')"
	 ;;
	 
	 "Failed Ri jobs")
		/usr/bin/psql central_repository dbadmin -c "
     select * from etl.ri_jobs where status='job_failed'"
;;

"DWH primary")

/usr/bin/psql central_repository dbadmin -c "select * from etl.nodes"
;;

"CONV last loading")

sudo -u dbadmin /opt/vertica/bin/vsql -d dbadmin -w dbadmin  -c "select max( period_min_key) as max_period_min_key
        from prod.DWH_FACT_CONV_RAW;"
;;

"Cluster status")
echo "**********************PCS STATUS****************************"
pcs status
echo"******************service pacemarker status*******************"
service pacemarker status
echo "******************DRBD STATUS****************************"
cat /proc/drbd
echo "******************************CRM STATUS***************************"
crm_resource -p
;;

"MSTR status")

echo "==================MICROSTRATEGY STATUS========="
if 
/opt/MicroStrategy/home/bin/mstrctl -s IntelligenceServer get-status | grep 'running'
then echo "MICROSTRATEGY is [OK]"
else 
echo "MICROSTRATEGY is [DOWN]"
fi
            ;;

 "Disk Space Usage")

df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{print $5,$6}'

;;

"Backlog 7 day")

 # Show backlog status of buckets
    # How many in state 5 (found) last 7 days


/usr/bin/psql central_repository dbadmin -c " SELECT data_source_name, day1, day2, day3, day4, day5, day6, day7
FROM etl.data_sources
LEFT JOIN (
  SELECT
    data_source_id,
    COUNT(*) AS day1
  FROM etl.files
  WHERE date_trunc('day', original_modification_time) =
        date_trunc('day', current_timestamp)
        AND state = 5
  GROUP BY data_source_id
) day1t
ON day1t.data_source_id=etl.data_sources.data_source_id
LEFT JOIN (
  SELECT
    data_source_id,
    COUNT(*) AS day2
  FROM etl.files
  WHERE date_trunc('day', original_modification_time) =
        date_trunc('day', current_timestamp) - INTERVAL '1 day'
        AND state = 5
  GROUP BY data_source_id
    ) day2t
ON day1t.data_source_id=day2t.data_source_id
LEFT JOIN (
  SELECT
    data_source_id,
    COUNT(*) AS day3
  FROM etl.files
  WHERE date_trunc('day', original_modification_time) =
        date_trunc('day', current_timestamp) - INTERVAL '2 day'
        AND state = 5
  GROUP BY data_source_id
    ) day3t
ON day1t.data_source_id=day3t.data_source_id
LEFT JOIN (
  SELECT
    data_source_id,
    COUNT(*) AS day4
  FROM etl.files
  WHERE date_trunc('day', original_modification_time) =
        date_trunc('day', current_timestamp) - INTERVAL '3 day'
        AND state = 5
  GROUP BY data_source_id
    ) day4t
ON day1t.data_source_id=day4t.data_source_id
LEFT JOIN (
  SELECT
    data_source_id,
    COUNT(*) AS day5
  FROM etl.files
  WHERE date_trunc('day', original_modification_time) =
        date_trunc('day', current_timestamp) - INTERVAL '4 day'
        AND state = 5
  GROUP BY data_source_id
    ) day5t
ON day1t.data_source_id=day5t.data_source_id
LEFT JOIN (
  SELECT
    data_source_id,
    COUNT(*) AS day6
  FROM etl.files
  WHERE date_trunc('day', original_modification_time) =
        date_trunc('day', current_timestamp) - INTERVAL '5 day'
        AND state = 5
  GROUP BY data_source_id
    ) day6t
ON day1t.data_source_id=day6t.data_source_id
LEFT JOIN (
  SELECT
    data_source_id,
    COUNT(*) AS day7
  FROM etl.files
  WHERE date_trunc('day', original_modification_time) =
        date_trunc('day', current_timestamp) - INTERVAL '6 day'
        AND state = 5
  GROUP BY data_source_id
    ) day7t
ON day1t.data_source_id=day7t.data_source_id
WHERE day1 IS NOT NULL
OR day2 IS NOT NULL
OR day3 IS NOT NULL
OR day4 IS NOT NULL
OR day5 IS NOT NULL
OR day6 IS NOT NULL
OR day7 IS NOT NULL";
;;

"Tomcat Status")

service tomcat status | grep running
;;

"Refresh Cubes")
/opt/allot/clearsee/etl/pymodules/CubeInitialPublish/CubeInitialPublish.py 

;;

"Postgres")
/usr/bin/psql central_repository dbadmin
;;

"Vertica")
/opt/vertica/bin/vsql -w dbadmin -U dbadmin
;;

      "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

