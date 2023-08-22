# docker_mlflow_db

A ready-to-run Docker container setup to quickly provide MLflow as a service, with optional
database backend, optional storage of artifacts in AWS S3, and a reverse proxy
frontend which could allow one to easily implement basic or secure authentication.

> <SUP>
> :bulb: Note this repo is part of a trio that you might find useful together
> (but all are separate tools that can be used independently):
>   
> * [aganse/docker_mlflow_db](https://github.com/aganse/docker_mlflow_db):
>     ready-to-run MLflow server with PostgreSQL, AWS S3, Nginx
>   
> * [aganse/py_tf2_gpu_dock_mlflow](https://github.com/aganse/py_tf2_gpu_dock_mlflow):
>     ready-to-run Python/Tensorflow2/MLflow setup to train models on GPU
>   
> * [aganse/vim_mlflow](https://github.com/aganse/vim-mlflow):
>     a Vim plugin to browse the MLflow parameters and metrics instead of GUI
> </SUP>
<P>&nbsp;<P>


## Summary
The main use-case options available in this MLflow implementation are:
* store the core MLflow info in a new separate standalone database instance, or
  in a pre-existing database instance elsewhere (including perhaps AWS RDS).
  Note a PostgreSQL database is assumed in this repo's setup, although altering
  to some other database would be a minimal change (mainly in the password file
  handling)
* store the run artifact files (like model and graphic/plot files) in the local
  local filesystem, in a docker volume, or in an S3 bucket,
* the default setup in this repo serves MLflow with its own database instance,
  and both database data and artifact files stored in their own docker volumes.

There are several docker-compose.yaml files in the compose_variations
subdirectory, any of which can be used in lieu of the docker-compose.yaml in the
root directory to use the desired variation.

In all variations, the additional nginx reverse-proxy on the front end allows
for options such as:
* using an htpasswd file in the nginx container to provide non-secure, basic
  logins for workgroup members behind an already-secure firewall,
* implementing more full-fledged certficate-based secure access,
* easily swapping out the nginx image with that some other comparable service
  (caddy for example).
No secure access is implemented here, deemed outside the scope of this repo,
but by having the reverse proxy in place and already correctly functional then
one may focus one's effort for updates on just the reverse proxy component.

## To run and connect to MLflow

An easy way to start the containers using separate new standalone db instance
is to just let MLflow use the admin user account to access the database.
(Not recommended for a database other than the standalone one, and be judicious
about even that.)
```bash
echo -n mydbadminpassword  > ~/.pgadminpw  # used when creating standalone db
echo db:5432:mlflow:postgres:mydbadminpassword > ~/.pgpass  # used by mlflow to save/get its results
chmod 600 ~/.pg*
make start
```
The first time it's run will be slower as it must download/build the containers,
but after that first time it will start back up the existing containers and
volumes.  We can verify it's all up and ready via:
```bash
> docker ps
CONTAINER ID   IMAGE             COMMAND                  CREATED          STATUS          PORTS                                   NAMES
dc99e6fc8d80   mlflow_nginx      "nginx -g 'daemon of…"   18 minutes ago   Up 18 minutes   0.0.0.0:5000->80/tcp, :::5000->80/tcp   mlflow_nginx
259ea89f1a9a   mlflow_server     "sh -c 'mlflow serve…"   19 minutes ago   Up 18 minutes   5001/tcp                                mlflow_server
07bbead3e910   postgres:latest   "docker-entrypoint.s…"   19 minutes ago   Up 19 minutes   5432/tcp                                mlflow_db
```

When it's up we can access the MLFlow website at `http://localhost:5000`.  If
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

There are a set of environment variables that can control the behavior of the
implementation, but depending on one's needs one one may get away with not
specifying any of them, simply using the defaults for all of them.  Password
for the database is supplied securely via a ~/.pgpass file, PostgreSQL's standard
handling mechanism.

Here are the possible env vars one may set, and their defaults which will be
used if the variable is not explicitly set.  For runs in the default setup you
can start it up without setting any of these.
```bash
# only bother with the ones you want to change from defaults
export DB_NAME=mlflow
export DB_USER=postgres  # default is admin user of standalone database, but
                         # in pre-existing database would use regular user account
export DB_SERVER=db  # 'db' is the name of the default standalone database
                     # container, but DB_SERVER could be set to something like
                     # mydatabaseserver.abcdefghij.us-west-2.rds.amazonaws.com
export DB_PORT=5432  # port of database process
export PGADMINPW=~/.pgadminpw  # file containing pw to use for admin user of new standalone db (if used)
export PGPASS=~/.pgpass  # file containing pw to use for mlflow (DB_USER) account, in PostgreSQL pgpass format
export FILESTORE=/storage/mlruns  # if using filesystem for artifacts; unused if using S3
export AWS_DEFAULT_REGION=us-west-2                    # unused unless using S3
export AWS_S3BUCKETURL=s3://mybucketname/myprefix/     # unused unless using S3
export AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxxx              # unused unless using S3
export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxx          # unused unless using S3
```

*Warning:*
Note regardless of the mechanisms noted above, it's important to note that the
public domain version of MLflow is still fundamentally insecure, with no user logins.
One should run this strictly on a secure, company-internal, firewalled intranet
and/or wrapped within some secure/https, internet-facing layer.
Overall the typical use-case here is individual or small-group usage contained
inside a company's internal network behind a firewall, so not at the top of my
concern list.  Please beware for use-cases beyond that.


## A few other functionalities to note

The makefile contains the following two macros which can be useful in testing
and development:

* `make mlflowquickcheck` just outputs the MLflow experiments list as a
  connectivity test, answering the basic question of "is it working?"

* `make mlflowpopulate` runs the small, quick-running example project
  'mlflow-example' to generate some example/test contents in your MLflow
  instance.  This test content in a rapidly-spun-up mlflow instance can be
  really useful when testing other tools such as the
  [vim-mlflow](https://github.com/aganse/vim-mlflow) Vim plugin.


## Relevant links

Initial implementation was originally based on
[Guillaume Androz's 10-Jan-2020 Toward-Data-Science post, "Deploy MLflow with docker compose"](https://towardsdatascience.com/deploy-mlflow-with-docker-compose-8059f16b6039) (thanks for getting me started!)

Other links:<BR>
https://github.com/ymym3412/mlflow-docker-compose  
https://medium.com/vantageai/keeping-your-ml-model-in-shape-with-kafka-airflow-and-mlflow-143d20024ba6  
https://docs.nginx.com/nginx/admin-guide/security-controls/configuring-http-basic-authentication/
https://www.digitalocean.com/community/tutorials/how-to-set-up-password-authentication-with-nginx-on-ubuntu-14-04
https://www.digitalocean.com/community/tutorials/how-to-set-up-http-authentication-with-nginx-on-ubuntu-12-10
