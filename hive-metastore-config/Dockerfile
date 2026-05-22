FROM apache/hive:4.0.0

USER root
COPY mysql-connector-j-8.0.33.jar /opt/hive/lib/mysql-connector-j-8.0.33.jar
RUN chmod 644 /opt/hive/lib/mysql-connector-j-8.0.33.jar

COPY --from=apache/hive:4.0.0 /opt/hadoop/share/hadoop/tools/lib/hadoop-aws-3.3.6.jar /opt/hive/lib/hadoop-aws-3.3.6.jar
COPY --from=apache/hive:4.0.0 /opt/hadoop/share/hadoop/tools/lib/aws-java-sdk-bundle-1.12.367.jar /opt/hive/lib/aws-java-sdk-bundle-1.12.367.jar
RUN chmod 644 /opt/hive/lib/hadoop-aws-3.3.6.jar /opt/hive/lib/aws-java-sdk-bundle-1.12.367.jar

USER hive