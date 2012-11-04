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

##------------------------------------------------------
## Use Swig to generate a literal binding to the C++ API
##------------------------------------------------------
SET(CMAKE_SWIG_FLAGS "-w401")
SET(QPID_INCLUDES "-I${qpid-cpp_SOURCE_DIR}/include")
SET_SOURCE_FILES_PROPERTIES(${CMAKE_CURRENT_SOURCE_DIR}/php.i PROPERTIES CPLUSPLUS ON)
SET_SOURCE_FILES_PROPERTIES(${CMAKE_CURRENT_SOURCE_DIR}/php.i PROPERTIES SWIG_FLAGS "${QPID_INCLUDES}")
SET(SWIG_MODULE_cqpid_php_EXTRA_DEPS ${CMAKE_CURRENT_SOURCE_DIR}/phpinfo.i)
SET(SWIG_MODULE_cqpid_php_EXTRA_DEPS ${CMAKE_CURRENT_SOURCE_DIR}/../../swig_php_typemaps.i)

SWIG_ADD_MODULE(cqpid_php php ${CMAKE_CURRENT_SOURCE_DIR}/php.i ${CMAKE_CURRENT_BINARY_DIR}/cqpid_php_prebuild)
SWIG_LINK_LIBRARIES(cqpid_php qpidmessaging qpidtypes)

SET_SOURCE_FILES_PROPERTIES(
  ${swig_generated_file_fullname} PROPERTIES COMPILE_FLAGS "${PHP_INCLUDES} ${QPID_INCLUDES}"
)

##----------------------------------------------------------------------
## Cleanup some of the global indentifiers in the generated C++ code and
## replace the deprecated zend_noreturn (if present) with zend_error
##----------------------------------------------------------------------
ADD_CUSTOM_COMMAND(
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/cqpid_php_prebuild
  COMMAND sed -i -e "s/\\\\\\(qpid_messaging_\\\\w*\\\\\\)_qpid_messaging/\\\\1/g"
                 -e "s/zend_error_noreturn/zend_error/g" ${swig_generated_file_fullname}
  COMMAND touch cqpid_php_prebuild
  DEPENDS ${swig_generated_file_fullname}
)

##--------------------------------------------------------------
## Cleanup some of the indentifiers in the generated PHP wrapper
##--------------------------------------------------------------
ADD_CUSTOM_COMMAND(
  TARGET ${SWIG_MODULE_cqpid_php_REAL_NAME}
  POST_BUILD
  COMMAND
    sed -i -e "s/\\\\\\(qpid_messaging_\\\\w*\\\\\\)_qpid_messaging/\\\\1/g"
           -e "s/\\\\\\(class\\\\\\|extends\\\\\\|function\\\\\\|new\\\\\\) qpid_messaging_/\\\\1 /g"
           -e "s/^\\\\\\(\\\\s*\\\\\\)\\\\\\(static function \\\\\\(FOREVER\\\\\\|IMMEDIATE\\\\\\|SECOND\\\\\\|MINUTE\\\\\\)\\(\\)\\\\\\)/\\\\1const \\\\3 = QPID_MESSAGING_DURATION_\\\\3\; \\\\2/"
        ${CMAKE_CURRENT_BINARY_DIR}/cqpid.php
  DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/cqpid.php
)

##----------------------------------------------------------------
## If PHP 5.3+ add the qpid\messaging namespace to the PHP wrapper
##----------------------------------------------------------------
if (PHP_VERNUM LESS 50300)
  # do nothing.
else (PHP_VERSION >= 50300)
  ADD_CUSTOM_COMMAND(
    TARGET ${SWIG_MODULE_cqpid_php_REAL_NAME}
    POST_BUILD
    COMMAND sed -i -e "s/^\\<?php/\\<?php namespace qpid\\\\\\\\messaging\;/" ${CMAKE_CURRENT_BINARY_DIR}/cqpid.php
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/cqpid.php
  )
endif (PHP_VERNUM LESS 50300)

##------------------------------
## Generate a basic PHP INI file
##------------------------------
FILE(
  WRITE ${CMAKE_CURRENT_BINARY_DIR}/cqpid.ini
    "; configuration for PHP Qpid module\nextension=${PHP_EXTENSION_DIR}/cqpid${CMAKE_SHARED_LIBRARY_SUFFIX}\n"
)

##-------------------------------
## Install the dynamic PHP module
##-------------------------------
GET_TARGET_PROPERTY(PHP_SHARED_LIBRARY_LOCATION ${SWIG_MODULE_cqpid_php_REAL_NAME} LOCATION)
INSTALL(
  FILES ${PHP_SHARED_LIBRARY_LOCATION}
  RENAME cqpid${CMAKE_SHARED_LIBRARY_SUFFIX}
  DESTINATION ${PHP_EXTENSION_DIR}
  COMPONENT ${QPID_COMPONENT_CLIENT}
)

##-------------------------------
## Install the basic PHP INI file
##-------------------------------
INSTALL(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/cqpid.ini
  DESTINATION ${PHP_CONFIG_DIR}
  COMPONENT ${QPID_COMPONENT_CLIENT}
)

##--------------------------------------
## Install the static PHP extension code
##--------------------------------------
INSTALL(
  FILES ${swig_generated_file_fullname}
  DESTINATION ${PHP_INCLUDE_DIR}/ext/qpid
  RENAME cqpid.cpp
  COMPONENT ${QPID_COMPONENT_CLIENT}
)
INSTALL(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/php_cqpid.h
  DESTINATION ${PHP_INCLUDE_DIR}/ext/qpid
  COMPONENT ${QPID_COMPONENT_CLIENT}
)

##-----------------------------------------
## Optionally install the PHP class wrapper
##-----------------------------------------
if (PHP_EXECUTABLE)
  execute_process(
    COMMAND
      ${PHP_EXECUTABLE} -r "print get_include_path();"
    COMMAND
      sed -ne "s/\\(\\.:\\)\\?\\(\\/[^:]*\\).*/\\2/p"
      OUTPUT_VARIABLE PHP_WRAPPER_DIR
  )

  if (PHP_WRAPPER_DIR)
    INSTALL(
      FILES ${CMAKE_CURRENT_BINARY_DIR}/cqpid.php
      DESTINATION ${PHP_WRAPPER_DIR}
      COMPONENT ${QPID_COMPONENT_CLIENT}
    )
  endif (PHP_WRAPPER_DIR)
endif (PHP_EXECUTABLE)