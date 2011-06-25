#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

if HAVE_PHP_DEVEL

INCLUDES = -I$(top_srcdir)/include -I$(top_builddir)/include

PHP_INI_FILE = cqpid.ini
EXTRA_DIST = php.i phpinfo.i cqpid.php $(PHP_INI_FILE)
SWIG_OUTPUT = cqpid.cpp cqpid.php php_cqpid.h
SWIG_FLAGS = -w401
PHP_QPID_VERSION = -DPHP_QPID_VERSION='"$(VERSION)"'

$(SWIG_OUTPUT): $(srcdir)/php.i $(srcdir)/phpinfo.i $(srcdir)/../qpid.i $(srcdir)/../../swig_php_typemaps.i
	$(SWIG) -c++ -php $(SWIG_FLAGS) $(INCLUDES) $(QPID_CXXFLAGS) -o cqpid.cpp $(srcdir)/php.i
	$(SED) -i -e 's/\(qpid_messaging_\w*\)_qpid_messaging/\1/g' \
	          -e 's/zend_error_noreturn/zend_error/g' cqpid.cpp
	$(SED) -i -e 's/\(qpid_messaging_\w*\)_qpid_messaging/\1/g' \
	          -e 's/\(class\|extends\|function\|new\) qpid_messaging_/\1 /g' \
	          -e 's/\(static function \(FOREVER\|IMMEDIATE\|SECOND\|MINUTE\)()\)/const \2 = QPID_MESSAGING_DURATION_\2; \1/' \
		cqpid.php
	if test $(PHP_VERSION) -ge 50300; then \
		$(SED) -i -e 's/^<?php/<?php namespace qpid\\messaging;/' cqpid.php; \
	fi

$(PHP_INI_FILE): cqpid.la
	echo '; configuration for PHP Qpid module' > $(PHP_INI_FILE)
	echo "extension=$(PHP_EXTENSION_DIR)/"`$(SED) -ne "s/^dlname='\(.*\)'/\1/p" cqpid.la` >> $(PHP_INI_FILE)

if HAVE_PHP_DYNAMIC_INSTALL
phplibarchdir = $(PHP_EXTENSION_DIR)
phplibarch_LTLIBRARIES = cqpid.la
cqpid_la_LDFLAGS = -avoid-version -module -shared
cqpid_la_LIBADD = -L$(top_builddir)/src/.libs -lqpidmessaging -lqpidtypes \
	$(top_builddir)/src/libqpidmessaging.la $(top_builddir)/src/libqpidtypes.la
cqpid_la_CXXFLAGS = -fpic $(INCLUDES) $(PHP_DEV_INCLUDES) $(PHP_QPID_VERSION)
nodist_cqpid_la_SOURCES = cqpid.cpp
cqpid_confdir = $(PHP_CONFIG_DIR)
cqpid_conf_DATA = $(PHP_INI_FILE)
endif

if HAVE_PHP_STATIC_INSTALL
cqpid_staticdir = $(PHP_INCLUDE_DIR)/ext/qpid
cqpid_static_DATA = cqpid.cpp
cqpid_static_HEADERS = php_cqpid.h
endif

if HAVE_PHP_WRAPPER_INSTALL
cqpid_wrapperdir = $(PHP_WRAPPER_DIR)
cqpid_wrapper_DATA = cqpid.php
endif

CLEANFILES = $(SWIG_OUTPUT) $(PHP_INI_FILE)

endif # HAVE_PHP_DEVEL
