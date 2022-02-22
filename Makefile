# Makefile for docker/mlflow/db/etc setup.  Most of this is really just for
# testing or miscellaneous needs, as the docker-compose file covers most of
# this already.  Two main exceptions are: mlflowpopulate which is handy for
# generating test entries in mlflow, and psqld which can provide psql entry
# directly into the mlflow db for the docker-compose files that allow it,
# which does NOT include the default one - need the ones that don't hide
# database on a backend network, like docker-compose.mlflow_postgres.yaml).
#
# Note sortof hardwired choice of postgres db in this makefile corresponding to
# the default docker-compose.yaml file in root dir.

ARTIFACTS=/mlruns   # inside mlflowd container
# MLGWHOST only relevant to mlflowpopulate and assumes mlflow container running:
MLGWHOST=$(shell docker inspect -f '{{ .NetworkSettings.Networks.docker_mlflow_db_frontend.Gateway }}' mlflow_server)
#MLGWHOST=host.docker.internal  # for macos with Docker Desktop
# DBGWHOST and DBCONNECT assume db container running, relevant to psqld and mlflowd:
DBGWHOST=$(shell docker inspect -f '{{ .NetworkSettings.Networks.docker_mlflow_db_mydefault.Gateway }}' mlflow_db)
DBCONNECT=postgresql://${DB_USER}:${DB_PW}@${DBGWHOST}:${DB_PORT}/${DB_NAME}

clean:
	docker volume rm docker_mlflow_db_mlrun_data
	docker volume rm docker_mlflow_db_db_datapg

pgdb:
	# Run postgres db on its own from container
	@docker run -p ${DB_PORT}:${DB_PORT} -v db_datapg:/var/lib/postgresql/data \
	    -e POSTGRES_DB=${DB_NAME} -e POSTGRES_USER=${DB_USER} -e POSTGRES_PASSWORD=${DB_PW} \
	    postgres:latest

psqld:
	# Run psql (postgres login app) on its own, locally or from container.
	# assumes locally installed:
	psql postgresql://${DB_USER}:${DB_PW}@localhost:${DB_PORT}/${DB_NAME}
	# if don't have psql locally:
	#@docker run -it postgres:latest /usr/bin/psql ${DBCONNECT}

mlflowd:
	# Run mlflow on its own from container
	@docker run -v mlrun_data:/mlruns -p ${MLFLOW_PORT}:${MLFLOW_PORT} mlflow_server \
	    mlflow server \
	        --host 0.0.0.0 \
		--port ${MLFLOW_PORT} \
	        --backend-store-uri ${DBCONNECT} \
	       	--default-artifact-root ${ARTIFACTS}

mlflowpopulate:
	# Use the mlflow team's mlflow-example to populate a number of entries
	# in mlflow for testing.  First time is slow as conda-installs packages
	# to condaenv volume, but quick after that since reusing same condaenv
	# volume.  (TODO put this into a loop!)
	docker run -e MLFLOW_TRACKING_URI=http://${MLGWHOST}:${MLFLOW_PORT} \
		-v mlrun_data:/mlruns -v condenv:/opt/conda mlflow_server \
		mlflow run /home/mlflow-example -P alpha=0.001
	docker run -e MLFLOW_TRACKING_URI=http://${MLGWHOST}:${MLFLOW_PORT} \
		-v mlrun_data:/mlruns -v condenv:/opt/conda mlflow_server \
		mlflow run /home/mlflow-example -P alpha=0.01
	docker run -e MLFLOW_TRACKING_URI=http://${MLGWHOST}:${MLFLOW_PORT} \
		-v mlrun_data:/mlruns -v condenv:/opt/conda mlflow_server \
		mlflow run /home/mlflow-example -P alpha=0.1
	docker run -e MLFLOW_TRACKING_URI=http://${MLGWHOST}:${MLFLOW_PORT} \
		-v mlrun_data:/mlruns -v condenv:/opt/conda mlflow_server \
		mlflow run /home/mlflow-example -P alpha=1.0
	docker run -e MLFLOW_TRACKING_URI=http://${MLGWHOST}:${MLFLOW_PORT} \
		-v mlrun_data:/mlruns -v condenv:/opt/conda mlflow_server \
		mlflow run /home/mlflow-example -P alpha=10.0
	docker run -e MLFLOW_TRACKING_URI=http://${MLGWHOST}:${MLFLOW_PORT} \
		-v mlrun_data:/mlruns -v condenv:/opt/conda mlflow_server \
		mlflow run /home/mlflow-example -P alpha=100.0

mlflowquicklook:
	# simple access check to mlflow server on host port from within container
	# configured like mlflow projects.  just lists experiments (top level
	# containers).
	curl http://localhost:${MLFLOW_PORT}/api/2.0/preview/mlflow/experiments/list

	# other MLflow REST API entrypoints are listed at:
	# https://www.mlflow.org/docs/latest/rest-api.html
