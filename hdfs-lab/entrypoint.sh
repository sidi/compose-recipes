#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Global environment (root shell)
# ----------------------------
export HADOOP_HOME="${HADOOP_HOME:-/opt/hadoop}"
export HIVE_HOME="${HIVE_HOME:-/opt/hive}"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-8-openjdk-amd64}"
export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:$PATH"

PROFILE_SCRIPT="/etc/profile.d/hadoop_hive.sh"

# Create profile script if missing (so `su - hdoop` gets Hadoop/Hive in PATH)
if [ ! -f "$PROFILE_SCRIPT" ]; then
  cat > "$PROFILE_SCRIPT" <<'EOF'
export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:$PATH
EOF
  chmod 0644 "$PROFILE_SCRIPT"
fi

# Ensure hdoop login shells source the profile script
if ! grep -q "hadoop_hive.sh" /home/hdoop/.profile 2>/dev/null; then
  echo "source /etc/profile.d/hadoop_hive.sh" >> /home/hdoop/.profile
  chown hdoop:hdoop /home/hdoop/.profile
fi
if ! grep -q "hadoop_hive.sh" /home/hdoop/.bashrc 2>/dev/null; then
  echo "source /etc/profile.d/hadoop_hive.sh" >> /home/hdoop/.bashrc
  chown hdoop:hdoop /home/hdoop/.bashrc
fi

# Helper: run a command as hdoop with Hadoop/Hive env loaded
HDOOP_RUN='source /etc/profile.d/hadoop_hive.sh && '

run_as_hdoop() {
  # Usage: run_as_hdoop "some command"
  su - hdoop -c "${HDOOP_RUN}$1"
}

# ----------------------------
# Start SSH (required for start-dfs.sh on many Hadoop distros)
# ----------------------------
service ssh start >/dev/null 2>&1 || /usr/sbin/sshd

# ----------------------------
# Prepare SSH keys for hdoop (localhost auth) once
# ----------------------------
if [ ! -f /home/hdoop/.ssh/id_rsa ]; then
  run_as_hdoop "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
  run_as_hdoop "ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa"
  run_as_hdoop "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys"
  run_as_hdoop "chmod 600 ~/.ssh/authorized_keys"
  # Prime known_hosts so scripts won't block
  run_as_hdoop "ssh -o StrictHostKeyChecking=no localhost true || true"
fi

# Render hive-site.xml from template using env vars (avoids ${env:...} parsing issues)
TPL="/opt/hive/conf/hive-site.xml.template"
OUT="/opt/hive/conf/hive-site.xml"

DB_HOST="${HIVE_METASTORE_DB_HOST:-metastore-db}"
DB_PORT="${HIVE_METASTORE_DB_PORT:-5432}"
DB_NAME="${HIVE_METASTORE_DB_NAME:-hive_metastore}"
DB_USER="${HIVE_METASTORE_DB_USER:-hive}"
DB_PASS="${HIVE_METASTORE_DB_PASSWORD:-hive_password}"

if [ -f "$TPL" ]; then
  sed -e "s/__DB_HOST__/${DB_HOST}/g" \
      -e "s/__DB_PORT__/${DB_PORT}/g" \
      -e "s/__DB_NAME__/${DB_NAME}/g" \
      -e "s/__DB_USER__/${DB_USER}/g" \
      -e "s#__DB_PASSWORD__#${DB_PASS}#g" \
      "$TPL" > "$OUT"
  chown hdoop:hdoop "$OUT"
else
  echo "ERROR: Hive template ${TPL} not found."
  exit 1
fi

# ----------------------------
# Format NameNode once
# ----------------------------
if [ ! -f /home/hdoop/dfsdata/namenode/.formatted ]; then
  run_as_hdoop "hdfs namenode -format -force -nonInteractive"
  run_as_hdoop "touch /home/hdoop/dfsdata/namenode/.formatted"
fi

# ----------------------------
# Start Hadoop daemons
# ----------------------------
run_as_hdoop "start-dfs.sh"
run_as_hdoop "start-yarn.sh"

# ----------------------------
# Create Hive dirs in HDFS (idempotent)
# ----------------------------
run_as_hdoop "hadoop fs -mkdir -p /tmp || true"
run_as_hdoop "hadoop fs -chmod -R 1777 /tmp || true"
run_as_hdoop "hadoop fs -mkdir -p /user/hive/warehouse || true"
run_as_hdoop "hadoop fs -chmod -R 777 /user/hive/warehouse || true"

# ----------------------------
# Wait for Postgres (Hive metastore DB)
# ----------------------------
DB_HOST="${HIVE_METASTORE_DB_HOST:-metastore-db}"
DB_PORT="${HIVE_METASTORE_DB_PORT:-5432}"

echo "Waiting for Postgres at ${DB_HOST}:${DB_PORT}..."
until (echo > "/dev/tcp/${DB_HOST}/${DB_PORT}") >/dev/null 2>&1; do
  sleep 1
done
echo "Postgres is reachable."

# ----------------------------
# Init Hive schema once
# ----------------------------
if [ ! -f /opt/hive/.schema_initialized ]; then
  run_as_hdoop "schematool -dbType postgres -initSchema"
  touch /opt/hive/.schema_initialized
  chown hdoop:hdoop /opt/hive/.schema_initialized
fi

# ----------------------------
# Start Hive services
# ----------------------------
# Ensure logs directory exists
run_as_hdoop "mkdir -p /opt/hive/logs"

# Start Metastore + HS2 in background
run_as_hdoop "nohup hive --service metastore > /opt/hive/logs/metastore.out 2>&1 &"
sleep 3
run_as_hdoop "nohup hive --service hiveserver2 > /opt/hive/logs/hiveserver2.out 2>&1 &"

echo "Services started."
echo " - NameNode UI:      http://localhost:9870"
echo " - YARN RM UI:       http://localhost:8088"
echo " - HiveServer2:      jdbc:hive2://localhost:10000"
echo " - Metastore Thrift: thrift://localhost:9083"

# ----------------------------
# Keep container alive
# ----------------------------
tail -F /opt/hive/logs/metastore.out /opt/hive/logs/hiveserver2.out
