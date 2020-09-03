Bit of a work in progress - goal is to have these files here as ready-to-go
variations for different db's and configs.  But in practice I just sortof
fix them up each time as I need them.  Want to save in here the variation
where nginx acts as the reverse proxy gating user access to mlflow website
via htpasswd.


| file                               | confirmed working |
-------------------------------------|--------------------
|docker-compose.mlflow_postgres.yaml |         Y         |
|docker-compose.mlflow_sqlite.yaml   |         Y         |
|docker-compose.orig.yaml            |         Y         |
|docker-compose.mlflow_mysql.yaml    |         N         |
|docker-compose.updated_orig.yaml    |         N         |


Just copy the given file to ../docker-compose.yaml.
(Almost there getting those N's working...)
