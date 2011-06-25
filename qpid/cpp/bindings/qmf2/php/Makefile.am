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

PHP_INI_FILE = cqmf2.ini
EXTRA_DIST = php.i cqmf2.php $(PHP_INI_FILE)
SWIG_OUTPUT = cqmf2.cpp cqmf2.php php_cqmf2.h
SWIG_FLAGS = -w401
PHP_QPID_VERSION = -DPHP_QPID_VERSION='"$(VERSION)"'


$(SWIG_OUTPUT): $(srcdir)/php.i $(srcdir)/../../qpid/php/phpinfo.i $(srcdir)/../qmf2.i $(srcdir)/../../swig_php_typemaps.i
	$(SWIG) -c++ -php $(SWIG_FLAGS) $(INCLUDES) $(QPID_CXXFLAGS) -o cqmf2.cpp $(srcdir)/php.i
	$(SED) -i -e 's/\(qmf_\w*\)_qmf/\1/g' \
	          -e 's/zend_error_noreturn/zend_error/g' cqmf2.cpp
	$(SED) -i -e 's/\(qmf_\w*\)_qmf/\1/g' \
	          -e 's/\(class\|extends\|function\|new\) qmf_/\1 /g' \
	          -e 's/const qmf_/const /g' \
		cqmf2.php
	if test $(PHP_VERSION) -ge 50300; then \
		$(SED) -i -e 's/^<?php/<?php namespace qmf;/' cqmf2.php; \
	fi

$(PHP_INI_FILE): cqmf2.la
	echo '; configuration for PHP QMF2 module' > $(PHP_INI_FILE)
	echo "extension=$(PHP_EXTENSION_DIR)/"`$(SED) -ne "s/^dlname='\(.*\)'/\1/p" cqmf2.la` >> $(PHP_INI_FILE)

if HAVE_PHP_DYNAMIC_INSTALL
phplibarchdir = $(PHP_EXTENSION_DIR)
phplibarch_LTLIBRARIES = cqmf2.la
cqmf2_la_LDFLAGS = -avoid-version -module -shared
cqmf2_la_LIBADD = -L$(top_builddir)/src/.libs $(top_builddir)/src/libqmf2.la
cqmf2_la_CXXFLAGS = -fpic $(INCLUDES) $(PHP_DEV_INCLUDES) $(PHP_QPID_VERSION)
nodist_cqmf2_la_SOURCES = cqmf2.cpp
cqmf2_confdir = $(PHP_CONFIG_DIR)
cqmf2_conf_DATA = $(PHP_INI_FILE)
endif

if HAVE_PHP_STATIC_INSTALL
cqmf2_staticdir = $(PHP_INCLUDE_DIR)/ext/qpid
cqmf2_static_DATA = cqmf2.cpp
cqmf2_static_HEADERS = php_cqmf2.h
endif

if HAVE_PHP_WRAPPER_INSTALL
cqmf2_wrapperdir = $(PHP_WRAPPER_DIR)
cqmf2_wrapper_DATA = cqmf2.php
endif

CLEANFILES = $(SWIG_OUTPUT) $(PHP_INI_FILE)

endif # HAVE_PHP_DEVEL
