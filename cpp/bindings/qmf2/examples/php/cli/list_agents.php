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

require('cqpid.php');
require('cqmf2.php');

$url = $argc > 1 ? $argv[1] : 'localhost';
$connectionOptions = ($argc > 2) ? $argv[2] : '';
$sessionOptions = $argc > 3 ? $argv[3] : '';

try {
    $connection = new qpid\messaging\Connection($url, $connectionOptions);
    $connection->open();

    $session = new qmf\ConsoleSession($connection, $sessionOptions);
    $session->open();

    $session->setAgentFilter('');

    while (true) {
        $event = new qmf\ConsoleEvent;
        if ($session->nextEvent($event)) {
            if ($event->getType() == qmf\cqmf2::CONSOLE_AGENT_ADD) {
                $extra = '';
                if ($event->getAgent()->getName() == $session->getConnectedBrokerAgent()->getName())
                    $extra = '  [Connected Broker]';
                print 'Agent Added: ' . $event->getAgent()->getName() . $extra . "\n";
            }
            if ($event->getType() == qmf\cqmf2::CONSOLE_AGENT_DEL) {
                if ($event->getAgentDelReason() == qmf\cqmf2::AGENT_DEL_AGED)
                    print 'Agent Aged: ' . $event->getAgent()->getName() . "\n";
                else
                    print 'Agent Filtered: ' . $event->getAgent()->getName() . "\n";
            }
        }
    }
} catch (\Exception $error) {
    print $error->getMessage() . "\n";
    if (isset($connection)) {
        $connection->close();
    }
    exit(1);
}
?>
