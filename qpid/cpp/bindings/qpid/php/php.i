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

%module cqpid

%include "std_string.i"

/* Include the PHP-specific SWIG typemaps */
%include "../../swig_php_typemaps.i"

/* Include our phpinfo support */
%include "phpinfo.i"

/* Define the general-purpose exception handling */
%exception {
    try {
        $action
    } catch (const qpid::messaging::MessagingException &ex) {
        SWIG_exception(SWIG_RuntimeError, ex.what());
    }
}

/*
 * Apply a custom prefix to all SWIG-generated global functions.  This is not
 * only good practice, but is necessary for this module since without doing so
 * the Session::commit method would be exposed as session_commit which clashes
 * with the PHP built-in session_commit function preventing the PHP
 * interpreter from loading.
 *
 * See https://sourceforge.net/tracker/?func=detail&aid=3168551&group_id=1645&atid=351645
 * for more details.
 */
%rename("qpid_messaging_%s") "";
/*
 * Unfortunately the %rename directive above will result in the wrapper
 * classes also being prefixed, so for example the Connection class will become
 * qpid_messaging_Connection.  Thus we strip the prefix from wrapper class
 * names later in the build system.
 *
 * Alternatively, we could perform a narrow %rename of just functions, not
 * classes, such as: %rename("qpid_messagins_%s", %$isfunction) "";  However,
 * that will still result in some non-prefixed global functions, such as
 * new_Session and Session_copy, which can still cause conflicts with other
 * modules, causing PHP to fail to start.
 */

/*
 * Ignore some overloaded member functions for SWIG versions earlier than
 * SWIG 2.0.2 (or else SWIG would seg-fault). See SWIG artifact 3168531.
 */
#if SWIG_VERSION < 0x020002 // SWIG version < 2.0.2
%ignore qpid::messaging::Receiver::fetch       (Message&);
%ignore qpid::messaging::Receiver::fetch       (Message&,Duration);
%ignore qpid::messaging::Receiver::get         (Message&);
%ignore qpid::messaging::Receiver::get         (Message&,Duration);
%ignore qpid::messaging::Session ::nextReceiver(Receiver&);
%ignore qpid::messaging::Session ::nextReceiver(Receiver&,Duration);
#endif

/* Rename some operators that would otherwise not be accessible to PHP */
%rename(copy)     operator=(const Address&);
%rename(copy)     operator=(const Message&);
%rename(copy)     operator=(const Receiver&);
%rename(copy)     operator=(const Sender&);
%rename(copy)     operator=(const Session&);
%rename(copy)     operator=(const Connection&);
%rename(isEqual)    operator==(const Duration&, const Duration&);
%rename(isNotEqual) operator!=(const Duration&, const Duration&);
%rename(isValid)  operator bool() const;
%rename(isNull)   operator!() const;
%rename(multiply) operator*(const Duration& duration, uint64_t multiplier);
%rename(multiply) operator*(uint64_t multiplier,const Duration& duration);

/*
 * PHP has no concept of constant-variables, so the following methods will
 * never be used by SWIG/PHP (there are non-const versions which SWIG will
 * use instead).  Ignore them, just to avoid benign SWIG warnings.
 */
%ignore qpid::messaging::Address::getOptions()    const;
%ignore qpid::messaging::Message::getProperties() const;

/*
 * Define some global constants to make Duration a little easier to use (since
 * PHP does not support operator*).  We'll modify the generated cqpid.php
 * wrapper file to expose these as Duration class member constants too.
 */
%init {
    SWIG_LONG_CONSTANT(QPID_MESSAGING_DURATION_FOREVER,   qpid::messaging::Duration::FOREVER.getMilliseconds());
    SWIG_LONG_CONSTANT(QPID_MESSAGING_DURATION_IMMEDIATE, qpid::messaging::Duration::IMMEDIATE.getMilliseconds());
    SWIG_LONG_CONSTANT(QPID_MESSAGING_DURATION_SECOND,    qpid::messaging::Duration::SECOND.getMilliseconds());
    SWIG_LONG_CONSTANT(QPID_MESSAGING_DURATION_MINUTE,    qpid::messaging::Duration::MINUTE.getMilliseconds());
}

/* Include the common Qpid SWIG interface file */
%include <../qpid.i>

/* Define type-agnostic codec wrapper functions */
%pragma(php) code = %{

function encode($content, $message = null) {
    if ($message === null) {
        $message = new Message();
    }
    qpid_messaging_encode($content, $message);
    return $message;
}

function decode($message) {
    if ($message->getContentType() == "amqp/list") {
        return qpid_messaging_decodeList($message);
    } else {
        return qpid_messaging_decodeMap($message);
    }
}

%}

// End of php.i
