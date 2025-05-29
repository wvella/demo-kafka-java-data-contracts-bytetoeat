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
package io.confluent.wvella.demo.datacontractsv1;

import static io.confluent.wvella.demo.datacontractsv1.Util.loadConfig;

import java.io.IOException;
import java.util.Locale;
import java.util.Properties;
import java.util.UUID;

import org.apache.kafka.clients.producer.Callback;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;

import com.github.javafaker.CreditCardType;
import com.github.javafaker.Faker;
import com.github.javafaker.Name;

import io.confluent.kafka.serializers.KafkaAvroSerializer;

public class ProducerAvroOrders {

  public static void main(final String[] args) throws IOException {
    if (args.length != 1) {
      System.out.println("Please provide command line argument: configPath");
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
      Producer<String, Order> producer = new KafkaProducer<String, Order>(props);

      // Number of messages in a batch
      final Long numMessages = 10L;
      for (Long i = 0L; i < numMessages; i++) {

        Faker faker = new Faker(new Locale("en-AU"));
        Name name = faker.name();
        String fullName = name.fullName(); // Convert Name object to a full name string
        Integer price = (int) (Math.random() * (80 - 5) + 5);

        // Create the Order
        Order order = new Order();
        order.setOrderId(UUID.randomUUID().toString()); // Unique order ID
        order.setRecipeId("Spaghetti Bolognese"); // Recipe ID
        order.setCustomerName(fullName); // Cast Name object to a full name string
        order.setCustomerAddress(faker.address().fullAddress());
        order.setQuantity(2); // Quantity of the recipe ordered
        order.setSpecialRequests("Extra cheese"); // Special requests (nullable)
        order.setStatus(OrderStatus.PLACED); // Order status (enum)
        order.setCreatedAt(System.currentTimeMillis()); // Current timestamp as Instant
        order.setEstimatedReadyTime(System.currentTimeMillis() + 1800 * 1000); // Add 1800 seconds (30 minutes) in milliseconds

        // Payment Information
        PaymentInformation paymentInfo = new PaymentInformation();
        paymentInfo.setPaymentMethod(PaymentMethod.CREDIT_CARD); // Payment method (enum)
        paymentInfo.setAmount(price); // Payment amount
        paymentInfo.setCurrency("AUD"); // Currency
        paymentInfo.setCcn(faker.finance().creditCard(CreditCardType.MASTERCARD)); // Credit card number
        paymentInfo.setPaymentStatus(PaymentStatus.COMPLETED); // Payment status (enum)
        paymentInfo.setPaymentTime(System.currentTimeMillis()); // Payment time (nullable)

        Order record = order;

        // Set payment information in the order
        order.setPaymentInformation(paymentInfo);

        System.out.println("Generated Order: " + order);

        // Use the order ID as the key
        String key = order.getOrderId().toString();
        System.out.print("\n");
        System.out.print("========= Producing record: ========= ");
        System.out.printf("%n[Key:]%n%s%n[Value:]%n%s%n", key, record);
        System.out.print("\n");

        long startTime = System.currentTimeMillis(); // Start time
        // Required to catch the SerializationException which will automatically write
        // the message to the DLQ and continue processing
        try {
          producer.send(new ProducerRecord<String, Order>(topic, key, record), new Callback() {
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
