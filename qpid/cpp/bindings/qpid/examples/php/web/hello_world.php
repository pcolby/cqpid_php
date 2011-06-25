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

function getIfSet($array, $key, $default=null) {
    return (isset($array[$key])) ? $array[$key] : $default;
}

if ((isset($_REQUEST['broker']))  &&
    (isset($_REQUEST['address'])) &&
    (isset($_REQUEST['messageContent'])))
{
    $connectionOptions = getIfSet($_REQUEST, 'connectionOptions', '');

    try {
        $connection = new Connection($_REQUEST['broker'], $connectionOptions);
        $connection->open();
        $session = $connection->createSession();

        $receiver = $session->createReceiver($_REQUEST['address']);
        $sender = $session->createSender($_REQUEST['address']);

        $sender->send(new Message($_REQUEST['messageContent']));

        $message = $receiver->fetch(new Duration(Duration::SECOND * 1));
        $content = $message->getContent();
        $session->acknowledge();

        $connection->close();
    } catch(\Exception $error) {
        if (isset($connection)) {
            $connection->close();
        }
        header("HTTP/1.0 500 Internal Server Error");
        $errorMessage = $error->getMessage();
    }
}

if ($success !== false) {
?>
<html>
 <body>
  <?php
      if (isset($errorMessage))
          print '<p style="color:red">' . htmlentities($errorMessage) . '</p><hr />';
  ?>
  <form>
   <table>
    <tr>
      <td><label for="broker">Broker:</label></td>
      <td><input id="broker" name="broker" type="text"
           value="<?php print getIfSet($_REQUEST, 'broker', 'localhost:5672'); ?>" />
      </td>
    </tr>
    <tr>
     <td><label for="address">Address:</label></td>
     <td><input id="address" name="address" type="text"
          value="<?php print getIfSet($_REQUEST, 'address', 'amq.topic'); ?>" />
     </td>
    </tr>
    <tr>
     <td><label for="connectionOptions">Connection options:</label></td>
     <td><input id="connectionOptions" name="connectionOptions" type="text"
          value="<?php print getIfSet($_REQUEST, 'connectionOptions'); ?>" />
     </td>
    </tr>
    <tr>
     <td><label for="messageContent">Message content:</label></td>
     <td><textarea id="messageContent" name="messageContent"><?php
          print getIfSet($_REQUEST, 'messageContent', 'Hello world!');
         ?></textarea>
     </td>
    </tr>
    <tr><td></td><td><input type="submit" /></td>
   </table>
  </form>
  <?php if (isset($content)) print '<hr /><p>' . htmlentities($content) . '</p>'; ?>
 </body>
</html>
<?php } ?>
