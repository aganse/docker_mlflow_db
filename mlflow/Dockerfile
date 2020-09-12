FROM continuumio/miniconda3
RUN apt-get update && apt-get install -y git

RUN pip install mlflow psycopg2-binary pymysql boto3   # comment out boto3 if not using AWS

RUN cd /home && git clone https://github.com/mlflow/mlflow-example.git
