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

package io.confluent.wvella.demo.datacontractsv2;

import static io.confluent.wvella.demo.datacontractsv1.Util.loadConfig;

import java.time.Duration;
import java.util.Arrays;
import java.util.Properties;

import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;

import io.confluent.kafka.serializers.KafkaAvroDeserializer;
import io.confluent.kafka.serializers.KafkaAvroDeserializerConfig;

public class ConsumerAvroRecipes {

  public static void main(final String[] args) throws Exception {
    if (args.length != 1) {
      System.out.println("Please provide command line argument: configPath");
      System.exit(1);
    }

    // Load properties from a local configuration file
    final Properties props = loadConfig(args[0]);

    final String topic = props.getProperty("topic");

    // Add additional properties.
    props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG,
        "org.apache.kafka.common.serialization.StringDeserializer");
    props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, KafkaAvroDeserializer.class);
    props.put(KafkaAvroDeserializerConfig.SPECIFIC_AVRO_READER_CONFIG, true);
    props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

    final Consumer<String, Recipe> consumer = new KafkaConsumer<String, Recipe>(props);
    consumer.subscribe(Arrays.asList(topic));

    try {
      while (true) {
        ConsumerRecords<String, Recipe> records = consumer.poll(Duration.ofMillis(100));
        for (ConsumerRecord<String, Recipe> record : records) {
          String key = record.key();
          Recipe value = record.value();
          System.out.println();
          System.out.printf("Consumed record with key %s and value %s", key, value);
          System.out.println();
        }
      }
    } finally {
      consumer.close();
    }
  }
}
