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

import com.ewu.career.util.ConfigManager;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import jakarta.ejb.Singleton;
import jakarta.ejb.Startup;
import java.util.Arrays;
import java.util.logging.Logger;

@Singleton
@Startup
public class NotificationServiceStartup {
    private final Logger logger = Logger.getLogger(this.getClass().getName());
    private KafkaConsumerService consumer;
    private Thread consumerThread;

    @PostConstruct
    public void startup() {
        if (ConfigManager.getConfig().hasPath(ConfigManager.KAFKA)) {
            logger.info(
                    String.format(
                            "Notification starts at %s",
                            ConfigManager.getKafkaProducer().getString(ConfigManager.BOOTSTRAP)));

            consumer =
                    new KafkaConsumerService(
                            ConfigManager.getKafkaProducer().getString(ConfigManager.BOOTSTRAP),
                            Arrays.stream(KafkaTopic.values()).map(KafkaTopic::name).toList(),
                            ConfigManager.getKafkaConsumer().getString("name"));
            consumerThread = new Thread(consumer, "kafka-learning-consumer");
            consumerThread.start();
            logger.info("Kafka consumer started.");
        }
    }

    @PreDestroy
    public void shutdown() {
        if (ConfigManager.getConfig().hasPath(ConfigManager.KAFKA)) {
            consumer.shutdown();
            consumerThread.interrupt();
            KafkaProducerService.close();
            logger.info("Kafka consumer started.");
        }
    }
}
