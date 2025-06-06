FROM openjdk:21-jdk-slim
RUN mkdir /app
COPY target/java-datacontracts-producer-orders-1.0.1.jar /app/java-datacontracts-producer-orders-1.0.1.jar
CMD ["java","-jar","/app/java-datacontracts-producer-orders-1.0.1.jar","/app/producer-orders.properties"]
