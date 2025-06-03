FROM openjdk:21-jdk-slim
RUN mkdir /app
COPY target/java-datacontracts-producer-recipes-1.0.0.jar /app/java-datacontracts-producer-recipes-1.0.0.jar
CMD ["java","-jar","/app/java-datacontracts-producer-recipes-1.0.0.jar","/app/producer-recipes.properties"]
