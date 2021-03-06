/*------------------------------------------------------------------------------
 * Database.h
 *----------------------------------------------------------------------------*/
/**
 * Copyright � Peter Wood, 2005
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
 *
 * @author  Peter Wood
 * @version 1.0
 */
#ifndef IBRUBY_DATABASE_H
#define IBRUBY_DATABASE_H

   /* Includes. */
   #ifndef IBRUBY_FIRE_RUBY_H
      #include "IBRuby.h"
   #endif

   #ifndef IBRUBY_FIRE_RUBY_EXCEPTION_H
      #include "IBRubyException.h"
   #endif

   /* Structure definitions. */
   typedef struct
   {
      int unused;
   } DatabaseHandle;
   
   /* Function prototypes. */
   void Init_Database(VALUE);
   void databaseFree(void *);
   VALUE rb_database_new(VALUE);   

#endif /* IBRUBY_DATABASE_H */
