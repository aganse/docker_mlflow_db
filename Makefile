# Makefile for docker/mlflow/db/etc setup...

DBCONNECT="postgresql://${DB_USER}:${DB_PW}@172.17.0.1:${DB_PORT}/${DB_NAME}"

db:
	docker run -p 5432:5432 -v db_datapg:/var/lib/postgresql/data \
	    -e POSTGRES_DB=${DB_NAME} -e POSTGRES_USER=${DB_USER} -e POSTGRES_PASSWORD=${DB_PW} \
	    postgres:latest

psqld:
	docker run -it postgres:latest sh -c "exec psql ${DBCONNECT}"

mlflowd:
	docker run -v mlrun_data:/mlruns -p 5000:5000 mlflow_server \
	    mlflow server \
	        --host 0.0.0.0 \
	        --backend-store-uri ${DBCONNECT} \
	       	--default-artifact-root ./tmp

	#mlflow server --backend-store-uri file:///Users/aganse/Documents/src/python/docker_mlflow_db_nginx/tmp --default-artifact-root file:///Users/aganse/Documents/src/python/docker_mlflow_db_nginx/mlruns --host -0.0.0.0

