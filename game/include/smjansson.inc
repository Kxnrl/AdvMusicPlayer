#if defined _jansson_included_
	#endinput
#endif
#define _jansson_included_

/**
 * --- Type
 *
 * The JSON specification (RFC 4627) defines the following data types:
 * object, array, string, number, boolean, and null.
 * JSON types are used dynamically; arrays and objects can hold any
 * other data type, including themselves. For this reason, Jansson's
 * type system is also dynamic in nature. There's one Handle type to
 * represent all JSON values, and the referenced structure knows the
 * type of the JSON value it holds.
 *
 */
enum JSONType {
	JSONType_Object,
	JSONType_Array,
	JSONType_String,
	JSONType_Integer,
	JSONType_Float,
	JSONType_True,
	JSONType_False,
	JSONType_Null
};

/**
 * Return the type of the JSON value.
 *
 * @param hObj              Handle to the JSON value
 *
 * @return                  JSONType of the value.
 */
native JSONType json_typeof(JSONValue hObj);

/**
 * The type of a JSON value is queried and tested using these macros
 *
 * @param %1                Handle to the JSON value
 *
 * @return                  True if the value has the correct type.
 */
#define json_is_object(%1)			( json_typeof(%1) == JSONType_Object )
#define json_is_array(%1)			( json_typeof(%1) == JSONType_Array )
#define json_is_string(%1)			( json_typeof(%1) == JSONType_String )
#define json_is_integer(%1)			( json_typeof(%1) == JSONType_Integer )
#define json_is_real(%1)			( json_typeof(%1) == JSONType_Float )
#define json_is_true(%1)			( json_typeof(%1) == JSONType_True )
#define json_is_false(%1)			( json_typeof(%1) == JSONType_False )
#define json_is_null(%1)			( json_typeof(%1) == JSONType_Null )
#define json_is_number(%1)			( json_typeof(%1) == JSONType_Integer || json_typeof(%1) == JSONType_Float )
#define json_is_boolean(%1)			( json_typeof(%1) == JSONType_True || json_typeof(%1) == JSONType_False )

/**
 * Saves json_type as a String in output
 *
 * @param input             json_type value to convert to string
 * @param output            Buffer to store the json_type value
 * @param maxlength         Maximum length of string buffer.
 *
 * @return                  False if the type does not exist.
 */
stock bool Stringify_json_type(JSONType input, char[] output, int maxlength) {
	switch(input) {
		case JSONType_Object:		strcopy(output, maxlength, "Object");
		case JSONType_Array:		strcopy(output, maxlength, "Array");
		case JSONType_String:		strcopy(output, maxlength, "String");
		case JSONType_Integer:		strcopy(output, maxlength, "Integer");
		case JSONType_Float:		strcopy(output, maxlength, "Float");
		case JSONType_True:			strcopy(output, maxlength, "True");
		case JSONType_False:		strcopy(output, maxlength, "False");
		case JSONType_Null:			strcopy(output, maxlength, "Null");
		default: return false;
	}

	return true;
}

/**
 * --- Equality
 *
 * - Two integer or real values are equal if their contained numeric
 *   values are equal. An integer value is never equal to a real value,
 *   though.
 * - Two strings are equal if their contained UTF-8 strings are equal,
 *   byte by byte. Unicode comparison algorithms are not implemented.
 * - Two arrays are equal if they have the same number of elements and
 *   each element in the first array is equal to the corresponding
 *   element in the second array.
 * - Two objects are equal if they have exactly the same keys and the
 *   value for each key in the first object is equal to the value of
 *   the corresponding key in the second object.
 * - Two true, false or null values have no "contents", so they are
 *   equal if their types are equal.
 *
 */

/**
 * Test whether two JSON values are equal.
 *
 * @param hObj              Handle to the first JSON node
 * @param hOther            Handle to the second JSON node
 *
 * @return                  Returns false if they are inequal or one
 *                          or both of the pointers are NULL.
 */
native bool json_equal(JSONValue hObj, JSONValue hOther);




/**
 * --- Copying
 *
 * Jansson supports two kinds of copying: shallow and deep. There is
 * a difference between these methods only for arrays and objects.
 *
 * Shallow copying only copies the first level value (array or object)
 * and uses the same child values in the copied value.
 *
 * Deep copying makes a fresh copy of the child values, too. Moreover,
 * all the child values are deep copied in a recursive fashion.
 *
 */

/**
 * Get a shallow copy of the passed object
 *
 * @param hObj              Handle to JSON object to be copied
 *
 * @return                  Returns a shallow copy of the object,
 *                          or INVALID_HANDLE on error.
 */
native JSONValue json_copy(JSONValue hObj);

/**
 * Get a deep copy of the passed object
 *
 * @param hObj              Handle to JSON object to be copied
 *
 * @return                  Returns a deep copy of the object,
 *                          or INVALID_HANDLE on error.
 */
native JSONValue json_deep_copy(JSONValue hObj);




/**
 * --- Objects
 *
 * A JSON object is a dictionary of key-value pairs, where the
 * key is a Unicode string and the value is any JSON value.
 *
 */

/**
 * Returns a handle to a new JSON object, or INVALID_HANDLE on error.
 * Initially, the object is empty.
 *
 * @return                  Handle to a new JSON object.
 */
native JSONObject json_object();

/**
 * Returns the number of elements in hObj
 *
 * @param hObj              Handle to JSON object
 *
 * @return                  Number of elements in hObj,
 *                          or 0 if hObj is not a JSON object.
 */
native int json_object_size(JSONObject hObj);

/**
 * Get a value corresponding to sKey from hObj
 *
 * @param hObj              Handle to JSON object to get a value from
 * @param sKey              Key to retrieve
 *
 * @return                  Handle to a the JSON object or
 *                          INVALID_HANDLE on error.
 */
native JSONValue json_object_get(JSONObject hObj, const char[] sKey);

/**
 * Set the value of sKey to hValue in hObj.
 * If there already is a value for key, it is replaced by the new value.
 *
 * @param hObj              Handle to JSON object to set a value on
 * @param sKey              Key to store in the object
 *                          Must be a valid null terminated UTF-8 encoded
 *                          Unicode string.
 * @param hValue            Value to store in the object
 *
 * @return					True on success.
 */
native bool json_object_set(JSONObject hObj, const char[] sKey, JSONValue hValue);

/**
 * Set the value of sKey to hValue in hObj.
 * If there already is a value for key, it is replaced by the new value.
 * This function automatically closes the Handle to the value object.
 *
 * @param hObj              Handle to JSON object to set a value on
 * @param sKey              Key to store in the object
 *                          Must be a valid null terminated UTF-8 encoded
 *                          Unicode string.
 * @param hValue            Value to store in the object
 *
 * @return					True on success.
 */
native bool json_object_set_new(JSONObject hObj, const char[] sKey, JSONValue hValue);

/**
 * Delete sKey from hObj if it exists.
 *
 * @param hObj              Handle to JSON object to delete a key from
 * @param sKey              Key to delete
 *
 * @return                  True on success.
 */
native bool json_object_del(JSONObject hObj, const char[] sKey);

/**
 * Remove all elements from hObj.
 *
 * @param hObj              Handle to JSON object to remove all
 *                          elements from.
 *
 * @return                  True on success.
 */
native bool json_object_clear(JSONObject hObj);

/**
 * Update hObj with the key-value pairs from hOther, overwriting
 * existing keys.
 *
 * @param hObj              Handle to JSON object to update
 * @param hOther            Handle to JSON object to get update
 *                          keys/values from.
 *
 * @return                  True on success.
 */
native bool json_object_update(JSONObject hObj, JSONObject hOther);

/**
 * Like json_object_update(), but only the values of existing keys
 * are updated. No new keys are created.
 *
 * @param hObj              Handle to JSON object to update
 * @param hOther            Handle to JSON object to get update
 *                          keys/values from.
 *
 * @return                  True on success.
 */
native bool json_object_update_existing(JSONObject hObj, JSONObject hOther);

/**
 * Like json_object_update(), but only new keys are created.
 * The value of any existing key is not changed.
 *
 * @param hObj              Handle to JSON object to update
 * @param hOther            Handle to JSON object to get update
 *                          keys/values from.
 *
 * @return                  True on success.
 */
native bool json_object_update_missing(JSONObject hObj, JSONObject hOther);




/**
 * Object iteration
 *
 * Example code:
 *  - We assume hObj is a Handle to a valid JSON object.
 *
 *
 * new Handle:hIterator = json_object_iter(hObj);
 * while(hIterator != INVALID_HANDLE)
 * {
 *     	new String:sKey[128];
 *      json_object_iter_key(hIterator, sKey, sizeof(sKey));
 *
 *      new Handle:hValue = json_object_iter_value(hIterator);
 *
 *      // Do something with sKey and hValue
 *
 *      CloseHandle(hValue);
 *
 *      hIterator = json_object_iter_next(hObj, hIterator);
 * }
 *
 */

/**
 * Returns a handle to an iterator which can be used to iterate over
 * all key-value pairs in hObj.
 * If you are not iterating to the end of hObj make sure to close the
 * handle to the iterator manually.
 *
 * @param hObj              Handle to JSON object to get an iterator
 *                          for.
 *
 * @return                  Handle to JSON object iterator,
 *                          or INVALID_HANDLE on error.
 */
native JSONObjectIterator json_object_iter(JSONObject hObj);

/**
 * Like json_object_iter(), but returns an iterator to the key-value
 * pair in object whose key is equal to key.
 * Iterating forward to the end of object only yields all key-value
 * pairs of the object if key happens to be the first key in the
 * underlying hash table.
 *
 * @param hObj              Handle to JSON object to get an iterator
 *                          for.
 * @param sKey              Start key for the iterator
 *
 * @return                  Handle to JSON object iterator,
 *                          or INVALID_HANDLE on error.
 */
native JSONObjectIterator json_object_iter_at(JSONObject hObj, const char[] sKey);

/**
 * Returns an iterator pointing to the next key-value pair in object.
 * This automatically closes the Handle to the iterator hIter.
 *
 * @param hObj              Handle to JSON object.
 * @param hIter             Handle to JSON object iterator.
 *
 * @return                  Handle to JSON object iterator,
 *                          or INVALID_HANDLE on error, or if the
 *                          whole object has been iterated through.
 */
native JSONObjectIterator json_object_iter_next(JSONObject hObj, JSONObjectIterator hIter);

/**
 * Extracts the associated key of hIter as a null terminated UTF-8
 * encoded string in the passed buffer.
 *
 * @param hIter             Handle to the JSON String object
 * @param sKeyBuffer        Buffer to store the value of the String.
 * @param maxlength         Maximum length of string buffer.
 * @error                   Invalid JSON Object Iterator.
 * @return                  Length of the returned string or -1 on error.
 */
native int json_object_iter_key(JSONObjectIterator hIter, char[] sKeyBuffer, int maxlength);

/**
 * Returns a handle to the value hIter is pointing at.
 *
 * @param hIter             Handle to JSON object iterator.
 *
 * @return                  Handle to value or INVALID_HANDLE on error.
 */
native JSONValue json_object_iter_value(JSONObjectIterator hIter);

/**
 * Set the value of the key-value pair in hObj, that is pointed to
 * by hIter, to hValue.
 *
 * @param hObj              Handle to JSON object.
 * @param hIter             Handle to JSON object iterator.
 * @param hValue            Handle to JSON value.
 *
 * @return                  True on success.
 */
native bool json_object_iter_set(JSONObject hObj, JSONObjectIterator hIter, JSONValue hValue);

/**
 * Set the value of the key-value pair in hObj, that is pointed to
 * by hIter, to hValue.
 * This function automatically closes the Handle to the value object.
 *
 * @param hObj              Handle to JSON object.
 * @param hIter             Handle to JSON object iterator.
 * @param hValue            Handle to JSON value.
 *
 * @return                  True on success.
 */
native bool json_object_iter_set_new(JSONObject hObj, JSONObjectIterator hIter, JSONValue hValue);




/**
 * Arrays
 *
 * A JSON array is an ordered collection of other JSON values.
 *
 */

/**
 * Returns a handle to a new JSON array, or INVALID_HANDLE on error.
 *
 * @return                  Handle to the new JSON array
 */
native JSONArray json_array();

/**
 * Returns the number of elements in hArray
 *
 * @param hObj              Handle to JSON array
 *
 * @return                  Number of elements in hArray,
 *                          or 0 if hObj is not a JSON array.
 */
native int json_array_size(JSONArray hArray);

/**
 * Returns the element in hArray at position iIndex.
 *
 * @param hArray            Handle to JSON array to get a value from
 * @param iIndex            Position to retrieve
 *
 * @return                  Handle to a the JSON object or
 *                          INVALID_HANDLE on error.
 */
native JSONValue json_array_get(JSONArray hArray, int iIndex);

/**
 * Replaces the element in array at position iIndex with hValue.
 * The valid range for iIndex is from 0 to the return value of
 * json_array_size() minus 1.
 *
 * @param hArray            Handle to JSON array
 * @param iIndex            Position to replace
 * @param hValue            Value to store in the array
 *
 * @return					True on success.
 */
native bool json_array_set(JSONArray hArray, int iIndex, JSONValue hValue);

/**
 * Replaces the element in array at position iIndex with hValue.
 * The valid range for iIndex is from 0 to the return value of
 * json_array_size() minus 1.
 * This function automatically closes the Handle to the value object.
 *
 * @param hArray            Handle to JSON array
 * @param iIndex            Position to replace
 * @param hValue            Value to store in the array
 *
 * @return					True on success.
 */
native bool json_array_set_new(JSONArray hArray, int iIndex, JSONValue hValue);

/**
 * Appends value to the end of array, growing the size of array by 1.
 *
 * @param hArray            Handle to JSON array
 * @param hValue            Value to append to the array
 *
 * @return					True on success.
 */
native bool json_array_append(JSONArray hArray, JSONValue hValue);

/**
 * Appends value to the end of array, growing the size of array by 1.
 * This function automatically closes the Handle to the value object.
 *
 * @param hArray            Handle to JSON array
 * @param hValue            Value to append to the array
 *
 * @return					True on success.
 */
native bool json_array_append_new(JSONArray hArray, JSONValue hValue);

/**
 * Inserts value to hArray at position iIndex, shifting the elements at
 * iIndex and after it one position towards the end of the array.
 *
 * @param hArray            Handle to JSON array
 * @param iIndex            Position to insert at
 * @param hValue            Value to store in the array
 *
 * @return					True on success.
 */
native bool json_array_insert(JSONArray hArray, int iIndex, JSONValue hValue);

/**
 * Inserts value to hArray at position iIndex, shifting the elements at
 * iIndex and after it one position towards the end of the array.
 * This function automatically closes the Handle to the value object.
 *
 * @param hArray            Handle to JSON array
 * @param iIndex            Position to insert at
 * @param hValue            Value to store in the array
 *
 * @return					True on success.
 */
native bool json_array_insert_new(JSONArray hArray, int iIndex, JSONValue hValue);

/**
 * Removes the element in hArray at position iIndex, shifting the
 * elements after iIndex one position towards the start of the array.
 *
 * @param hArray            Handle to JSON array
 * @param iIndex            Position to insert at
 *
 * @return					True on success.
 */
native bool json_array_remove(JSONArray hArray, int iIndex);

/**
 * Removes all elements from hArray.
 *
 * @param hArray            Handle to JSON array
 *
 * @return					True on success.
 */
native bool json_array_clear(JSONArray hArray);

/**
 * Appends all elements in hOther to the end of hArray.
 *
 * @param hArray            Handle to JSON array to be extended
 * @param hOther            Handle to JSON array, source to copy from
 *
 * @return					True on success.
 */
native bool json_array_extend(JSONArray hArray, JSONArray hOther);




/**
 * Booleans & NULL
 *
 */

/**
 * Returns a handle to a new JSON Boolean with value true,
 * or INVALID_HANDLE on error.
 *
 * @return                  Handle to the new Boolean object
 */
native JSONValue json_true();

/**
 * Returns a handle to a new JSON Boolean with value false,
 * or INVALID_HANDLE on error.
 *
 * @return                  Handle to the new Boolean object
 */
native JSONValue json_false();

/**
 * Returns a handle to a new JSON Boolean with the value passed
 * in bState or INVALID_HANDLE on error.
 *
 * @param bState            Value for the new Boolean object
 * @return                  Handle to the new Boolean object
 */
native JSONValue json_boolean(bool bState);

/**
 * Returns a handle to a new JSON NULL or INVALID_HANDLE on error.
 *
 * @return                  Handle to the new NULL object
 */
native JSONValue json_null();




/**
 * Strings
 *
 * Jansson uses UTF-8 as the character encoding. All JSON strings must
 * be valid UTF-8 (or ASCII, as it's a subset of UTF-8). Normal null
 * terminated C strings are used, so JSON strings may not contain
 * embedded null characters.
 *
 */

/**
 * Returns a handle to a new JSON string, or INVALID_HANDLE on error.
 *
 * @param sValue            Value for the new String object
 *							Must be a valid UTF-8 encoded Unicode string.
 * @return                  Handle to the new String object
 */
native JSONString json_string(const char[] sValue);

/**
 * Saves the associated value of hString as a null terminated UTF-8
 * encoded string in the passed buffer.
 *
 * @param hString           Handle to the JSON String object
 * @param sValueBuffer      Buffer to store the value of the String.
 * @param maxlength         Maximum length of string buffer.
 * @error                   Invalid JSON String Object.
 * @return                  Length of the returned string or -1 on error.
 */
native int json_string_value(JSONString hString, char[] sValueBuffer, int maxlength);

/**
 * Sets the associated value of JSON String object to value.
 *
 * @param hString           Handle to the JSON String object
 * @param sValue            Value to set the object to.
 *                          Must be a valid UTF-8 encoded Unicode string.
 * @error                   Invalid JSON String Object.
 * @return                  True on success.
 */
native bool json_string_set(JSONString hString, const char[] sValue);




/**
 * Numbers
 *
 * The JSON specification only contains one numeric type, 'number'.
 * The C (and Pawn) programming language has distinct types for integer
 * and floating-point numbers, so for practical reasons Jansson also has
 * distinct types for the two. They are called 'integer' and 'real',
 * respectively. (Whereas 'real' is a 'Float' for Pawn).
 * Therefore a number is represented by either a value of the type
 * JSONType_Integer or of the type JSONType_Float.
 *
 */

/**
 * Returns a handle to a new JSON integer, or INVALID_HANDLE on error.
 *
 * @param iValue            Value for the new Integer object
 * @return                  Handle to the new Integer object
 */
native JSONInteger json_integer(int iValue);

/**
 * Returns the associated value of a JSON Integer Object.
 *
 * @param hInteger          Handle to the JSON Integer object
 * @error                   Invalid JSON Integer Object.
 * @return                  Value of the hInteger,
 *                          or 0 if hInteger is not a JSON integer.
 */
native int json_integer_value(JSONInteger hInteger);

/**
 * Sets the associated value of JSON Integer to value.
 *
 * @param hInteger          Handle to the JSON Integer object
 * @param iValue            Value to set the object to.
 * @error                   Invalid JSON Integer Object.
 * @return                  True on success.
 */
native bool json_integer_set(JSONInteger hInteger, int iValue);




/**
 * Returns a handle to a new JSON real, or INVALID_HANDLE on error.
 *
 * @param fValue            Value for the new Real object
 * @return                  Handle to the new String object
 */
native JSONFloat json_real(float fValue);

/**
 * Returns the associated value of a JSON Real.
 *
 * @param hReal             Handle to the JSON Real object
 * @error                   Invalid JSON Real Object.
 * @return                  Float value of hReal,
 *                          or 0.0 if hReal is not a JSON Real.
 */
native float json_real_value(JSONFloat hReal);

/**
 * Sets the associated value of JSON Real to fValue.
 *
 * @param hReal             Handle to the JSON Integer object
 * @param fValue            Value to set the object to.
 * @error                   Invalid JSON Real handle.
 * @return                  True on success.
 */
native bool json_real_set(JSONFloat hReal, float value);

/**
 * Returns the associated value of a JSON integer or a
 * JSON Real, cast to Float regardless of the actual type.
 *
 * @param hNumber           Handle to the JSON Number
 * @error                   Not a JSON Real or JSON Integer
 * @return                  Float value of hNumber,
 *                          or 0.0 on error.
 */
native float json_number_value(JSONNumber hNumber);




/**
 * Decoding
 *
 * This sections describes the functions that can be used to decode JSON text
 * to the Jansson representation of JSON data. The JSON specification requires
 * that a JSON text is either a serialized array or object, and this
 * requirement is also enforced with the following functions. In other words,
 * the top level value in the JSON text being decoded must be either array or
 * object.
 *
 */

/**
 * Decodes the JSON string sJSON and returns the array or object it contains.
 * Errors while decoding can be found in the sourcemod error log.
 *
 * @param sJSON             String containing valid JSON

 * @return                  Handle to JSON object or array.
 *                          or INVALID_HANDLE on error.
 */
native JSONValue json_load(const char[] sJSON);

/**
 * Decodes the JSON string sJSON and returns the array or object it contains.
 * This function provides additional error feedback and does not log errors
 * to the sourcemod error log.
 *
 * @param sJSON             String containing valid JSON
 * @param sErrorText        This buffer will be filled with the error
 *                          message.
 * @param maxlen            Size of the buffer
 * @param iLine             This int will contain the line of the error
 * @param iColumn           This int will contain the column of the error
 *
 * @return                  Handle to JSON object or array.
 *                          or INVALID_HANDLE on error.
 */
native JSONValue json_load_ex(const char[] sJSON, char[] sErrorText, int maxlen, int &iLine, int &iColumn);

/**
 * Decodes the JSON text in file sFilePath and returns the array or object
 * it contains.
 * Errors while decoding can be found in the sourcemod error log.
 *
 * @param sFilePath         Path to a file containing pure JSON
 *
 * @return                  Handle to JSON object or array.
 *                          or INVALID_HANDLE on error.
 */
native JSONValue json_load_file(const char sFilePath[PLATFORM_MAX_PATH]);

/**
 * Decodes the JSON text in file sFilePath and returns the array or object
 * it contains.
 * This function provides additional error feedback and does not log errors
 * to the sourcemod error log.
 *
 * @param sFilePath         Path to a file containing pure JSON
 * @param sErrorText        This buffer will be filled with the error
 *                          message.
 * @param maxlen            Size of the buffer
 * @param iLine             This int will contain the line of the error
 * @param iColumn           This int will contain the column of the error
 *
 * @return                  Handle to JSON object or array.
 *                          or INVALID_HANDLE on error.
 */
native JSONValue json_load_file_ex(const char sFilePath[PLATFORM_MAX_PATH], char[] sErrorText, int maxlen, int &iLine, int &iColumn);



/**
 * Encoding
 *
 * This sections describes the functions that can be used to encode values
 * to JSON. By default, only objects and arrays can be encoded directly,
 * since they are the only valid root values of a JSON text.
 *
 */

/**
 * Saves the JSON representation of hObject in sJSON.
 *
 * @param hObject           String containing valid JSON
 * @param sJSON             Buffer to store the created JSON string.
 * @param maxlength         Maximum length of string buffer.
 * @param iIndentWidth      Indenting with iIndentWidth spaces.
 *                          The valid range for this is between 0 and 31 (inclusive),
 *                          other values result in an undefined output. If this is set
 *                          to 0, no newlines are inserted between array and object items.
 * @param bEnsureAscii      If this is set, the output is guaranteed
 *                          to consist only of ASCII characters. This is achieved
 *                          by escaping all Unicode characters outside the ASCII range.
 * @param bSortKeys         If this flag is used, all the objects in output are sorted
 *                          by key. This is useful e.g. if two JSON texts are diffed
 *                          or visually compared.
 * @param bPreserveOrder    If this flag is used, object keys in the output are sorted
 *                          into the same order in which they were first inserted to
 *                          the object. For example, decoding a JSON text and then
 *                          encoding with this flag preserves the order of object keys.
 * @return                  Length of the returned string or -1 on error.
 */
native int json_dump(JSONValue hObject, char[] sJSON, int maxlength, int iIndentWidth = 4, bool bEnsureAscii = false, bool bSortKeys = false, bool bPreserveOrder = false);

/**
 * Write the JSON representation of hObject to the file sFilePath.
 * If sFilePath already exists, it is overwritten.
 *
 * @param hObject           String containing valid JSON
 * @param sFilePath         Buffer to store the created JSON string.
 * @param iIndentWidth      Indenting with iIndentWidth spaces.
 *                          The valid range for this is between 0 and 31 (inclusive),
 *                          other values result in an undefined output. If this is set
 *                          to 0, no newlines are inserted between array and object items.
 * @param bEnsureAscii      If this is set, the output is guaranteed
 *                          to consist only of ASCII characters. This is achieved
 *                          by escaping all Unicode characters outside the ASCII range.
 * @param bSortKeys         If this flag is used, all the objects in output are sorted
 *                          by key. This is useful e.g. if two JSON texts are diffed
 *                          or visually compared.
 * @param bPreserveOrder    If this flag is used, object keys in the output are sorted
 *                          into the same order in which they were first inserted to
 *                          the object. For example, decoding a JSON text and then
 *                          encoding with this flag preserves the order of object keys.
 * @return                  Length of the returned string or -1 on error.
 */
native bool json_dump_file(JSONValue hObject, const char[] sFilePath, int iIndentWidth = 4, bool bEnsureAscii = false, bool bSortKeys = false, bool bPreserveOrder = false);




/**
 * MethodMaps
 *
 * Again: EXPERIMENTAL!
 *
 */


enum JSONObjectUpdateType {
	Update_All = 0,
	Update_Existing,
	Update_Missing
};

/**
 * Base methodmap for all of smjansson's handles
 */
methodmap JSONValue < Handle {
	property JSONType Type {
		public get() {
			return json_typeof(this);
		}
	}

	property bool IsObject {
		public get() {
			return (this.Type == JSONType_Object);
		}
	}

	property bool IsArray {
		public get() {
			return (this.Type == JSONType_Array);
		}
	}

	property bool IsString {
		public get() {
			return (this.Type == JSONType_String);
		}
	}

	property bool IsInteger {
		public get() {
			return (this.Type == JSONType_Integer);
		}
	}

	property bool IsFloat {
		public get() {
			return (this.Type == JSONType_Float);
		}
	}

	property bool IsTrue {
		public get() {
			return (this.Type == JSONType_True);
		}
	}

	property bool IsFalse {
		public get() {
			return (this.Type == JSONType_False);
		}
	}

	property bool IsNull {
		public get() {
			return (this.Type == JSONType_Null);
		}
	}

	property bool IsNumber {
		public get() {
			return (this.Type == JSONType_Integer || this.Type == JSONType_Float);
		}
	}

	property bool IsBoolean {
		public get() {
			return (this.Type == JSONType_True || this.Type == JSONType_False);
		}
	}

	property any Value {
		// not implemented
	}

	public bool Equals(JSONValue other) {
		return json_equal(this, other);
	}

	public JSONValue Copy(bool deep = false) {
		if (deep) {
			return view_as<JSONValue>(json_deep_copy(this));
		} else {
			return view_as<JSONValue>(json_copy(this));
		}
	}

	public void TypeToString(char[] buffer, int maxlength) {
		if (!Stringify_json_type(view_as<JSONType>(this.Type), buffer, maxlength)) {
			ThrowError("Attempting to get type of a non-SMJansson handle");
		}
	}
}

methodmap JSONBoolean < JSONValue {
	public JSONBoolean(bool value) {
		return view_as<JSONBoolean>(json_boolean(value));
	}

	property bool Value {
		public get() {
			if (this.Type == JSONType_True) {
				return true;
			} else if (this.Type == JSONType_False) {
				return false;
			}
			ThrowError("Not a JSONBoolean value");
			return false;
		}
	}
}

methodmap JSONNull < JSONValue {
	public JSONNull() {
		return view_as<JSONNull>(json_null());
	}
}

methodmap JSONString < JSONValue {
	public JSONString(const char[] value) {
		return view_as<JSONString>(json_string(value));
	}

	public static JSONString Format(int bufferSize = 4096, const char[] format, any ...) {
		char[] buffer = new char[bufferSize];
		VFormat(buffer, bufferSize, format, 3);
		return new JSONString(buffer);
	}

	public int GetString(char[] buffer, int length) {
		return json_string_value(this, buffer, length);
	}

	public bool SetString(char[] value) {
		return json_string_set(this, value);
	}
}

/**
 * Base map inherited by JSONInteger and JSONFloat to get the value of either, cast to float.
 */
methodmap JSONNumber < JSONValue {
	public float FloatValue() {
		return json_number_value(this);
	}
}

methodmap JSONInteger < JSONNumber {
	public JSONInteger(int value) {
		return view_as<JSONInteger>(json_integer(value));
	}

	property int Value {
		public get() {
			return json_integer_value(this);
		}
		public set(int value) {
			json_integer_set(this, value);
		}
	}
}

methodmap JSONFloat < JSONNumber {
	public JSONFloat(float value) {
		return view_as<JSONFloat>(json_real(value));
	}

	property float Value {
		public get() {
			return json_real_value(this);
		}
		public set(float value) {
			json_real_set(this, value);
		}
	}
}

/**
 * Provides a few functions for valid root nodes (JSONArray and JSONObject)
 */
methodmap JSONRootNode < JSONValue {
	/**
	 * Dumps the contents of the given root node to a string.
	 *
	 * @return Number of characters written
	 */
	public int ToString(char[] buffer, int maxlength, int indentWidth = 4,
			bool asciiOnly = false, bool sortKeys = false, bool preserveOrder = false) {
		return json_dump(this, buffer, maxlength, indentWidth, asciiOnly, sortKeys,
				preserveOrder);
	}

	/**
	 * @return True on success
	 */
	public bool ToFile(const char[] filePath, int indentWidth = 4, bool asciiOnly = false,
			bool sortKeys = false, bool preserveOrder = false) {
		return json_dump_file(this, filePath, indentWidth, asciiOnly, sortKeys, preserveOrder);
	}

	public static JSONRootNode FromFile(const char[] filePath) {
		char path[PLATFORM_MAX_PATH];
		strcopy(path, sizeof(path), filePath);
		return view_as<JSONRootNode>(json_load_file(path));
	}

	public static JSONRootNode Pack(const char[] packString, ArrayList params) {
		return json_pack(packString, params);
	}

	public void DumpToServer() {
		char sMsg[4096];
		this.ToString(sMsg, sizeof(sMsg));

		PrintToServer(sMsg);
	}
}

methodmap JSONArray < JSONRootNode {
	public JSONArray() {
		return view_as<JSONArray>(json_array());
	}

	property int Length {
		public get() {
			if (this.Type != JSONType_Array) {
				ThrowError("Handle is not an array");
			}
			return json_array_size(this);
		}
	}

	public JSONValue Get(int index) {
		return view_as<JSONValue>(json_array_get(this, index));
	}

	public bool Set(int index, JSONValue value, bool autoClose = true) {
		if (autoClose) {
			return json_array_set_new(this, index, value);
		}
		return json_array_set(this, index, value);
	}

	public bool Append(JSONValue value, bool autoClose = true) {
		if (autoClose) {
			return json_array_append_new(this, value);
		}
		return json_array_append(this, value);
	}

	public bool Insert(int index, JSONValue value, bool autoClose = true) {
		if (autoClose) {
			return json_array_insert_new(this, index, value);
		}
		return json_array_insert(this, index, value);
	}

	public bool Remove(int index) {
		return json_array_remove(this, index);
	}

	public bool Clear() {
		return json_array_clear(this);
	}

	public bool Extend(JSONArray other) {
		return json_array_extend(this, other);
	}

	/**
	 * Utility functions
	 */

	/* Booleans */

	public bool GetBool(int index, bool defValue = false) {
		JSONValue value = this.Get(index);
		if(!value)
			return defValue;

		JSONType type = value.Type;
		delete value;

		switch (type) {
			case JSONType_True: { return true; }
			case JSONType_False: { return false; }
		}
		return defValue;
	}

	public bool SetBool(int index, bool value) {
		return this.Set(index, new JSONBoolean(value));
	}

	public bool AppendBool(bool value) {
		return this.Append(new JSONBoolean(value));
	}

	public bool InsertBool(int index, bool value) {
		return this.Insert(index, new JSONBoolean(value));
	}

	/* Floats */

	public float GetFloat(int index, float defValue = 0.0) {
		JSONValue value = this.Get(index);
		if(!value)
			return defValue;

		float result = (json_is_number(value) ?
				(view_as<JSONNumber>(value)).FloatValue() : defValue);
		delete value;

		return result;
	}

	public bool SetFloat(int index, float value) {
		return this.Set(index, new JSONFloat(value));
	}

	public bool AppendFloat(float value) {
		return this.Append(new JSONFloat(value));
	}

	public bool InsertFloat(int index, float value) {
		return this.Insert(index, new JSONFloat(value));
	}

	/* Integers */

	public int GetInt(int index, int defValue = 0) {
		JSONValue value = this.Get(index);
		if(!value)
			return defValue;

		int result = value.Type == JSONType_Integer ? (view_as<JSONInteger>(value)).Value : 0;
		delete value;

		return result;
	}

	public bool SetInt(int index, int value) {
		return this.Set(index, new JSONInteger(value));
	}

	public bool AppendInt(int value) {
		return this.Append(new JSONInteger(value));
	}

	public bool InsertInt(int index, int value) {
		return this.Insert(index, new JSONInteger(value));
	}

	/* Strings */

	public int GetString(int index, char[] buffer, int maxlength) {
		JSONValue value = this.Get(index);
		if(!value)
			return -1;

		int result = -1;
		if (value.Type == JSONType_String) {
			result = (view_as<JSONString>(value)).GetString(buffer, maxlength);
		}
		delete value;
		return result;
	}

	public bool SetString(int index, const char[] value) {
		return this.Set(index, new JSONString(value));
	}

	public bool AppendString(const char[] value) {
		return this.Append(new JSONString(value));
	}

	public bool InsertString(int index, const char[] value) {
		return this.Insert(index, new JSONString(value));
	}

	/* Misc. functions */

	public static JSONArray FromFile(const char[] filePath) {
		JSONRootNode data = JSONRootNode.FromFile(filePath);

		if (data.Type == JSONType_Array) {
			return view_as<JSONArray>(data);
		} else {
			ThrowError("File loaded by JSONArray.FromFile was not an array");
			delete data;
			return null;
		}
	}

	public static JSONArray Pack(const char[] packString, ArrayList params) {
		int length = strlen(packString);
		if (packString[0] == '[' && packString[length - 1] == ']') {
			return view_as<JSONArray>(JSONRootNode.Pack(packString, params));
		} else {
			ThrowError("Pack string '%s' is not appropriate for creating a JSONArray",
					packString);
			return null;
		}
	}
}

methodmap JSONObject < JSONRootNode {
	public JSONObject() {
		return view_as<JSONObject>(json_object());
	}

	property int Size {
		public get() {
			return json_object_size(this);
		}
	}

	public JSONValue Get(const char[] key) {
		return view_as<JSONValue>(json_object_get(this, key));
	}

	public bool Set(const char[] key, JSONValue value, bool autoClose = true) {
		if (autoClose) {
			return json_object_set_new(this, key, value);
		}
		return json_object_set(this, key, value);
	}

	/**
	 * @return true on success
	 */
	public bool Remove(const char[] key) {
		return json_object_del(this, key);
	}

	public bool Clear() {
		return json_object_clear(this);
	}

	public bool Update(JSONObject other, JSONObjectUpdateType updateType = Update_All) {
		switch (updateType) {
			case Update_Existing: {
				return json_object_update_existing(this, other);
			}
			case Update_Missing: {
				return json_object_update_missing(this, other);
			}
		}
		return json_object_update(this, other);
	}

	/**
	 * Utility functions
	 */

	public bool GetBool(const char[] key, bool defValue = false) {
		JSONValue value = this.Get(key);
		if(!value)
			return defValue;

		JSONType type = value.Type;
		delete value;

		switch (type) {
			case JSONType_True: { return true; }
			case JSONType_False: { return false; }
		}
		return defValue;
	}

	public bool SetBool(const char[] key, bool value) {
		return this.Set(key, new JSONBoolean(value));
	}

	/* Floats */

	public float GetFloat(const char[] key, float defValue = 0.0) {
		JSONValue value = this.Get(key);
		if(!value)
			return defValue;

		float result = (json_is_number(value) ?
				(view_as<JSONNumber>(value)).FloatValue() : defValue);
		delete value;

		return result;
	}

	public bool SetFloat(const char[] key, float value) {
		return this.Set(key, new JSONFloat(value));
	}

	/* Integers */

	public int GetInt(const char[] key, int defValue = 0) {
		JSONValue value = this.Get(key);
		if(!value)
			return defValue;

		int result = value.Type == JSONType_Integer ?
				(view_as<JSONInteger>(value)).Value : defValue;
		delete value;

		return result;
	}

	public bool SetInt(const char[] key, int value) {
		return this.Set(key, new JSONInteger(value));
	}

	/* Strings */

	public int GetString(const char[] key, char[] buffer, int maxlength) {
		JSONValue value = this.Get(key);
		if(!value)
			return -1;

		int result = -1;
		if (value.Type == JSONType_String) {
			result = (view_as<JSONString>(value)).GetString(buffer, maxlength);
		}
		delete value;
		return result;
	}

	public bool SetString(const char[] key, const char[] value) {
		return this.Set(key, new JSONString(value));
	}

	/* Misc. functions */

	public static JSONObject FromFile(const char[] filePath) {
		JSONRootNode data = JSONRootNode.FromFile(filePath);

		if (data.Type == JSONType_Object) {
			return view_as<JSONObject>(data);
		} else {
			ThrowError("File loaded by JSONObject.FromFile was not an object");
			delete data;
			return null;
		}
	}

	public static JSONObject Pack(const char[] packString, ArrayList params) {
		int length = strlen(packString);
		if (packString[0] == '{' && packString[length - 1] == '}') {
			return view_as<JSONObject>(JSONRootNode.Pack(packString, params));
		} else {
			ThrowError("Pack string '%s' is not appropriate for creating a JSONObject",
					packString);
			return null;
		}
	}
}

methodmap JSONObjectIterator < Handle {
	public static JSONObjectIterator From(JSONObject obj, const char[] key = "") {
		if (strlen(key) > 0) {
			return view_as<JSONObjectIterator>(json_object_iter_at(obj, key));
		}
		return view_as<JSONObjectIterator>(json_object_iter(obj));
	}

	public JSONObjectIterator Next(JSONObject obj) {
		return view_as<JSONObjectIterator>(json_object_iter_next(obj, this));
	}

	public int GetKey(char[] buffer, int maxlength) {
		return json_object_iter_key(this, buffer, maxlength);
	}

	public JSONValue GetValue() {
		return view_as<JSONValue>(json_object_iter_value(this));
	}

	public bool SetValue(JSONObject obj, JSONValue value, bool autoclose = true) {
		if (autoclose) {
			return json_object_iter_set_new(obj, this, value);
		}
		return json_object_iter_set(obj, this, value);
	}
}


/**
 * Some additional constructors
 *
 *
 */

/**
 * Returns a handle to a new JSON string, or INVALID_HANDLE on error.
 * Formats the string according to the SourceMod format rules.
 * The result must be a valid UTF-8 encoded Unicode string.
 *
 * @param sFormat           Formatting rules.
 * @param ...			    Variable number of format parameters.
 * @return                  Handle to the new String object
 */
public JSONString JSONString_ByFormat(const char[] sFormat, ...) {
	char sTmp[4096];
	VFormat(sTmp, sizeof(sTmp), sFormat, 2);

	return new JSONString(sTmp);
}


/**
 * Returns a handle to a new JSON string, or INVALID_HANDLE on error.
 * This stock allows to specify the size of the temporary buffer used
 * to create the string. Use this if the default of 4096 is not enough
 * for your string.
 * Formats the string according to the SourceMod format rules.
 * The result must be a valid UTF-8 encoded Unicode string.
 *
 * @param tmpBufferLength   Size of the temporary buffer
 * @param sFormat           Formatting rules.
 * @param ...			    Variable number of format parameters.
 * @return                  Handle to the new String object
 */
public JSONString JSONString_ByFormatEx(int tmpBufferLength, const char[] sFormat, ...) {
	char[] sTmp = new char[tmpBufferLength];
	VFormat(sTmp, tmpBufferLength, sFormat, 3);

	return new JSONString(sTmp);
}


/**
 * Pack String Rules
 *
 * Here's the full list of format characters:
 *  n    Output a JSON null value. No argument is consumed.
 *  s    Output a JSON string, consuming one argument.
 *  b    Output a JSON bool value, consuming one argument.
 *  i    Output a JSON integer value, consuming one argument.
 *  f    Output a JSON real value, consuming one argument.
 *  r    Output a JSON real value, consuming one argument.
 *  []   Build an array with contents from the inner format string,
 *       recursive value building is supported.
 *       No argument is consumed.
 *  {}   Build an array with contents from the inner format string.
 *       The first, third, etc. format character represent a key,
 *       and must be s (as object keys are always strings). The
 *       second, fourth, etc. format character represent a value.
 *       Recursive value building is supported.
 *       No argument is consumed.
 *
 */

/**
 * This method can be used to create json objects/arrays directly
 * without having to create the structure.
 * See 'Pack String Rules' for more details.
 *
 * @param sPackString       Pack string similiar to Format()s fmt.
 *                          See 'Pack String Rules'.
 * @param hParams           ADT Array containing all keys and values
 *                          in the order they appear in the pack string.
 *
 * @error                   Invalid pack string or pack string and
 *                          ADT Array don't match up regarding type
 *                          or size.
 * @return                  Handle to JSON element.
 */
public JSONValue JSONValue_ByPack(const char[] sPackString, Handle hParams) {
	int iPos = 0;
	return json_pack_element_(sPackString, iPos, hParams);
}





/**
* Internal stocks used by json_pack(). Don't use these directly!
*
*/
public JSONArray json_pack_array_(const char[] sFormat, int &iPos, Handle hParams) {
	JSONArray hObj = new JSONArray();
	int iStrLen = strlen(sFormat);

	for(; iPos < iStrLen;) {
		int this_char = sFormat[iPos];

		if(this_char == 32 || this_char == 58 || this_char == 44) {
			// Skip whitespace, ',' and ':'
			iPos++;
			continue;
		}

		if(this_char == 93) {
			// array end
			iPos++;
			break;
		}

		// Get the next entry as value
		// This automatically increments the position!
		JSONValue hValue = json_pack_element_(sFormat, iPos, hParams);

		// Append the value to the array.
		hObj.Append(hValue);
	}

	return hObj;
}

public JSONObject json_pack_object_(const char[] sFormat, int &iPos, Handle hParams) {
	JSONObject hObj = new JSONObject();
	int iStrLen = strlen(sFormat);

	for(; iPos < iStrLen;) {
		int this_char = sFormat[iPos];

		if(this_char == 32 || this_char == 58 || this_char == 44) {
			// Skip whitespace, ',' and ':'
			iPos++;
			continue;
		}

		if(this_char == 125) {
			// } --> object end
			iPos++;
			break;
		}

		if(this_char != 115) {
			LogError("Object keys must be strings at %d.", iPos);
			CloseHandle(hObj);
			return view_as<JSONObject>(INVALID_HANDLE);
		}

		// Get the key string for this object from
		// the hParams array.
		char sKey[255];
		GetArrayString(hParams, 0, sKey, sizeof(sKey));
		RemoveFromArray(hParams, 0);

		// Advance one character in the pack string,
		// because we've just read the Key string for
		// this object.
		iPos++;

		// Get the next entry as value
		// This automatically increments the position!
		JSONValue hValue = json_pack_element_(sFormat, iPos, hParams);

		// Insert into object
		hObj.Set(sKey, hValue);
	}

	return hObj;
}

public JSONValue json_pack_element_(const char[] sFormat, int &iPos, Handle hParams) {
	int this_char = sFormat[iPos];
	while(this_char == 32 || this_char == 58 || this_char == 44) {
		iPos++;
		this_char = sFormat[iPos];
	}

	// Advance one character in the pack string
	iPos++;

	switch(this_char) {
		case 91: {
			// {  --> Array
			return json_pack_array_(sFormat, iPos, hParams);
		}

		case 123: {
			// {  --> Object
			return json_pack_object_(sFormat, iPos, hParams);

		}

		case 98: {
			// b  --> Boolean
			int iValue = GetArrayCell(hParams, 0);
			RemoveFromArray(hParams, 0);

			return json_boolean(view_as<bool>(iValue));
		}

		case 102, 114: {
			// r,f  --> Real (Float)
			float fValue = GetArrayCell(hParams, 0);
			RemoveFromArray(hParams, 0);

			return json_real(fValue);
		}

		case 110: {
			// n --> NULL
			return json_null();
		}

		case 115: {
			// s  --> String
			char sKey[255];
			GetArrayString(hParams, 0, sKey, sizeof(sKey));
			RemoveFromArray(hParams, 0);

			return json_string(sKey);
		}

		case 105: {
			// i  --> Integer
			int iValue = GetArrayCell(hParams, 0);
			RemoveFromArray(hParams, 0);

			return json_integer(iValue);
		}
	}

	SetFailState("Invalid pack String '%s'. Type '%s' not supported at %i", sFormat, this_char, iPos);
	return json_null();
}


/**
 * Not yet implemented
 *
 * native json_object_foreach(Handle:hObj, ForEachCallback:cb);
 * native Handle:json_unpack(const String:sFormat[], ...);
 *
 */


 /**
 * Do not edit below this line!
 */
public Extension __ext_smjansson =
{
	name = "SMJansson",
	file = "smjansson.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_EXTENSIONS
public __ext_smjansson_SetNTVOptional()
{
	MarkNativeAsOptional("json_typeof");
	MarkNativeAsOptional("json_equal");

	MarkNativeAsOptional("json_copy");
	MarkNativeAsOptional("json_deep_copy");

	MarkNativeAsOptional("json_object");
	MarkNativeAsOptional("json_object_size");
	MarkNativeAsOptional("json_object_get");
	MarkNativeAsOptional("json_object_set");
	MarkNativeAsOptional("json_object_set_new");
	MarkNativeAsOptional("json_object_del");
	MarkNativeAsOptional("json_object_clear");
	MarkNativeAsOptional("json_object_update");
	MarkNativeAsOptional("json_object_update_existing");
	MarkNativeAsOptional("json_object_update_missing");

	MarkNativeAsOptional("json_object_iter");
	MarkNativeAsOptional("json_object_iter_at");
	MarkNativeAsOptional("json_object_iter_next");
	MarkNativeAsOptional("json_object_iter_key");
	MarkNativeAsOptional("json_object_iter_value");
	MarkNativeAsOptional("json_object_iter_set");
	MarkNativeAsOptional("json_object_iter_set_new");

	MarkNativeAsOptional("json_array");
	MarkNativeAsOptional("json_array_size");
	MarkNativeAsOptional("json_array_get");
	MarkNativeAsOptional("json_array_set");
	MarkNativeAsOptional("json_array_set_new");
	MarkNativeAsOptional("json_array_append");
	MarkNativeAsOptional("json_array_append_new");
	MarkNativeAsOptional("json_array_insert");
	MarkNativeAsOptional("json_array_insert_new");
	MarkNativeAsOptional("json_array_remove");
	MarkNativeAsOptional("json_array_clear");
	MarkNativeAsOptional("json_array_extend");

	MarkNativeAsOptional("json_string");
	MarkNativeAsOptional("json_string_value");
	MarkNativeAsOptional("json_string_set");

	MarkNativeAsOptional("json_integer");
	MarkNativeAsOptional("json_integer_value");
	MarkNativeAsOptional("json_integer_set");

	MarkNativeAsOptional("json_real");
	MarkNativeAsOptional("json_real_value");
	MarkNativeAsOptional("json_real_set");
	MarkNativeAsOptional("json_number_value");

	MarkNativeAsOptional("json_boolean");
	MarkNativeAsOptional("json_true");
	MarkNativeAsOptional("json_false");
	MarkNativeAsOptional("json_null");

	MarkNativeAsOptional("json_load");
	MarkNativeAsOptional("json_load_file");

	MarkNativeAsOptional("json_dump");
	MarkNativeAsOptional("json_dump_file");
}
#endif