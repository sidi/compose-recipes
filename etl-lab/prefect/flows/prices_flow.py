import subprocess
from prefect import flow, task

@task(retries=2, retry_delay_seconds=10)
def init_sqlite():
    subprocess.check_call(["python", "/work/etl/init_sqlite.py"])

@task(retries=2, retry_delay_seconds=10)
def extract():
    subprocess.check_call(["python", "/work/etl/extract.py"])

@task(retries=2, retry_delay_seconds=10)
def transform():
    subprocess.check_call(["python", "/work/etl/transform.py"])

@task(retries=2, retry_delay_seconds=10)
def load():
    subprocess.check_call(["python", "/work/etl/load.py"])

@flow(name="prices_etl_publicurls_sqlite")
def prices_flow():
    init_sqlite()
    extract()
    transform()
    load()

if __name__ == "__main__":
    prices_flow()
