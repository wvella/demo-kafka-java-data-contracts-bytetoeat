FROM openjdk:21-jdk-slim
RUN mkdir /app
COPY target/java-datacontracts-consumer-orders-1.1.0.jar /app/java-datacontracts-consumer-orders-1.1.0.jar
CMD ["java","-jar","/app/java-datacontracts-consumer-orders-1.1.0.jar","/app/consumer-orders.properties"]
