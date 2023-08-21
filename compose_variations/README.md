The goal here was to have these files here as ready-to-go variations for
different DBs and configs.  But fyi in practice I've only actually focused on
the Postgresql-based scripts, so the sqlite and mysql based scripts may be out
of date or may need a tweak to work, and additionally I've mainly focused on
the docker-compose.yaml in root dir so there may be a few other differences.


| file                               | description |
|------------------------------------|-------------|
|docker-compose.mlflow_existingpostgres.yaml|connect mlflow to pre-existing postgres mlflow backend database (repo default)|
|docker-compose.mlflow_newpostgres.yaml|stand up a new postgres db and connect mlflow to it for backend|
|docker-compose.mlflow_sqlite.yaml   |stand up a new sqlite db and connect mlflow to it for backend|
|docker-compose.mlflow_mysql.yaml    |stand up a new mysql db and connect mlflow to it for backend|
|docker-compose.orig.yaml            |original scripts from [Guillaume Androz's 10-Jan-2020 Toward-Data-Science article](https://towardsdatascience.com/deploy-mlflow-with-docker-compose-8059f16b6039) per README.md|


To use one of these just copy it to ../docker-compose.yaml.
Note the repo's default docker-compose.yaml in its root directory is
docker-compose.mlflow_existingpostgres.yaml to begin with.

