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
import java.util.Locale;
import java.util.Properties;
import java.util.UUID;

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

    final Properties props = loadConfig(args[0]);
    final String topic = props.getProperty("topic");
    addProducerProperties(props);

    while (true) {
      final Long numExecutions = 1L;
      for (Long ex = 0L; ex < numExecutions; ex++) {
        Producer<String, Order> producer = new KafkaProducer<>(props);
        produceOrders(producer, topic);
        producer.flush();
        System.out.printf("Messages were produced to topic %s%n", topic);
        System.out.println("Sleeping for 60 seconds before next execution...");
        sleepForSeconds(60);
        producer.close();
      }
    }
  }

  private static void addProducerProperties(Properties props) {
    props.put(ProducerConfig.ACKS_CONFIG, "all");
    props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG,
        "org.apache.kafka.common.serialization.StringSerializer");
    props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, KafkaAvroSerializer.class);
  }

  private static void produceOrders(Producer<String, Order> producer, String topic) {
    final Long numMessages = 10L;
    for (Long i = 0L; i < numMessages; i++) {
      Order order = buildOrder();
      System.out.println("Generated Order: " + order);

      String key = order.getOrderId().toString();
      System.out.print("\n");
      System.out.print("========= Producing record: ========= ");
      System.out.printf("%n[Key:]%n%s%n[Value:]%n%s%n", key, order);
      System.out.print("\n");

      long startTime = System.currentTimeMillis();
      try {
        producer.send(new ProducerRecord<>(topic, key, order), new ProducerCallback(startTime));
      } catch (Exception e) {
        System.err.println("Failed to send record to Kafka: " + e.getMessage());
        e.printStackTrace();
      }
    }
  }

  private static Order buildOrder() {
    Faker faker = new Faker(new Locale("en-AU"));
    Name name = faker.name();
    String fullName = name.fullName();

    Order order = new Order();
    order.setOrderId(UUID.randomUUID().toString());
    order.setRecipeId("Spaghetti Bolognese");
    order.setCustomerName(fullName);
    order.setCustomerAddress(faker.address().fullAddress());
    order.setQuantity(2);
    order.setSpecialRequests("Extra cheese");
    order.setStatus(OrderStatus.PLACED);
    order.setCreatedAt(System.currentTimeMillis());
    order.setEstimatedReadyTime(System.currentTimeMillis() + 1800 * 1000);

    PaymentInformation paymentInfo = new PaymentInformation();
    paymentInfo.setPaymentMethod(PaymentMethod.CREDIT_CARD);
    paymentInfo.setAmount((int) (Math.random() * (80 - 5) + 5));
    paymentInfo.setCurrency("AUD");
    paymentInfo.setCcn(faker.finance().creditCard(CreditCardType.MASTERCARD));
    paymentInfo.setPaymentStatus(PaymentStatus.COMPLETED);
    paymentInfo.setPaymentTime(System.currentTimeMillis());

    order.setPaymentInformation(paymentInfo);
    return order;
  }

  private static void sleepForSeconds(int seconds) {
    try {
      Thread.sleep(seconds * 1000L);
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
