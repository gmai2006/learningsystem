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

import jakarta.websocket.*;
import jakarta.websocket.server.ServerEndpoint;
import java.io.IOException;
import java.util.Set;
import java.util.concurrent.CopyOnWriteArraySet;
import java.util.logging.Logger;

/** Auto generated from a schema generated on $date$ */
@ServerEndpoint("/ws/messages")
public class MessageWebSocket {
    private static final Logger logger = Logger.getLogger(MessageWebSocket.class.getName());
    private static final Set<Session> sessions = new CopyOnWriteArraySet<>();

    @OnOpen
    public void onOpen(Session session) {
        sessions.add(session);
        System.out.println("WebSocket connected: " + session.getId());
    }

    @OnMessage
    public void onMessage(String message, Session session) throws IOException {
        logger.info("onMessage Received message from client: " + message);
        KafkaProducerService.sendMessage(KafkaTopic.Users.name(), "test", message);
    }

    @OnClose
    public void onClose(Session session) {
        sessions.remove(session);
    }

    @OnError
    public void onError(Session session, Throwable error) {
        logger.severe("WebSocket error: " + error.getMessage());
    }

    public static void broadcast(String message) {
        logger.info(String.format("Web socket broadcast: %s", message));
        sessions.forEach(
                session -> {
                    try {
                        session.getBasicRemote().sendText(message);
                        logger.info(String.format("sent the message %S", message));
                    } catch (IOException e) {
                        logger.severe(String.format("Cannot sent the message %S", message));
                    }
                });
    }
}
