/*------------------------------------------------------------------------------
 * Services.c
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

#include "Services.h"
#include "IBRubyException.h"
#ifdef OS_UNIX
   #include <unistd.h>
#endif

/* Defines. */
#define START_BUFFER_SIZE     1024


/**
 * This function is used to query the status of a service, returning any of
 * the output generated by the service operation.
 *
 * @param  handle  A pointer to the service manager handle to be used to query
 *                 the service.
 *
 * @return  Either a String object containing the output from the service query
 *          or nil if there is no output.
 *
 */
VALUE queryService(isc_svc_handle *handle)
{
   VALUE result = Qnil;
   int   size   = START_BUFFER_SIZE;
   short done   = 0;

   /* Query the service until it has completed. */
   while(!done)
   {
      ISC_STATUS status[20];
      char       *output   = NULL,
                 *offset   = NULL,
                 *log      = NULL,
                 request[] = {isc_info_svc_to_eof};
      short      len       = 0;

      /* Allocate the output buffer. */
      offset = output = ALLOC_N(char, size);
      if(output == NULL)
      {
         rb_raise(rb_eNoMemError,
                  "Memory allocation failure querying service status.");
      }
      memset(output, 0, size);

      /* Make the service info request. */
      done = 1;
      if(isc_service_query(status, handle, NULL, 0, NULL, sizeof(request),
                           request, size, output))
      {
         free(output);
         rb_ibruby_raise(status, "Error querying service status.");
      }

      do
      {
         switch(*offset++)
         {
            case isc_info_svc_to_eof :
               len    = isc_vax_integer(offset, 2);
               offset += 2;
               if(len > 0)
               {
                  log = ALLOC_N(char, len + 1);
                  if(log == NULL)
                  {
                     free(output);
                     rb_raise(rb_eNoMemError,
                              "Memory allocation failure querying service status.");
                  }

                  memset(log, 0, len + 1);
                  memcpy(log, offset, len);

                  result = rb_str_new2(log);
                  free(log);
               }
               break;

            case isc_info_truncated :
               done = 0;
               size = size * 2;
               break;
         }
      } while(*offset);

      /* Clean up. */
      free(output);

      /* Snooze if we're not done. */
      if(!done)
      {
         sleep(1);
      }
   }

   return(result);
}
