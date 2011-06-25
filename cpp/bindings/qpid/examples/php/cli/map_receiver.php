<?php
/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

namespace qpid\messaging;

require('cqpid.php');

$url = $argc>1 ? $argv[1] : 'amqp:tcp:127.0.0.1:5672';
$address = $argc>2 ? $argv[2] : 'message_queue; {create: always}';
$connectionOptions = $argc > 3 ? $argv[3] : '';

$connection = new Connection($url, $connectionOptions);
try {
    $connection->open();
    $session = $connection->createSession();
    $receiver = $session->createReceiver($address);
    $content = decode($receiver->fetch());
    print_r($content);
    $session->acknowledge();
    $receiver->close();
    $connection->close();
    exit(0);
} catch(\Exception $error) {
    print $error->getMessage() . "\n";
    $connection->close();
}
exit(1);
?>