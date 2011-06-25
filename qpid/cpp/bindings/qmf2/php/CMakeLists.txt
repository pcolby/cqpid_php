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
SET(SWIG_MODULE_cqmf2_php_EXTRA_DEPS ${CMAKE_CURRENT_SOURCE_DIR}/../qmf2.ini)
SET(SWIG_MODULE_cqmf2_php_EXTRA_DEPS ${CMAKE_CURRENT_SOURCE_DIR}/../../qpid/php/phpinfo.i)
SET(SWIG_MODULE_cqmf2_php_EXTRA_DEPS ${CMAKE_CURRENT_SOURCE_DIR}/../../swig_php_typemaps.i)

SWIG_ADD_MODULE(cqmf2_php php ${CMAKE_CURRENT_SOURCE_DIR}/php.i ${CMAKE_CURRENT_BINARY_DIR}/cqmf2_php_prebuild)
SWIG_LINK_LIBRARIES(cqmf2_php qmf2)

SET_SOURCE_FILES_PROPERTIES(
  ${swig_generated_file_fullname} PROPERTIES COMPILE_FLAGS "${PHP_INCLUDES} ${QPID_INCLUDES}"
)

##----------------------------------------------------------------------
## Cleanup some of the global indentifiers in the generated C++ code and
## replace the deprecated zend_noreturn (if present) with zend_error
##----------------------------------------------------------------------
ADD_CUSTOM_COMMAND(
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/cqmf2_php_prebuild
  COMMAND sed -i -e "s/\\\\\\(qmf_\\\\w*\\\\\\)_qmf/\\\\1/g"
                 -e "s/zend_error_noreturn/zend_error/g" ${swig_generated_file_fullname}
  COMMAND touch cqmf2_php_prebuild
  DEPENDS ${swig_generated_file_fullname}
)

##--------------------------------------------------------------
## Cleanup some of the indentifiers in the generated PHP wrapper
##--------------------------------------------------------------
ADD_CUSTOM_COMMAND(
  TARGET ${SWIG_MODULE_cqmf2_php_REAL_NAME}
  POST_BUILD
  COMMAND
    sed -i -e "s/\\\\\\(qmf_\\\\w*\\\\\\)_qmf/\\\\1/g"
           -e "s/\\\\\\(class\\\\\\|extends\\\\\\|function\\\\\\|new\\\\\\) qmf_/\\\\1 /g"
           -e "s/const qmf_/const /g"
        ${CMAKE_CURRENT_BINARY_DIR}/cqmf2.php
  DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/cqmf2.php
)

##----------------------------------------------------------------
## If PHP 5.3+ add the qpid\messaging namespace to the PHP wrapper
##----------------------------------------------------------------
if (PHP_VERNUM LESS 50300)
  # do nothing.
else (PHP_VERSION >= 50300)
  ADD_CUSTOM_COMMAND(
    TARGET ${SWIG_MODULE_cqmf2_php_REAL_NAME}
    POST_BUILD
    COMMAND sed -i -e "s/^\\<?php/\\<?php namespace qmf\;/" ${CMAKE_CURRENT_BINARY_DIR}/cqmf2.php
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/cqmf2.php
  )
endif (PHP_VERNUM LESS 50300)

##------------------------------
## Generate a basic PHP INI file
##------------------------------
FILE(
  WRITE ${CMAKE_CURRENT_SOURCE_DIR}/cqmf2.ini
    "; configuration for PHP QMF2 module\nextension=${PHP_EXTENSION_DIR}/cqmf2${CMAKE_SHARED_LIBRARY_SUFFIX}\n"
)

##-------------------------------
## Install the dynamic PHP module
##-------------------------------
GET_TARGET_PROPERTY(PHP_SHARED_LIBRARY_LOCATION ${SWIG_MODULE_cqmf2_php_REAL_NAME} LOCATION)
INSTALL(
  FILES ${PHP_SHARED_LIBRARY_LOCATION}
  RENAME cqmf2${CMAKE_SHARED_LIBRARY_SUFFIX}
  DESTINATION ${PHP_EXTENSION_DIR}
  COMPONENT ${QPID_COMPONENT_CLIENT}
)

##-------------------------------
## Install the basic PHP INI file
##-------------------------------
INSTALL(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/cqmf2.ini
  DESTINATION ${PHP_CONFIG_DIR}
  COMPONENT ${QPID_COMPONENT_CLIENT}
)

##--------------------------------------
## Install the static PHP extension code
##--------------------------------------
INSTALL(
  FILES ${swig_generated_file_fullname}
  DESTINATION ${PHP_INCLUDE_DIR}/ext/qpid
  RENAME cqmf2.cpp
  COMPONENT ${QPID_COMPONENT_CLIENT}
)
INSTALL(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/php_cqmf2.h
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
      FILES ${CMAKE_CURRENT_BINARY_DIR}/cqmf2.php
      DESTINATION ${PHP_WRAPPER_DIR}
      COMPONENT ${QPID_COMPONENT_CLIENT}
    )
  endif (PHP_WRAPPER_DIR)
endif (PHP_EXECUTABLE)