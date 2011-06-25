#
# This is just a temporary Makefile to aide with early development,
# and should be discarded when the PHP binding is integrated into
# Qpid's build process.
#

SWIG = /usr/local/bin/swig
PHP_INCLUDES = $(shell php-config --includes)
PHP_INCLUDE_DIR = $(shell php-config --include-dir)
PHP_EXTENSION_DIR = $(shell php-config --extension-dir)

all: cqpid.so

cqpid.so: php.i
	$(SWIG) -c++ -php -I/usr/local/include -Wall -o cqpid.cpp php.i
	sed -i -e 's/\(qpid_messaging_\w*\)_qpid_messaging/\1/g' \
	       -e 's/zend_error_noreturn/zend_error/g' cqpid.cpp
	$(CXX) -fpic $(PHP_INCLUDES) -lqpidmessaging -o cqpid.so -shared cqpid.cpp
	sed -i -e 's/\(qpid_messaging_\w*\)_qpid_messaging/\1/g'     \
	       -e 's/\(class\|function\|new\) qpid_messaging_/\1 /g' \
	       -e 's/\(static function \(FOREVER\|IMMEDIATE\|SECOND\|MINUTE\)()\)/const \2 = QPID_MESSAGING_DURATION_\2; \1/' \
	       -e 's/^<?php/<?php namespace qpid\\messaging;/' cqpid.php

install:
	mkdir -p '$(PHP_INCLUDE_DIR)/ext/cqpid/'
	cp php_cqpid.h '$(PHP_INCLUDE_DIR)/ext/cqpid/'
	cp cqpid.so '$(PHP_EXTENSION_DIR)/'
	@echo 'Add the following line to your PHP configuration:'
	@echo 'extension=$(PHP_EXTENSION_DIR)/cqpid.so'
	# TODO: detect the following directory somehow.
	cp cqpid.php '/usr/share/php/'

clean:
	$(RM) cqpid.* php_cqpid.h
