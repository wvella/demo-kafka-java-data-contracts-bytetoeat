FROM openjdk:21-jdk-slim
RUN mkdir /app
COPY target/java-datacontracts-consumer-recipes-3.0.0.jar /app/java-datacontracts-consumer-recipes-3.0.0.jar
CMD ["java","-jar","/app/java-datacontracts-consumer-recipes-3.0.0.jar","/app/consumer-recipes.properties"]
