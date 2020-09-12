# Makefile for docker/mlflow/db/etc setup, sortof hardwiring choice of postgres
# db corresponding to the default docker-compose.yaml file in root dir...

DBGWHOST=$(shell docker inspect -f '{{ .NetworkSettings.Networks.docker_mlflow_db_mydefault.Gateway }}' mlflow_db)
MLGWHOST=$(shell docker inspect -f '{{ .NetworkSettings.Networks.docker_mlflow_db_mydefault.Gateway }}' mlflow_server)
DBCONNECT=postgresql://${DB_USER}:${DB_PW}@${DBGWHOST}:${DB_PORT}/${DB_NAME}
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

mlflowpopulate:
	# first time slow as conda-installs packages to condaenv volume, but quick after that since reusing same condaenv volume
	docker run -e MLFLOW_TRACKING_URI=http://${MLGWHOST}:${MLFLOW_PORT} -v mlrun_data:/mlruns -v condenv:/opt/conda mlflow_server \
		mlflow run /home/mlflow-example -P alpha=0.01
	docker run -e MLFLOW_TRACKING_URI=http://${MLGWHOST}:${MLFLOW_PORT} -v mlrun_data:/mlruns -v condenv:/opt/conda mlflow_server \
		mlflow run /home/mlflow-example -P alpha=0.1
	docker run -e MLFLOW_TRACKING_URI=http://${MLGWHOST}:${MLFLOW_PORT} -v mlrun_data:/mlruns -v condenv:/opt/conda mlflow_server \
		mlflow run /home/mlflow-example -P alpha=1.0
	docker run -e MLFLOW_TRACKING_URI=http://${MLGWHOST}:${MLFLOW_PORT} -v mlrun_data:/mlruns -v condenv:/opt/conda mlflow_server \
		mlflow run /home/mlflow-example -P alpha=10.0

mlflowquicklook:
	# test access to mlflow server on host port from within container configured like mlflow projects
	curl http://localhost:${MLFLOW_PORT}/api/2.0/preview/mlflow/experiments/list

	# other MLflow REST API entrypoints are listed at:
	# https://www.mlflow.org/docs/latest/rest-api.html
