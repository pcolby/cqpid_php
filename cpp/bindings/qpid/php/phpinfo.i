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

/* Expose the SWIG_VERSION macro to C/C++ code */
%header {
    static const size_t __SWIG_VERSION__ = SWIG_VERSION;
}

/* Define our phpinfo print function */
%pragma(php) phpinfo = %{
    php_info_print_table_start();

    // TODO: Qpid Information.

    // SWIG Information.
    size_t swigVersions[3] = {
        __SWIG_VERSION__ >> 16,
        __SWIG_VERSION__ >> 8 & 0xFF,
        __SWIG_VERSION__ & 0xFF
    };
    std::stringstream swigVersion;
    swigVersion << swigVersions[0] << '.' << swigVersions[1] << '.' << swigVersions[2];
    php_info_print_table_row(2, "SWIG Version", swigVersion.str().c_str());

    // PHP Information.
    size_t phpVersions[3] = {
        PHP_VERSION_ID / 100 / 100,
        PHP_VERSION_ID / 100 % 100,
        PHP_VERSION_ID % 100
    };
    std::stringstream phpVersion;
    phpVersion << phpVersions[0] << '.' << phpVersions[1] << '.' << phpVersions[2]
               << " (" << PHP_VERSION << ')';
    php_info_print_table_row(2, "Targeted PHP Version", phpVersion.str().c_str());
#ifdef ZTS
    php_info_print_table_row(2, "PHP Thread Safety", "enabled");
#else
    php_info_print_table_row(2, "PHP Thread Safety", "disabled");
#endif

    // Compiler Information.
#ifdef __GNUC__
    std::stringstream gccVersion;
    gccVersion << "gcc " << __GNUC__;
#ifdef __GNUC_MINOR__
    gccVersion << '.' << __GNUC_MINOR__;
#ifdef __GNUC_PATCHLEVEL__
    gccVersion << '.' << __GNUC_PATCHLEVEL__;
#endif
#endif
    php_info_print_table_row(2, "Compiler Version", gccVersion.str().c_str());
#endif
    // TODO: Add other compiler types.

    // Other build information.
    php_info_print_table_row(2, "Build Date", __DATE__" "__TIME__);

    php_info_print_table_end();
%}

// End of phpinfo.i
