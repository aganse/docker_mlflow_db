# docker_mlflow_db
A docker-compose setup to quickly provide MlFlow service with database backend
and potentially reverse proxy frontend for authentication.

### Summary:
Merely a tweak of [Guillaume Androz's 10-Jan-2020 Toward-Data-Science post,
"Deploy MLflow with docker compose"]
(https://towardsdatascience.com/deploy-mlflow-with-docker-compose-8059f16b6039),
with a few changes to:
1. replace AWS usage with local mapping for artifact store (done)
2. replace mysql with postgresql.
and allowing me to quickly clone to to wherever I'm working.

Also may incorporate additional bits and pieces from:
https://github.com/ymym3412/mlflow-docker-compose
https://medium.com/vantageai/keeping-your-ml-model-in-shape-with-kafka-airflow-and-mlflow-143d20024ba6


### To run:
Set the following env vars in shell first:
```bash
export DB_NAME='mlflowdb'
export DB_USER='postgres'
export DB_PW='<mypassword>'        # (choose an actual pw)
export DB_ROOT_PW='<rtpassword>'   # (choose an actual pw)
```
(or you can use these into an .env file without the 'export's...)

Then start the containers with:
```bash
docker-compose up -d --build 
```
(-d for detached mode, --build to build the underlying containers if needed)
The first time will download/build the containers, but after that it will
generate output similar to this:
```bash
aganse docker_mlflow_db  (master *) 14:12:27> docker-compose up -d --build
Creating network "docker_mlflow_db_backend" with driver "bridge"
Creating network "docker_mlflow_db_frontend" with driver "bridge"
Building web
Step 1/2 : FROM python:3.7-slim-buster
 ---> d3fbf7fff365
Step 2/2 : RUN pip install mlflow boto3 pymysql
 ---> Using cache
 ---> f0d347dcd19b

Successfully built f0d347dcd19b
Successfully tagged mlflow_server:latest
Building nginx
Step 1/4 : FROM nginx:1.17.6
 ---> f7bb5701a33c
Step 2/4 : RUN rm /etc/nginx/nginx.conf
 ---> Using cache
 ---> d2f3deeae562
Step 3/4 : COPY nginx.conf /etc/nginx
 ---> Using cache
 ---> 48519c857f66
Step 4/4 : COPY mlflow.conf /etc/nginx/sites-enabled/
 ---> Using cache
 ---> b2089a7a4b16

Successfully built b2089a7a4b16
Successfully tagged mlflow_nginx:latest
Creating mlflow_server ... done
Creating mlflow_db     ... done
Creating mlflow_nginx  ... done
```

We can verify it's all up and ready via:
```bash
aganse docker_mlflow_db  (master *) 14:12:36> docker ps
CONTAINER ID        IMAGE                       COMMAND                  CREATED             STATUS                            PORTS                 NAMES
9e645787e83e        mlflow_nginx                "nginx -g 'daemon of…"   9 seconds ago       Up 8 seconds                      0.0.0.0:80->80/tcp    mlflow_nginx
84e63be6f8fc        mlflow_server               "mlflow server --bac…"   9 seconds ago       Up 8 seconds                      5050/tcp              mlflow_server
f615c7b3d367        mysql/mysql-server:5.7.28   "/entrypoint.sh mysq…"   9 seconds ago       Up 8 seconds (health: starting)   3306/tcp, 33060/tcp   mlflow_db
```

And to shut it all down:
```bash
aganse docker_mlflow_db  (master *) 14:16:51> docker-compose down
Stopping mlflow_nginx  ... done
Stopping mlflow_db     ... done
Stopping mlflow_server ... done
Removing mlflow_nginx  ... done
Removing mlflow_db     ... done
Removing mlflow_server ... done
Removing network docker_mlflow_db_nginx_backend
Removing network docker_mlflow_db_nginx_frontend
```
