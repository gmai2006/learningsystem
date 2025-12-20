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
package com.ewu.career.util;

import com.typesafe.config.Config;
import com.typesafe.config.ConfigFactory;

/** Auto generated from a schema generated on $date$ */
public class ConfigManager {
    private static Config config;
    public static String KAFKA = "kafka";
    public static String PRODUCER = "producer";
    public static String CONSUMER = "consumer";
    public static String BOOTSTRAP = "bootstrap";
    public static String OKTA = "okta";

    public static synchronized Config getConfig() {
        if (null == config) {
            config = ConfigFactory.parseResources("app.conf");
        }
        return config;
    }

    public static synchronized Config getKafkaProducer() {
        return getConfig().getConfig(KAFKA).getConfig(PRODUCER);
    }

    public static synchronized Config getKafkaConsumer() {
        return getConfig().getConfig(KAFKA).getConfig(CONSUMER);
    }

    public static synchronized Config getOkta() {
        return getConfig().getConfig(OKTA);
    }
}
