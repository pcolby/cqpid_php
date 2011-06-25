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

%wrapper %{
    #include <limits>
    #include <sstream>
    #include <qpid/types/Variant.h>

    /*
     * Functions for converting from PHP values to Qpid Variants.
     */

    void listToZval(zval * const output, const qpid::types::Variant::List * const list TSRMLS_DC);
    void mapToZval (zval * const output, const qpid::types::Variant::Map  * const map  TSRMLS_DC);

    /*
     * This macro is used to simplify the variantToZval function below by
     * selecting the right PHP array-add function.
     */
    #define ADD_TO_ARRAY(type, ...) {                                      \
        if (key == NULL)                                                   \
            add_next_index_##type(output , ##__VA_ARGS__);                 \
        else if (keyLength == (uint)-1)                                    \
            add_assoc_##type(output, key , ##__VA_ARGS__);                 \
        else                                                               \
            add_assoc_##type##_ex(output, key, keyLength , ##__VA_ARGS__); \
    }

    /*
     * This macro is used to simplify the variantToZval function below, by
     * abstracting away the choice between setting a PHP value directly, or
     * adding the value to an existing PHP array instead.
     */
    #define SET_OR_ADD(TYPE, type, ...)          \
        if (add) {                               \
            ADD_TO_ARRAY(type, ##__VA_ARGS__);   \
        } else {                                 \
            ZVAL_##TYPE(output , ##__VA_ARGS__); \
        }

    // Convert a Qpid Variant to a PHP value.
    void variantToZval(
        zval * const output,
        const qpid::types::Variant * const variant
        TSRMLS_DC,                      // Zend thread-safety arguments.
        const bool add = false,         // Is output an array we should add to?
        const char *key = NULL,         // If non-NULL, the associative array key.
        const uint keyLength = (uint)-1 // If non-default, the length of key.
    ) {
        switch (variant->getType()) {
            case qpid::types::VAR_VOID:
                SET_OR_ADD(NULL, null);
                break;
            case qpid::types::VAR_BOOL:
                SET_OR_ADD(BOOL, bool, variant->asBool());
                break;
            case qpid::types::VAR_UINT8:
            case qpid::types::VAR_UINT16:
            case qpid::types::VAR_UINT32:
            case qpid::types::VAR_UINT64: {
                    const uint64_t value = variant->asUint64();
                    if (value > LONG_MAX) {
                        SWIG_exception(SWIG_OverflowError, "unsigned integer too large for PHP");
                        return;
                    }
                    SET_OR_ADD(LONG, long, (long)value);
                }
                break;
            case qpid::types::VAR_INT8:
            case qpid::types::VAR_INT16:
            case qpid::types::VAR_INT32:
            case qpid::types::VAR_INT64: {
                    const int64_t value = variant->asInt64();
                    if ((value < LONG_MIN) || (value > LONG_MAX)) {
                        SWIG_exception(SWIG_OverflowError, "integer too large for PHP");
                        return;
                    }
                    SET_OR_ADD(LONG, long, (long)value);
                }
                break;
            case qpid::types::VAR_FLOAT:
            case qpid::types::VAR_DOUBLE:
                SET_OR_ADD(DOUBLE, double, variant->asDouble());
                break;
            case qpid::types::VAR_STRING: {
                    std::string value = variant->asString();
                    SET_OR_ADD(STRINGL, stringl, const_cast<char *>(value.c_str()), value.size(), 1);
                }
                break;
            case qpid::types::VAR_LIST: {
                    qpid::types::Variant::List list = variant->asList();
                    if (add) {
                        zval *array;
                        ALLOC_INIT_ZVAL(array);
                        listToZval(array, &list TSRMLS_CC);
                        ADD_TO_ARRAY(zval, array);
                    } else {
                        listToZval(output, &list TSRMLS_CC);
                    }
                }
                break;
            case qpid::types::VAR_MAP: {
                    qpid::types::Variant::Map map = variant->asMap();
                    if (add) {
                        zval *array;
                        ALLOC_INIT_ZVAL(array);
                        mapToZval(array, &map TSRMLS_CC);
                        ADD_TO_ARRAY(zval, array);
                    } else {
                        mapToZval(output, &map TSRMLS_CC);
                    }
                }
                break;
            case qpid::types::VAR_UUID: {
                    std::string value = variant->asUuid().str();
                    SET_OR_ADD(STRINGL, stringl, const_cast<char *>(value.c_str()), value.size(), 1);
                }
                break;
            default: // Should never happen.
                SWIG_exception(SWIG_TypeError, "invalid variant type");
        }
    }

    // Convert a Qpid Variant::List to a PHP value.
    void listToZval(zval * const output, const qpid::types::Variant::List * const list TSRMLS_DC) {
        array_init(output);
        for (qpid::types::Variant::List::const_iterator iter = list->begin(); iter != list->end(); iter++) {
            variantToZval(output, &*iter TSRMLS_CC, true);
        }
    }

    // Convert a Qpid Variant::Map to a PHP value.
    void mapToZval(zval * const output, const qpid::types::Variant::Map * const map TSRMLS_DC) {
        array_init(output);
        for (qpid::types::Variant::Map::const_iterator iter = map->begin(); iter != map->end(); iter++) {
            variantToZval(output, &iter->second TSRMLS_CC, true, iter->first.c_str(), iter->first.size()+1);
        }
    }

    // Overloaded required by QMF2 only.
    void mapToZval(zval * const output, const qpid::types::Variant::Map &map TSRMLS_DC) {
        mapToZval(output, &map TSRMLS_CC);
    }

    /*
     * Functions for converting from Qpid Variants to PHP variables.
     */

    qpid::types::Variant zvalToVariant(zval ** const input TSRMLS_DC);

    // Convert a PHP array value to a Qpid Variant::List.
    qpid::types::Variant::List zvalToList(zval ** const input TSRMLS_DC) {
        qpid::types::Variant::List list;
        HashTable *hashTable = Z_ARRVAL_PP(input);
        HashPosition hashPosition;
        zval **data;
        for (zend_hash_internal_pointer_reset_ex(hashTable, &hashPosition);
             zend_hash_get_current_data_ex(hashTable, (void**)&data, &hashPosition) == SUCCESS;
             zend_hash_move_forward_ex(hashTable, &hashPosition))
        {
            list.push_back(zvalToVariant(data TSRMLS_CC));
        }
        return list;
    }

    // Convert a PHP hash table key to a std::string.
    std::string zvalArrayKey(HashTable *hashTable, HashPosition *hashPosition TSRMLS_DC) {
        char *key = NULL;
        uint keyLength = 0;
        ulong index;
        const int type = zend_hash_get_current_key_ex(hashTable, &key, &keyLength, &index, 0, hashPosition);
        switch (type) {
            case HASH_KEY_IS_STRING:
                return std::string(key, keyLength-1);
            case HASH_KEY_IS_LONG: {
                    std::stringstream stream;
                    stream << index;
                    return stream.str();
                }
            case HASH_KEY_NON_EXISTANT:
                SWIG_exception(SWIG_TypeError, "non-existant hash key");
                return std::string();
            default: // Should never happen.
                SWIG_exception(SWIG_TypeError, "unknown hash key type");
                return std::string();
        }
    }

    // Convert a PHP hash table to a Qpid Variant::Map.
    qpid::types::Variant::Map zvalToMap(HashTable * const hashTable TSRMLS_DC) {
        qpid::types::Variant::Map map;
        HashPosition hashPosition;
        zval **data;
        for (zend_hash_internal_pointer_reset_ex(hashTable, &hashPosition);
             zend_hash_get_current_data_ex(hashTable, (void**)&data, &hashPosition) == SUCCESS;
             zend_hash_move_forward_ex(hashTable, &hashPosition))
        {
            const std::string key = zvalArrayKey(hashTable, &hashPosition TSRMLS_CC);
            map[key] = zvalToVariant(data TSRMLS_CC);
        }
        return map;
    }

    // Convert a PHP array value to a Qpid Variant::Map.
    qpid::types::Variant::Map zvalToMap(zval ** const input TSRMLS_DC) {
        HashTable *hashTable = Z_ARRVAL_PP(input);
        return zvalToMap(hashTable TSRMLS_CC);
    }

   /*
    * Determine if a PHP array should be converted to a Qpid Variant::List
    * in preference to converting to a Qpid Variant::Map instead.
    *
    * We consider a PHP array to be a "list" if the following are both true:
    *   1. the array has no string keys.
    *   2. all indexes are contiguous, and begin at 0.
    *
    * If either of these conditions are not met, then conversion to a List
    * (which is still possible, and supported), would result in array key
    * data loss, making List conversion non-preferable (ie conversion to Map
    * would be better).
    */
   bool isZvalList(zval ** const input) {
        // Make sure input is a PHP array.
        if ((Z_TYPE_PP(input) != IS_ARRAY) && (Z_TYPE_PP(input) != IS_CONSTANT_ARRAY))
            return false; // input is not a "map".

        // Make sure all of the array elements have a valid key.
        HashTable *hashTable = Z_ARRVAL_PP(input);
        HashPosition hashPosition;
        zval **data;
        ulong count;
        for (zend_hash_internal_pointer_reset_ex(hashTable, &hashPosition), count = 0;
             zend_hash_get_current_data_ex(hashTable, (void**)&data, &hashPosition) == SUCCESS;
             zend_hash_move_forward_ex(hashTable, &hashPosition), count++)
        {
            char *key = NULL;
            uint keyLength = 0;
            ulong index;
            if (zend_hash_get_current_key_ex(hashTable, &key, &keyLength, &index, 0, &hashPosition) != HASH_KEY_IS_LONG)
                return false; // The current element has a key string (or is invalid), so it's not a "list".
            else if (index != count)
                return false; // input has non-contiguous indexes.
        }
        return true;
    }

    // Convert a PHP value to a Qpid Variant.
    qpid::types::Variant zvalToVariant(zval ** const input TSRMLS_DC) {
        switch (Z_TYPE_PP(input)) {
            case IS_ARRAY:
            case IS_CONSTANT_ARRAY:
                if (isZvalList(input)) {
                    return zvalToList(input TSRMLS_CC);
                } else {
                    return zvalToMap(input TSRMLS_CC);
                }
            case IS_BOOL:
                return Z_BVAL_PP(input) ? true : false;
            case IS_DOUBLE:
                return Z_DVAL_PP(input);
            case IS_LONG: {
                    const int64_t value = Z_LVAL_PP(input);
                    if (value < 0) {
                        if (value >= std::numeric_limits<int8_t>::min())
                            return (int8_t)value;
                        if (value >= std::numeric_limits<int16_t>::min())
                            return (int16_t)value;
                        if (value >= std::numeric_limits<int32_t>::min())
                            return (int32_t)value;
                        return (int64_t)value;
                    } else {
                        if (value <= std::numeric_limits<uint8_t>::max())
                            return (uint8_t)value;
                        if (value <= std::numeric_limits<uint16_t>::max())
                            return (uint16_t)value;
                        if (value <= std::numeric_limits<uint32_t>::max())
                            return (uint32_t)value;
                        return (uint64_t)value;
                    }
                }
            case IS_NULL:
                return NULL;
            case IS_OBJECT: {
                    // Mimic var_dump's object serialisation.
                    char *className;
                    zend_uint classNameLength;
                    const int copyNeeded = zend_get_object_classname(*input, &className, &classNameLength TSRMLS_CC);
                    const std::string key = "object(" + std::string(className, classNameLength) + ')';
                    if (!copyNeeded) {
                        efree(className);
                    }
                    qpid::types::Variant::Map map;
                    map[key] = zvalToMap(Z_OBJPROP_PP(input) TSRMLS_CC);
                    return map;
                }
            case IS_RESOURCE: {
                    // Mimic var_dump's resource display; eg  "resource (10) of type (stream)".
                    char * const type = zend_rsrc_list_get_rsrc_type(Z_LVAL_PP(input) TSRMLS_CC);
                    std::stringstream stream;
                    stream << "resource(" << Z_LVAL_PP(input) << ") of type (" << type << ')';
                    return stream.str();
                }
            case IS_STRING:
            case IS_CONSTANT:
                return std::string(Z_STRVAL_PP(input), Z_STRLEN_PP(input));
            default:
                SWIG_exception(SWIG_TypeError, "unknown PHP type");
        }
    }

%}

/*
 * Apply SWIG's existing integer typemaps to our explicit width types.
 */

%apply int                {   int8_t,  int16_t,  int32_t };
%apply unsigned int       {  uint8_t, uint16_t, uint32_t };

#ifdef long long
%apply long long          {  int64_t                     };
#else
%apply int                {  int64_t                     };
#endif

#ifdef unsigned long long
%apply unsigned long long { uint64_t                     };
#else
%apply unsigned int       { uint64_t                     };
#endif

/*
 * Map Qpid Variants to PHP values.
 */

%typemap(out) qpid::types::Variant::Map {
    mapToZval($result, $1 TSRMLS_CC);
}

%typemap(out) qpid::types::Variant::Map& {
    mapToZval($result, $1 TSRMLS_CC);
}

%typemap(out) qpid::types::Variant::List {
    listToZval($result, $1 TSRMLS_CC);
}

%typemap(out) qpid::types::Variant::List& {
    listToZval(return_value, $1 TSRMLS_CC);
}

%typemap(out) qpid::types::Variant {
    variantToZval($result, $1 TSRMLS_CC);
}

%typemap(out) qpid::types::Variant& {
    variantToZval($result, $1 TSRMLS_CC);
}

/*
 * Map PHP values to Qpid Variants.
 */

%typemap(in) qpid::types::Variant &,
             const qpid::types::Variant const &
{
    $1 = new qpid::types::Variant(zvalToVariant($input TSRMLS_CC));
}

%typemap(in) qpid::types::Variant::List &,
             const qpid::types::Variant::List const &
{
    $1 = new qpid::types::Variant::List(zvalToList($input TSRMLS_CC));
}

%typemap(in) qpid::types::Variant::Map &,
             const qpid::types::Variant::Map const &
{
    $1 = new qpid::types::Variant::Map(zvalToMap($input TSRMLS_CC));
}

%typemap(freearg) qpid::types::Variant & {
    delete $1;
}

%typemap(freearg) qpid::types::Variant::Map & {
    delete $1;
}

%typemap(freearg) qpid::types::Variant::List & {
    delete $1;
}

/*
 * Integer typechecks.
 */

%define %php_typecheck_range(_type,_prec)
%typemap(typecheck,precedence=_prec) _type, const _type &
"    $1 = ((Z_TYPE_PP($input) == IS_LONG) &&
           (Z_LVAL_PP($input) >= std::numeric_limits<_type>::min()) &&
           (Z_LVAL_PP($input) <= std::numeric_limits<_type>::max())
          ) ? 0 : 1;"
%enddef

%php_typecheck_range(  int8_t,SWIG_TYPECHECK_INT8  );
%php_typecheck_range( int16_t,SWIG_TYPECHECK_INT16 );
%php_typecheck_range( int32_t,SWIG_TYPECHECK_INT32 );
%php_typecheck_range( int64_t,SWIG_TYPECHECK_INT64 );
%php_typecheck_range( uint8_t,SWIG_TYPECHECK_UINT8 );
%php_typecheck_range(uint16_t,SWIG_TYPECHECK_UINT16);
%php_typecheck_range(uint32_t,SWIG_TYPECHECK_UINT32);
%php_typecheck_range(uint64_t,SWIG_TYPECHECK_UINT64);

/*
 * Variant typechecks.
 */

%typecheck(SWIG_TYPECHECK_LIST) qpid::types::Variant::List &,
                                const qpid::types::Variant::List const &
{
    $1 = (isZvalList($input)) ? 1 : 0;
}

%typecheck(SWIG_TYPECHECK_MAP) qpid::types::Variant::Map &,
                               const qpid::types::Variant::Map const &
{
    $1 = ((Z_TYPE_PP($input) == IS_ARRAY) ||
          (Z_TYPE_PP($input) == IS_CONSTANT_ARRAY)) ? 1 : 0;
}

%typecheck(3000) qpid::types::Variant &,
                 const qpid::types::Variant const &
{
    $1 = ((Z_TYPE_PP($input) == IS_NULL)     ||
          (Z_TYPE_PP($input) == IS_LONG)     ||
          (Z_TYPE_PP($input) == IS_DOUBLE)   ||
          (Z_TYPE_PP($input) == IS_BOOL)     ||
          (Z_TYPE_PP($input) == IS_ARRAY)    ||
        //(Z_TYPE_PP($input) == IS_OBJECT)   ||
          (Z_TYPE_PP($input) == IS_STRING)   ||
        //(Z_TYPE_PP($input) == IS_RESOURCE) ||
          (Z_TYPE_PP($input) == IS_CONSTANT) ||
          (Z_TYPE_PP($input) == IS_CONSTANT_ARRAY)
         ) ? 1 : 0;
}

// End of swig_php_typemaps.i
