/*------------------------------------------------------------------------------
 * IBRuby.c
 *----------------------------------------------------------------------------*/
/**
 * Copyright © Peter Wood, 2005
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with the
 * License. You may obtain a copy of the License at
 *
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specificlanguage governing rights and  limitations under the License.
 *
 * The Original Code is the FireRuby extension for the Ruby language.
 *
 * The Initial Developer of the Original Code is Peter Wood. All Rights
 * Reserved.
 **
 * T he Microsoft Compiler has the following extensions when compiling

-nologo -MD -Zi -O2b2xg- -G6 -DOS_WIN32  -c
 *
 * @author  Peter Wood
 * @version 1.0
 */



/* Includes. */

#include "IBRuby.h"

#include <string.h>

#include "AddUser.h"

#include "Blob.h"

#include "Backup.h"

#include "Database.h"

#include "Connection.h"

#include "IBRubyException.h"

#include "Generator.h"

#include "RemoveUser.h"

#include "ResultSet.h"

#include "ServiceManager.h"

#include "Statement.h"

#include "Transaction.h"

#include "Restore.h"

#include "Row.h"


#ifdef OS_UNIX
  #define __declspec(X) 
#endif




/**

 * This function provides an encapsulation of extracting a setting from the

 * global IBRuby settings hash.

 *

 * @param  key  A string containing the name of the key to be retrieved.

 *

 */

VALUE getIBRubySetting(const char *key)

{

   VALUE settings = rb_gv_get("$IBRubySettings");

   return(rb_hash_aref(settings, toSymbol(key)));

}





/**

 * This function provides a convenience mechanism to obtain the class name for

 * an object, useful in debugging.

 *

 * @param  object  A reference to the objec to get the class name for.

 * @param  name    A string that will be populated with the class name.

 *

 */

void getClassName(VALUE object, char *name)

{

   VALUE klass  = rb_funcall(object, rb_intern("class"), 0),

         string = rb_funcall(klass, rb_intern("name"), 0);



   strcpy(name, STR2CSTR(string));

}





/**

 * This method takes a string and generates a Symbol object from it.

 *

 * @param  name  A string containing the text to be made into a Symbol.

 *

 * @return  A Symbol object for the string passed in.

 *

 */

VALUE toSymbol(const char *name)

{

   return(rb_funcall(rb_str_new2(name), rb_intern("intern"), 0));

}





/**

 * This function attempts to deduce the type for a SQL field from the XSQLVAR

 * structure that is used to describe it.

 *

 * @param  column  A pointer to the XSQLVAR structure for the column to work

 *                 the type out for.

 *

 * @return  A symbol giving the base type for the column.

 *

 */

VALUE getColumnType(const XSQLVAR *column)

{

   VALUE type = Qnil;

   

   switch((column->sqltype & ~1))

   {
	  case SQL_BOOLEAN:
		 type = toSymbol("BOOLEAN");
		 break;

      case SQL_BLOB:

         type = toSymbol("BLOB");

         break;



      case SQL_TYPE_DATE:

         type = toSymbol("DATE");

         break;



      case SQL_DOUBLE:

         type = toSymbol("DOUBLE");

         break;



      case SQL_FLOAT:

         type = toSymbol("FLOAT");

         break;



      case SQL_INT64:

         if(column->sqlsubtype != 0)

         {

            if(column->sqlsubtype == 1)

            {

               type = toSymbol("NUMERIC");

            }

            else if(column->sqlsubtype == 2)

            {

               type = toSymbol("DECIMAL");

            }

         }

         else

         {

            type = toSymbol("INT64");

         }

         break;



      case SQL_LONG:

         if(column->sqlsubtype != 0)

         {

            if(column->sqlsubtype == 1)

            {

               type = toSymbol("NUMERIC");

            }

            else if(column->sqlsubtype == 2)

            {

               type = toSymbol("DECIMAL");

            }

         }

         else

         {

            type = toSymbol("INTEGER");

         }

         break;



      case SQL_SHORT:

         if(column->sqlsubtype != 0)

         {

            if(column->sqlsubtype == 1)

            {

               type = toSymbol("NUMERIC");

            }

            else if(column->sqlsubtype == 2)

            {

               type = toSymbol("DECIMAL");

            }

         }

         else

         {

            type = toSymbol("SMALLINT");

         }

         break;



      case SQL_TEXT:

         type = toSymbol("CHAR");

         break;



      case SQL_TYPE_TIME:

         type = toSymbol("TIME");

         break;



      case SQL_TIMESTAMP:

         type = toSymbol("TIMESTAMP");

         break;



      case SQL_VARYING:

         type = toSymbol("VARCHAR");

         break;

         

      default:

         type = toSymbol("UNKNOWN");

   }


   if ( type == Qnil )
   {
	   fprintf( stderr, "unknown col type %d", column->sqltype & ~1 );
   }


   return(type);

}





/**

 * This function is required by the Ruby interpreter to load and initialize

 * the extension details. The function creates a module called 'IBRuby'

 * and then creates the various extension classes within this module.

 *

 */

//extern __declspec(dllimport) void Init_ib_lib(void)
extern void Init_ib_lib(void)
{

   VALUE module = rb_define_module("IBRuby"),

         array  = rb_ary_new(),

         hash   = rb_hash_new();



   /* Initialise the configuration and make it available. */

   rb_ary_push(array, INT2FIX(MAJOR_VERSION_NO));

   rb_ary_push(array, INT2FIX(MINOR_VERSION_NO));

   rb_ary_push(array, INT2FIX(BUILD_NO));

   rb_hash_aset(hash, toSymbol("ALIAS_KEYS"), Qtrue);

   rb_hash_aset(hash, toSymbol("DATE_AS_DATE"), Qtrue);

   rb_gv_set("$IBRubyVersion", array);

   rb_gv_set("$IBRubySettings", hash);



   /* Require needed libraries. */

   rb_require("date");
   rb_require("bigdecimal"); // for INT64 DECIMAL or NUMERICs



   /* Initialise the library classes. */

   Init_Database(module);

   Init_Connection(module);

   Init_Transaction(module);

   Init_Statement(module);

   Init_ResultSet(module);

   Init_Generator(module);

   Init_IBRubyException(module);

   Init_Blob(module);

   Init_Row(module);

   Init_ServiceManager(module);

   Init_Backup(module);

   Init_AddUser(module);

   Init_RemoveUser(module);

   Init_Restore(module);

}


