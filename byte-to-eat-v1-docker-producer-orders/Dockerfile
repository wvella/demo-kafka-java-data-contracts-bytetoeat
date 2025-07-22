FROM openjdk:21-jdk-slim
RUN mkdir /app
COPY target/java-datacontracts-producer-orders-1.1.0.jar /app/java-datacontracts-producer-orders-1.1.0.jar
CMD ["java","-jar","/app/java-datacontracts-producer-orders-1.1.0.jar","/app/producer-orders.properties"]
