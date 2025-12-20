/**
 * %% Copyright (C) 2025 DataScience 9 LLC %% Licensed under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance with the License. You may obtain a
 * copy of the License at
 *
 * <p>http://www.apache.org/licenses/LICENSE-2.0
 *
 * <p>Unless required by applicable law or agreed to in writing, software distributed under the
 * License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing permissions and
 * limitations under the License. #L%
 */
package com.ewu.career.notification;

import java.util.Properties;
import java.util.logging.Logger;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;

public class KafkaProducerService {
    private static final Logger logger = Logger.getLogger(KafkaProducerService.class.getName());
    private static final KafkaProducer<String, String> producer = createProducer();

    private static KafkaProducer<String, String> createProducer() {
        Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.ACKS_CONFIG, "all");
        return new KafkaProducer<>(props);
    }

    /** Send to a specified topic */
    public static void sendMessage(String topic, String key, String message) {
        ProducerRecord<String, String> record = new ProducerRecord<>(topic, key, message);
        producer.send(
                record,
                (metadata, exception) -> {
                    if (exception != null)
                        logger.severe(
                                String.format(
                                        "[Producer] Error sending to %s: %s%n",
                                        topic, exception.getMessage()));
                    else
                        logger.info(
                                String.format(
                                        "[Producer] Sent to %s[%d] offset=%d%n",
                                        metadata.topic(), metadata.partition(), metadata.offset()));
                });
    }

    public static void close() {
        producer.flush();
        producer.close();
    }
}
