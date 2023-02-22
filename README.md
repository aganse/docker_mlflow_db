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
root directory to use the desired variation (although admittedly those others
might be slightly out of date in comparison, but hopefully at least need only
minimal tweaks if any).  The docker-compose.yaml file is a copy of
compose_variations/docker-compose.mlflow_existingpostgres.yaml.

The nginx reverse-proxy on the front end allows use of an htpasswd file in the
nginx container to provide non-secure, basic logins for workgroup members.  Note
this approach is not secure and is not encrypted - it must not be used for
internet-open systems, only within an already-firewalled company network, just
to prevent inadvertent changes by curious browsing colleagues.


### To run and connect to MLflow:

First, there are some env vars which set things like ports and database name
and so on; these all have defaults when not specified, but these are the most
likely to need setting (typically put into .bashrc).  No environment variables
contain security credentials - those are in ~/.aws and ~/.pgpass files.
```bash
export AWS_REGION=us-west-2  # (or whichever region)
export AWS_S3BUCKETURL=s3://mybucketname/myprefix/
export DB_SERVER=mydatabaseserver.abcdefghij.us-west-2.rds.amazonaws.com
export DB_NAME=mlflow2
```

*Warning:*
Even with putting those aws and postgres security credentials in those files,
it's important to note that this setup is still fundamentally insecure - you
should either be sure to run this strictly on a secure, company-internal,
firewalled intranet and/or wrapped within some secure/https, internet-facing
layer such as aws cloudfront or whatever.
Overall the typical use-case here is individual or small-group usage contained
inside a company's internal network behind a firewall, so not at the top of my
concern list.  Please beware for use-cases beyond that.

Anyhow, start the containers with `make start` or:
```bash
docker compose up -d --build 
```
(`-d` for detached mode, `--build` to build the underlying containers if needed)
The first time will download/build the containers, but after that it will
start back up the existing containers and volumes, as can be seen via
```bash
docker compose logs -f
```

We can verify it's all up and ready via:
```bash
> docker ps
CONTAINER ID   IMAGE             COMMAND                  CREATED          STATUS          PORTS                                   NAMES
dc99e6fc8d80   mlflow_nginx      "nginx -g 'daemon of…"   18 minutes ago   Up 18 minutes   0.0.0.0:5000->80/tcp, :::5000->80/tcp   mlflow_nginx
259ea89f1a9a   mlflow_server     "sh -c 'mlflow serve…"   19 minutes ago   Up 18 minutes   5001/tcp                                mlflow_server
# [and if running with its own postgres db (as in compose_variations/docker-compose.mlflow_postgres_nginx.yaml)]:
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
If running on AWS, that ssh line might look something like:
```bash
ssh -CNi "~/.ssh/my_awskey.pem" -L 5000:localhost:5000 ec2-user@12.34.56.78
```

You can shut the docker-compose all down via `make stop` which just runs a
docker compose down command.


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
