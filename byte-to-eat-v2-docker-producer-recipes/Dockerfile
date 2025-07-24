FROM openjdk:21-jdk-slim
RUN mkdir /app
COPY target/java-datacontracts-producer-recipes-2.2.0.jar /app/java-datacontracts-producer-recipes-2.2.0.jar
CMD ["java","-jar","/app/java-datacontracts-producer-recipes-2.2.0.jar","/app/producer-recipes.properties"]
