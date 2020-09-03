# Makefile for docker/mlflow/db/etc setup...

#GWHOST=$(shell docker inspect -f '{{ .NetworkSettings.Networks.docker_mlflow_db_default.Gateway }}' mlflow_db)
GWHOST=172.22.0.1
DBCONNECT=postgresql://${DB_USER}:${DB_PW}@${GWHOST}:${DB_PORT}/${DB_NAME}
ARTIFACTS=/mlruns

pgdb:
	@docker run -p ${DB_PORT}:${DB_PORT} -v db_datapg:/var/lib/postgresql/data \
	    -e POSTGRES_DB=${DB_NAME} -e POSTGRES_USER=${DB_USER} -e POSTGRES_PASSWORD=${DB_PW} \
	    postgres:latest

psqld:
	psql postgresql://${DB_USER}:${DB_PW}@localhost:${DB_PORT}/${DB_NAME}
	#@docker run -it postgres:latest /usr/bin/psql ${DBCONNECT}

mlflowd:
	@docker run -v mlrun_data:/mlruns -p ${MLFLOW_PORT}:${MLFLOW_PORT} mlflow_server \
	    mlflow server \
	        --host 0.0.0.0 \
		--port ${MLFLOW_PORT} \
	        --backend-store-uri ${DBCONNECT} \
	       	--default-artifact-root ${ARTIFACTS}

	#mlflow server --backend-store-uri file:///Users/aganse/Documents/src/python/docker_mlflow_db_nginx/tmp --default-artifact-root file:///Users/aganse/Documents/src/python/docker_mlflow_db_nginx/mlruns --host -0.0.0.0

