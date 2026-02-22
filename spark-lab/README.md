# Big Data Lab (Kafka + Spark + Jupyter)

This repository provides a self-contained lab environment to run the course TD/TP using Docker Compose:
- **Apache Spark** (standalone cluster: master + worker)
- **Jupyter Notebook/Lab** (PySpark notebook image)
- **Apache Kafka** (+ Kafka UI)

---

## Services

- **spark-master**
  - Spark Master + Web UI
- **spark-worker-1**
  - Spark Worker attached to the master
- **jupyter**
  - JupyterLab/Notebook with PySpark (based on `quay.io/jupyter/pyspark-notebook:spark-3.5.3`)
- **kafka**
  - Kafka broker for streaming TD/TP
- **kafka-ui**
  - Web UI to inspect topics, messages, consumer groups

---

## Prerequisites

- Docker Engine + Docker Compose plugin
- Recommended host resources:
  - CPU: 2 cores+
  - RAM: 4 GB+ (8 GB recommended)

---

## Quick Start

1) Start the full environment:
```bash
docker compose up -d --build
````

2. Check containers:

```bash
docker compose ps
```

3. Open UIs:

* Spark Master UI: `http://localhost:8081`
* Jupyter: `http://localhost:8888` (token may be required depending on your compose env)
* Kafka UI: `http://localhost:8080`

4. Stop:

```bash
docker compose down
```

---
