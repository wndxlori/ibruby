#!/usr/bin/env ruby
require 'mkmf'

# Add the framework link for Mac OS X.
if PLATFORM.include?("win32")
   $LDFLAGS = $LDFLAGS + "gds32_ms.lib"
   $CFLAGS  = $CFLAGS + " -DOS_WIN32"
   dir_config("win32")
   dir_config("winsdk")
   dir_config("dotnet")
elsif PLATFORM.include?("linux")
   $LDFLAGS = $LDFLAGS + " -lgds"
   $CFLAGS  = $CFLAGS + " -DOS_UNIX"
end

# Make sure the interbase stuff is included.
dir_config("interbase2007")

# Generate the Makefile.
create_makefile("ib_lib")
