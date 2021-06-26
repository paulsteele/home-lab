#!/bin/bash
# modified from https://github.com/camilb/kube-mysqldump-cron/blob/master/Docker/dump.sh since it does not have the port option
DB_USER=${DB_USER:-${MYSQL_ENV_DB_USER}}
DB_PASS=${DB_PASS:-${MYSQL_ENV_DB_PASS}}
DB_NAME=${DB_NAME:-${MYSQL_ENV_DB_NAME}}
DB_HOST=${DB_HOST:-${MYSQL_ENV_DB_HOST}}
DB_PORT=${DB_PORT:-${MYSQL_ENV_DB_PORT}}
ALL_DATABASES=${ALL_DATABASES}


if [[ ${DB_USER} == "" ]]; then
	echo "Missing DB_USER env variable"
	exit 1
fi
if [[ ${DB_PASS} == "" ]]; then
	echo "Missing DB_PASS env variable"
	exit 1
fi
if [[ ${DB_HOST} == "" ]]; then
	echo "Missing DB_HOST env variable"
	exit 1
fi
if [[ ${DB_PORT} == "" ]]; then
	echo "Missing DB_PORT env variable"
	exit 1
fi

databases=$(mysql --user="${DB_USER}" --password="${DB_PASS}" --host="${DB_HOST}" --port="${DB_PORT}" -e "SHOW DATABASES;" | tr -d "| " | grep -v Database)
for db in $databases; do
   if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != _* ]]; then
        echo "Dumping database: $db"
        mysqldump --user="${DB_USER}" --password="${DB_PASS}" --host="${DB_HOST}" --port="${DB_PORT}" --databases $db > /mysqldump/$db.sql
    fi
done
