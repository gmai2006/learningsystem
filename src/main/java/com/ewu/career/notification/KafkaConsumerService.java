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

import java.time.Duration;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;
import java.util.logging.Logger;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.serialization.StringDeserializer;

public class KafkaConsumerService implements Runnable {
    private final Logger logger = Logger.getLogger(this.getClass().getName());
    private final KafkaConsumer<String, String> consumer;
    private final Set<String> subscribedTopics = new CopyOnWriteArraySet<>();
    private final Map<String, List<KafkaSubscriber>> subscribers = new ConcurrentHashMap<>();
    private volatile boolean running = true;

    public KafkaConsumerService(
            String bootstrapServers, Collection<String> topics, String groupId) {
        Properties props = new Properties();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        props.put(ConsumerConfig.GROUP_ID_CONFIG, groupId);
        props.put(ConsumerConfig.GROUP_INSTANCE_ID_CONFIG, "pharmacy-instance-1");
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        props.put(
                ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

        this.consumer = new KafkaConsumer<>(props);
        this.subscribedTopics.addAll(topics);
        logger.info(String.format("Consumer subscribes to : %s", topics));
        consumer.subscribe(subscribedTopics);
        topics.forEach(topic -> subscribers.put(topic, new ArrayList<>()));
    }

    public void addSubscriber(String topic, KafkaSubscriber subscriber) {
        if (!subscribedTopics.contains(topic))
            throw new IllegalArgumentException(String.format("topic NOT found %s", topic));
        subscribers.get(topic).add(subscriber);
    }

    public synchronized void addTopic(String topic) {
        subscribedTopics.add(topic);
        consumer.subscribe(subscribedTopics);
        subscribers.put(topic, new ArrayList<>());
        logger.info("[Consumer] Added topic: " + topic);
    }

    public synchronized void removeTopic(String topic) {
        subscribedTopics.remove(topic);
        consumer.subscribe(subscribedTopics);
        subscribers.remove(topic);
        logger.info("[Consumer] Removed topic: " + topic);
    }

    public Set<String> getSubscribedTopics() {
        return Collections.unmodifiableSet(subscribedTopics);
    }

    @Override
    public void run() {
        logger.info("[Consumer] Listening on topics: " + subscribedTopics);
        while (running) {
            ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(500));
            for (ConsumerRecord<String, String> record : records) {
                String msg =
                        String.format(
                                "Kafka client receives message [%s] [%s] %s",
                                record.topic(), record.key(), record.value());
                logger.info(msg);
                MessageWebSocket.broadcast(msg);
                List<KafkaSubscriber> receivers = subscribers.get(record.topic());
                receivers.forEach(
                        receiver ->
                                receiver.onMessage(record.topic(), record.key(), record.value()));
            }
        }
        consumer.close();
    }

    public void shutdown() {
        running = false;
    }
}
