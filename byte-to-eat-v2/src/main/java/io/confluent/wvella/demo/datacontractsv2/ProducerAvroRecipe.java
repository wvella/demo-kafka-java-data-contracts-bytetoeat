/**
 * Copyright 2020 Confluent Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package io.confluent.wvella.demo.datacontractsv2;

import static io.confluent.wvella.demo.datacontractsv2.Util.loadConfig;

import java.io.IOException;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.Properties;
import java.util.UUID;

import org.apache.kafka.clients.producer.Callback;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;

import io.confluent.kafka.serializers.KafkaAvroSerializer;
public class ProducerAvroRecipe {

  public static void main(final String[] args) throws IOException {
    if (args.length < 2) {
      System.out.println("Please provide command line arguments: configPath createAllIngredients");
      System.exit(1);
    }

    // Load properties from a local configuration file
    // Create the configuration file (e.g. at '/.confluent/java.config') with
    // configuration parameters
    // to connect to your Kafka cluster, which can be on your local host, Confluent
    // Cloud, or any other cluster.
    // Follow these instructions to create this file:
    // https://docs.confluent.io/platform/current/tutorials/examples/clients/docs/java.html
    final Properties props = loadConfig(args[0]);

    final String topic = props.getProperty("topic");

    // Add additional properties.
    props.put(ProducerConfig.ACKS_CONFIG, "all");
    props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
    props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, KafkaAvroSerializer.class);

    // Number of executions
    final Long numExecutions = 1L;
    for (Long ex = 0L; ex < numExecutions; ex++) {
      Producer<String, Recipe> producer = new KafkaProducer<String, Recipe>(props);

      // Number of messages in a batch
      final Long numMessages = 1L;
      for (Long i = 0L; i < numMessages; i++) {

        // Toggle to control whether all ingredients or just one ingredient is created
        boolean createAllIngredients = Boolean.parseBoolean(args[1]); // Set to false to create only one ingredient

        // Create Ingredients
        List<Ingredient> ingredients;
        if (createAllIngredients) {
          ingredients = Arrays.asList(
              new Ingredient("Spaghetti", 500, "grams"),
              new Ingredient("Ground beef", 250, "grams"),
              new Ingredient("Tomato sauce", 400, "ml"),
              new Ingredient("Onion", 1, "piece"),
              new Ingredient("Garlic", 2, "cloves"),
              new Ingredient("Olive oil", 2, "tablespoons"),
              new Ingredient("Salt", 2, "teaspoon"),
              new Ingredient("Pepper", 1, "teaspoon"));
        } else {
          ingredients = Arrays.asList(
              new Ingredient("Spaghetti", 500, "grams") // Only one ingredient
          );
        }

        // Create Steps
        List<CharSequence> steps = Arrays.asList(
            "1. Boil water and cook spaghetti according to package instructions.",
            "2. Heat olive oil in a pan and sauté chopped onion and garlic until fragrant.",
            "3. Add ground beef to the pan and cook until browned.",
            "4. Stir in tomato sauce, salt, and pepper. Simmer for 20 minutes.",
            "5. Serve the sauce over the cooked spaghetti.");

        // Create the Recipe
        Recipe recipe = new Recipe();
        recipe.setEventId(UUID.randomUUID().toString());
        recipe.setRecipeId("Spaghetti Bolognese");
        recipe.setChefFirstName("Chef Gordon");
        recipe.setChefLastName("Ramsay");
        recipe.setRecipeName("Spaghetti Bolognese");
        recipe.setIngredients(ingredients);
        recipe.setCookTimeMinutes(45);
        recipe.setSpiceLevel(SpiceLevel.mild);
        recipe.setCalories(600);
        recipe.setCreatedAt(Instant.now());
        recipe.setSteps(steps);

        Recipe record = recipe;

        // Use the recipe ID as the key
        String key = recipe.getRecipeId().toString();
        System.out.print("\n");
        System.out.print("========= Producing record: ========= ");
        System.out.printf("%n[Key:]%n%s%n[Value:]%n%s%n", key, record);
        System.out.print("\n");

        long startTime = System.currentTimeMillis(); // Start time
        // Required to catch the SerializationException which will automatically write
        // the message to the DLQ and continue processing
        try {
          producer.send(new ProducerRecord<String, Recipe>(topic, key, record), new Callback() {
            long endTime = System.currentTimeMillis();

            @Override
            public void onCompletion(RecordMetadata m, Exception e) {
              if (e != null) {
                e.printStackTrace();
              } else {
                System.out.printf("Produced record to topic %s partition [%d] @ offset %d%n", m.topic(), m.partition(),
                    m.offset());
                long duration = endTime - startTime; // Duration in milliseconds
                System.out.printf("Time taken: %d ms%n", duration);
              }
            }
          });
        } catch (Exception e) {
          System.err.println("Failed to send record to Kafka: " + e.getMessage());
          e.printStackTrace();
        }
      }
      producer.flush();
      System.out.printf("Messages were produced to topic %s%n", topic);

      try {
        Thread.sleep(5000); // Sleep for 5 seconds
      } catch (InterruptedException e) {
        e.printStackTrace();
        Thread.currentThread().interrupt(); // Restore interrupted status
      }
      producer.close();
    }

  }
}
