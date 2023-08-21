# Makefile for testing and populating of the docker/mlflow/db setup.
# Warning: note 'make clean' will empty out your mlflow contents completely.

# MLGWHOST variable is the address for accessing mlflow from inside the
# mlflow_server docker container.
MLGWHOST=$(shell docker inspect -f '{{ .NetworkSettings.Networks.docker_mlflow_db_default.Gateway }}' mlflow_server)
# MLGWHOST=172.17.0.1  # may be ubuntu-specific
# Localhost is used to access mlflow outside the docker container.
MLFLOW_PORT=5000

ALPHA = 0.0002 0.002 0.02 0.2 2.0 20.0 200.0 2000.0
L1RATIO = 0.1 0.2 0.3
EXPT = 'Testing1'

start:
	# Default location in docker-compose.yml for artifact store is docker volume
	# but let's set it to local filesystem in makefile here for easy example runs.
	docker compose up -d --build

stop:
	docker compose down

clean:
	docker volume rm docker_mlflow_db_datapg_vol
	docker volume rm docker_mlflow_db_condaenv_vol
	docker volume rm docker_mlflow_db_mlruns_vol

mlflowquickcheck:
	# Simple access check to mlflow server on host port; just lists experiments.
	docker exec                                                      \
	    -e MLFLOW_TRACKING_URI=http://${MLGWHOST}:${MLFLOW_PORT}     \
	    mlflow_server                                                \
	    mlflow experiments search  # (in mlflow v1 use 'list', v2 use 'search')

mlflowpopulate:
	# Populates entries in mlflow with the mlflow team's own mlflow-example.
	# First time is slow as conda-installs packages to condaenv_vol volume,
	# but runs quick after that via reusing same condaenv_vol volume.
	docker exec                                                      \
	    -e MLFLOW_TRACKING_URI=http://${MLGWHOST}:${MLFLOW_PORT}     \
	    mlflow_server                                                \
		mlflow experiments create -n $(EXPT) &> /dev/null ||         \
		echo Populating pre-existing experiment $(EXPT)
	@$(foreach loop_l1ratio, $(L1RATIO),                             \
		$(foreach loop_alpha, $(ALPHA),                              \
		echo passing params $(loop_l1ratio) $(loop_alpha) into loop; \
		docker exec                                                  \
		    -e MLFLOW_TRACKING_URI=http://${MLGWHOST}:${MLFLOW_PORT} \
		    mlflow_server                                            \
		    mlflow run /home/mlflow-example                          \
			-P alpha=$(loop_alpha)                                   \
			-P l1_ratio=$(loop_l1ratio)                              \
		    --experiment-name=$(EXPT)                                \
		;)                                                           \
	)
