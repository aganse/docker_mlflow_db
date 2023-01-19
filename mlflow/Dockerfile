FROM continuumio/miniconda3
RUN apt-get update && apt-get install -y git

RUN conda install -c conda-forge shap  # binary pkg not available in pip
RUN pip install mlflow==1.30.0 psycopg2-binary pymysql boto3

RUN cd /home && git clone https://github.com/mlflow/mlflow-example.git \
    && cd mlflow-example && git checkout v1.0.0 \
    && sed -i 's/mlflow/mlflow\=\=1.30.0/' conda.yaml 
