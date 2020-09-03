# Makefile for docker/mlflow/db/etc setup, sortof hardwiring choice of postgres
# db corresponding to the default docker-compose.yaml file in root dir...

#GWHOST=$(shell docker inspect -f '{{ .NetworkSettings.Networks.docker_mlflow_db_default.Gateway }}' mlflow_db)
GWHOST=172.22.0.1  # typical gateway ip within docker container
DBCONNECT=postgresql://${DB_USER}:${DB_PW}@${GWHOST}:${DB_PORT}/${DB_NAME}
ARTIFACTS=/mlruns

pgdb:
	@docker run -p ${DB_PORT}:${DB_PORT} -v db_datapg:/var/lib/postgresql/data \
	    -e POSTGRES_DB=${DB_NAME} -e POSTGRES_USER=${DB_USER} -e POSTGRES_PASSWORD=${DB_PW} \
	    postgres:latest

psqld:
	psql postgresql://${DB_USER}:${DB_PW}@localhost:${DB_PORT}/${DB_NAME}
	#@docker run -it postgres:latest /usr/bin/psql ${DBCONNECT}   # if don't have psql locally

mlflowd:
	@docker run -v mlrun_data:/mlruns -p ${MLFLOW_PORT}:${MLFLOW_PORT} mlflow_server \
	    mlflow server \
	        --host 0.0.0.0 \
		--port ${MLFLOW_PORT} \
	        --backend-store-uri ${DBCONNECT} \
	       	--default-artifact-root ${ARTIFACTS}

