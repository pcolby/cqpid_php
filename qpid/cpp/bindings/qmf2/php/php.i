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

%module cqmf2

%include "std_string.i"

/* Include the PHP-specific SWIG typemaps */
%include "../../swig_php_typemaps.i"

/* Include our phpinfo support (same as the cqpid module for now) */
%include "../../qpid/php/phpinfo.i"

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
%rename("qmf_%s") "";
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

/* Rename some operators that would otherwise not be accessible to PHP */
%rename(copy)         operator=(const AgentEvent&);
%rename(copy)         operator=(const Agent&);
%rename(copy)         operator=(const AgentSession&);
%rename(copy)         operator=(const Console&);
%rename(copy)         operator=(const ConsoleEvent&);
%rename(copy)         operator=(const ConsoleSession&);
%rename(copy)         operator=(const DataAddr&);
%rename(is_equal)     operator==(const DataAddr&);
%rename(is_less_than) operator<(const DataAddr&);
%rename(copy)         operator=(const Data&);
%rename(copy)         operator=(const Query&);
%rename(copy)         operator=(const Schema&);
%rename(copy)         operator=(const SchemaId&);
%rename(copy)         operator=(const SchemaMethod&);
%rename(copy)         operator=(const SchemaProperty&);
%rename(copy)         operator=(const Subscription&);
//%rename(multiply)     operator*(const Duration& duration, uint64_t multiplier);
//%rename(multiply)     operator*(uint64_t multiplier,const Duration& duration);

// These two are already defined in cqpid, so no need to re-export.
%ignore operator*(const Duration& duration, uint64_t multiplier);
%ignore operator*(uint64_t multiplier,const Duration& duration);

/* Include the common QMF2 SWIG interface file */
%include "../qmf2.i"

// End of php.i
