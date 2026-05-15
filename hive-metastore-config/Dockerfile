FROM apache/hive:4.0.0

USER root
COPY mysql-connector-j-8.0.33.jar /opt/hive/lib/mysql-connector-j-8.0.33.jar
RUN chmod 644 /opt/hive/lib/mysql-connector-j-8.0.33.jar

USER hive