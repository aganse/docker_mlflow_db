# docker_mlflow_db
A docker-compose setup to quickly provide MlFlow service with database backend
and a reverse proxy frontend which can optionally allow for basic authentication.

### Summary:

Originally based on [Guillaume Androz's 10-Jan-2020 Toward-Data-Science post,
"Deploy MLflow with docker compose"]
(https://towardsdatascience.com/deploy-mlflow-with-docker-compose-8059f16b6039),
with some changes to:
* replace AWS usage with local mapping for artifact store
* replace mysql with postgresql and other options.
* set the whole thing in an easily deployable repo that starts right off the bat
  (whereas the original was just a web article).

There are several docker-compose.yaml files in the compose_variations
subdirectory, any of which can be in lieu of the docker-compose.yaml in the
root directory to use the desired variation.  The docker-compose.yaml file is
a copy of compose_variations/docker-compose.mlflow_postgres_nginx.yaml.  Only
this docker-compose.yaml is necessarily fully up-to-date and tested, but
brief comparisons with the other files should make pretty clear what to update
if necessary.

The nginx reverse-proxy on the front end allows use of an htpasswd file in the
nginx container to provide non-secure, basic logins for workgroup members.  Note
this approach is not secure and is not encrypted - it must not be used for
internet-open systems, only within an already-firewalled company network, just
to prevent inadvertent changes by curious browsing colleagues.


### To run and connect to MLflow:

First, there are some env vars which set things like ports and database name
and so on; these all have defaults when not specified, but it is highly
recommended that at least the DB_PW (database password) is not left to its
default value and is rather set by hand - detaled work.

The default env variables run mlflow with its backend store in postgresql and
its artifact store in a local docker volume.  The database is hidden on a
backend network, and the mlflow contents are viewable via website or REST API.
```bash
export MLFLOW_PORT=5000
export DB_NAME=mlflowdb
export DB_PORT=5432
export DB_USER=postgres
export DB_PW=<somepassword>        # (choose an actual pw)
```
A minor gotcha to note: this `<somepassword>` is expected to have no spaces
in it, not due to the database used but due to the way I pass it from this
variable.  Should fix this in future but meanwhile fyi.

*Warning:*
Also note there's a security issue in general with putting passwords in
environment variables, as one can interrogate the Linux process list and/or
the Docker inspect output and see it.  But typical use-case here is individual
or small-group usage contained inside a company's internal network behind a
firewall, so not at the top of my concern list.  Please beware for use-cases
beyond that.

Anyhow, start the containers with `make start` or:
```bash
docker-compose up -d --build 
```
(`-d` for detached mode, `--build` to build the underlying containers if needed)
The first time will download/build the containers, but after that it will
start back up the existing containers and volumes, as can be seen via
```bash
docker-compose logs -f
```

We can verify it's all up and ready via:
```bash
> docker ps
CONTAINER ID   IMAGE             COMMAND                  CREATED          STATUS          PORTS                                   NAMES
dc99e6fc8d80   mlflow_nginx      "nginx -g 'daemon of…"   18 minutes ago   Up 18 minutes   0.0.0.0:5000->80/tcp, :::5000->80/tcp   mlflow_nginx
259ea89f1a9a   mlflow_server     "sh -c 'mlflow serve…"   19 minutes ago   Up 18 minutes   5001/tcp                                mlflow_server
07bbead3e910   postgres:latest   "docker-entrypoint.s…"   19 minutes ago   Up 19 minutes   5432/tcp                                mlflow_db
```

While it's up we can access the MLFlow website via `http://localhost:5000`.  If
this is running on a remote machine without firewalled access, you could access
via `http://remotehost:5000` (ie if the remote hostname were 'remotehost'), or
if only access to remotehost is via ssh tunnel, then this command running in a
separate terminal:
```bash
ssh -CNL 5000:localhost:5000 <username>@<hostname>
```
will allow you to access the MLFlow website via `http://localhost:5000` locally.
If running on AWS, that line might look something like:
```bash
ssh -CNi "~/.ssh/my_awskey.pem" -L 5000:localhost:5000 ec2-user@12.34.56.78
```

You can shut the docker-compose all down via `docker-compose down`, or if you
want the volumes (database and mlflow artifacts stores) entirely deleted too then:
```bash
> docker-compose down --volumes
Stopping mlflow_server ... done
Stopping mlflow_db     ... done
Removing mlflow_server ... done
Removing mlflow_db     ... done
Removing network docker_mlflow_db_mydefault
Removing volume docker_mlflow_db_db_datapg
Removing volume docker_mlflow_db_mlrun_data
```


### A few other functionalities to be aware of:

The makefile contains the following two macros which can be useful in testing
and development:

* `make mlflowquickcheck` just outputs the MLflow experiments list as a
  connectivity test, answering the basic question of "is it working?"

* `make mlflowpopulate` runs the small, quick-running example project
  'mlflow-example' to generate some example/test contents in your MLflow
  instance.  This test content in a rapidly-spun-up mlflow instance can be
  really useful when testing other tools such as the
  [vim-mlflow](https://github.com/aganse/vim-mlflow) Vim plugin.


### Some other relevant links:

https://github.com/ymym3412/mlflow-docker-compose  
https://medium.com/vantageai/keeping-your-ml-model-in-shape-with-kafka-airflow-and-mlflow-143d20024ba6  
https://docs.nginx.com/nginx/admin-guide/security-controls/configuring-http-basic-authentication/
https://www.digitalocean.com/community/tutorials/how-to-set-up-password-authentication-with-nginx-on-ubuntu-14-04
https://www.digitalocean.com/community/tutorials/how-to-set-up-http-authentication-with-nginx-on-ubuntu-12-10
