FROM openjdk:21-jdk-slim
RUN mkdir /app
COPY target/java-datacontracts-consumer-recipes-1.2.0.jar /app/java-datacontracts-consumer-recipes-1.2.0.jar
CMD ["java","-jar","/app/java-datacontracts-consumer-recipes-1.2.0.jar","/app/consumer-recipes.properties"]
