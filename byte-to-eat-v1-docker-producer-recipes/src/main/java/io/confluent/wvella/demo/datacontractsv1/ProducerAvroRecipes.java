/**
 * Copyright 2020 Confluent Inc.
 *
 * <p>Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * <p>http://www.apache.org/licenses/LICENSE-2.0
 *
 * <p>Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.confluent.wvella.demo.datacontractsv1;

import static io.confluent.wvella.demo.datacontractsv1.Util.loadConfig;

import java.io.IOException;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.Properties;
import java.util.UUID;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;

import io.confluent.kafka.serializers.KafkaAvroSerializer;

public class ProducerAvroRecipes {

  public static void main(final String[] args) throws IOException {
    if (args.length < 1) {
      System.out.println("Please provide command line arguments: configPath");
      System.exit(1);
    }

    final Properties props = loadConfig(args[0]);
    final String topic = props.getProperty("topic");
    addProducerProperties(props);

    final Long numExecutions = 1L;
    for (Long ex = 0L; ex < numExecutions; ex++) {
      Producer<String, Recipe> producer = new KafkaProducer<>(props);

      final Long numMessages = 1L;
      for (Long i = 0L; i < numMessages; i++) {
        String createAllIngredientsStr = System.getenv()
            .getOrDefault("LIST_ALL_INGREDIENTS", "true");
        boolean createAllIngredients = Boolean.parseBoolean(createAllIngredientsStr);
        Recipe recipe = buildRecipe(createAllIngredients);
        sendRecipe(producer, topic, recipe);
      }

      producer.flush();
      System.out.printf("Messages were produced to topic %s%n", topic);

      sleepFiveSeconds();
      producer.close();
    }
  }

  private static void addProducerProperties(Properties props) {
    props.put(ProducerConfig.ACKS_CONFIG, "all");
    props.put(
        ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG,
        "org.apache.kafka.common.serialization.StringSerializer");
    props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, KafkaAvroSerializer.class);
  }

  private static Recipe buildRecipe(boolean createAllIngredients) {
    List<Ingredient> ingredients = createAllIngredients
        ? Arrays.asList(
            new Ingredient("Spaghetti", 500, "grams"),
            new Ingredient("Ground beef", 250, "grams"),
            new Ingredient("Tomato sauce", 400, "ml"),
            new Ingredient("Onion", 1, "piece"),
            new Ingredient("Garlic", 2, "cloves"),
            new Ingredient("Olive oil", 2, "tablespoons"),
            new Ingredient("Salt", 2, "teaspoon"),
            new Ingredient("Pepper", 1, "teaspoon"))
        : Arrays.asList(new Ingredient("Spaghetti", 500, "grams"));

    List<CharSequence> steps = Arrays.asList(
        "1. Boil water and cook spaghetti according to package instructions.",
        "2. Heat olive oil in a pan and sauté chopped onion and garlic until fragrant.",
        "3. Add ground beef to the pan and cook until browned.",
        "4. Stir in tomato sauce, salt, and pepper. Simmer for 20 minutes.",
        "5. Serve the sauce over the cooked spaghetti.");

    Recipe recipe = new Recipe();
    recipe.setEventId(UUID.randomUUID().toString());
    recipe.setRecipeId("Spaghetti Bolognese");
    recipe.setChefName("Chef Gordon Ramsay");
    recipe.setRecipeName("Spaghetti Bolognese");
    recipe.setIngredients(ingredients);
    recipe.setCookTimeMinutes(45);
    recipe.setSpiceLevel(SpiceLevel.mild);
    recipe.setCalories(600);
    recipe.setCreatedAt(Instant.now());
    recipe.setSteps(steps);
    return recipe;
  }

  private static void sendRecipe(Producer<String, Recipe> producer, String topic, Recipe recipe) {
    String key = recipe.getRecipeId().toString();
    System.out.print("\n");
    System.out.print("========= Producing record: ========= ");
    System.out.printf("%n[Key:]%n%s%n[Value:]%n%s%n", key, recipe);
    System.out.print("\n");

    long startTime = System.currentTimeMillis();
    try {
      producer.send(new ProducerRecord<>(topic, key, recipe), new ProducerCallback(startTime));
    } catch (Exception e) {
      System.err.println("Failed to send record to Kafka: " + e.getMessage());
      e.printStackTrace();
    }
  }

  private static void sleepFiveSeconds() {
    try {
      Thread.sleep(5000);
    } catch (InterruptedException e) {
      e.printStackTrace();
      Thread.currentThread().interrupt();
    }
  }

  private static class ProducerCallback implements org.apache.kafka.clients.producer.Callback {
    private final long startTime;

    ProducerCallback(long startTime) {
      this.startTime = startTime;
    }

    @Override
    public void onCompletion(RecordMetadata m, Exception e) {
      long endTime = System.currentTimeMillis();
      if (e != null) {
        e.printStackTrace();
      } else {
        System.out.printf("Produced record to topic %s partition [%d] @ offset %d%n",
            m.topic(), m.partition(), m.offset());
        long duration = endTime - startTime;
        System.out.printf("Time taken: %d ms%n", duration);
      }
    }
  }
}
