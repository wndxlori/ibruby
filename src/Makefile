
SHELL = /bin/sh

#### Start of system configuration section. ####

srcdir = .
topdir = e:/ruby_bcc32/lib/ruby/1.8/i386-bccwin32
hdrdir = $(topdir)
VPATH = $(srcdir);$(topdir);$(hdrdir)

DESTDIR = e:
prefix = $(DESTDIR)/ruby_bcc32
exec_prefix = $(prefix)
sitedir = $(prefix)/lib/ruby/site_ruby
rubylibdir = $(libdir)/ruby/$(ruby_version)
top_srcdir = $(DESTDIR)./
archdir = $(rubylibdir)/$(arch)
sbindir = $(exec_prefix)/sbin
datadir = $(prefix)/share
includedir = $(prefix)/include
infodir = $(prefix)/info
sysconfdir = $(prefix)/etc
mandir = $(prefix)/man
libdir = $(exec_prefix)/lib
sharedstatedir = $(DESTDIR)/etc
oldincludedir = $(DESTDIR)/usr/include
sitearchdir = $(sitelibdir)/$(sitearch)
localstatedir = $(DESTDIR)/var
bindir = $(exec_prefix)/bin
sitelibdir = $(sitedir)/$(ruby_version)
libexecdir = $(exec_prefix)/libexec

CC = bcc32
LIBRUBY = $(RUBY_SO_NAME).lib
LIBRUBY_A = $(RUBY_SO_NAME)-static.lib
LIBRUBYARG_SHARED = $(LIBRUBY)
LIBRUBYARG_STATIC = $(LIBRUBY_A)

RUBY_EXTCONF_H = 
CFLAGS   =  -q -tWR -tWC  -O -6 -w- -wsus -wcpt -wdup -wext -wrng -wrpt -wzdi -I"C:\Program Files\Borland\BDS\4.0\include" -L"C:\Program Files\Borland\BDS\4.0\lib" -DOS_WIN32 
INCFLAGS = -I. -I$(topdir) -I$(hdrdir) -I$(srcdir) -I"c:\program files\borland\interbase2007\sdk\include"
CPPFLAGS =  
CXXFLAGS = $(CFLAGS) 
DLDFLAGS = gds32.lib -Tpd c0d32.obj 
LDSHARED = ilink32 -q -Gn -L. -L"C:\Program Files\Borland\BDS\4.0\lib" -L"c:\program files\borland\interbase2007\sdk\lib"
AR = tlib
EXEEXT = .exe

RUBY_INSTALL_NAME = ruby
RUBY_SO_NAME = bccwin32-ruby18
arch = i386-bccwin32
sitearch = i386-bccwin32
ruby_version = 1.8
ruby = e:/ruby_bcc32/bin/ruby
RUBY = $(ruby:/=\)
RM = $(RUBY) -run -e rm -- -f
!ifndef MAKEDIRS
MAKEDIRS = @$(RUBY) -run -e mkdir -- -p
!endif
INSTALL = copy > nul
!ifndef INSTALL_PROG
INSTALL_PROG = $(INSTALL)
!endif
!ifndef INSTALL_DATA
INSTALL_DATA = $(INSTALL)
!endif
COPY = copy > nul

#### End of system configuration section. ####

preload = 

libpath = $(libdir)
LIBPATH =  -L"$(libdir)"
DEFFILE = $(TARGET)-$(arch).def

CLEANFILES = 
DISTCLEANFILES = $(DEFFILE)

extout = 
extout_prefix = 
target_prefix = 
LOCAL_LIBS = 
LIBS = $(LIBRUBYARG_SHARED)   cw32i.lib import32.lib ws2_32.lib  
SRCS = AddUser.c Backup.c Blob.c Common.c Connection.c DataArea.c Database.c Generator.c IBRuby.c IBRubyException.c RemoveUser.c Restore.c ResultSet.c Row.c ServiceManager.c Services.c Statement.c Transaction.c TypeMap.c
OBJS = AddUser.obj Backup.obj Blob.obj Common.obj Connection.obj DataArea.obj Database.obj Generator.obj IBRuby.obj IBRubyException.obj RemoveUser.obj Restore.obj ResultSet.obj Row.obj ServiceManager.obj Services.obj Statement.obj Transaction.obj TypeMap.obj
TARGET = ib_lib
DLLIB = $(TARGET).so
EXTSTATIC = 
STATIC_LIB = 

RUBYCOMMONDIR = $(sitedir)$(target_prefix)
RUBYLIBDIR    = $(sitelibdir)$(target_prefix)
RUBYARCHDIR   = $(sitearchdir)$(target_prefix)

TARGET_SO     = $(DLLIB)
CLEANLIBS     = $(TARGET).so $(TARGET).il? $(TARGET).tds $(TARGET).map
CLEANOBJS     = *.obj *.lib *.s[ol] *.pdb *.exp *.bak

all:		$(DLLIB)
static:		$(STATIC_LIB)

clean:
		@-$(RM) $(CLEANLIBS:/=\) $(CLEANOBJS:/=\) $(CLEANFILES:/=\)

distclean:	clean
		@-$(RM) Makefile $(RUBY_EXTCONF_H) conftest.* mkmf.log
		@-$(RM) core ruby$(EXEEXT) *~ $(DISTCLEANFILES:/=\)

realclean:	distclean
install: install-so install-rb

install-so: $(RUBYARCHDIR)
install-so: $(RUBYARCHDIR)/$(DLLIB)
$(RUBYARCHDIR)/$(DLLIB): $(DLLIB)
	$(INSTALL_PROG) $(DLLIB:/=\) $(RUBYARCHDIR:/=\)
install-rb: pre-install-rb install-rb-default
install-rb-default: pre-install-rb-default
pre-install-rb: Makefile
pre-install-rb-default: Makefile
$(RUBYARCHDIR):
	$(MAKEDIRS) $@

site-install: site-install-so site-install-rb
site-install-so: install-so
site-install-rb: install-rb

.path.c = $(VPATH)
.path.m = $(VPATH)
.path.cccxxcpp = $(VPATH)
.SUFFIXES: .c .m .cc .cxx .cpp .obj

{$(srcdir)}.cc{}.obj:
	$(CXX) $(INCFLAGS) $(CXXFLAGS) $(CPPFLAGS) -P -c $(<:/=\)

{$(topdir)}.cc{}.obj:
	$(CXX) $(INCFLAGS) $(CXXFLAGS) $(CPPFLAGS) -P -c $(<:/=\)

{$(hdrdir)}.cc{}.obj:
	$(CXX) $(INCFLAGS) $(CXXFLAGS) $(CPPFLAGS) -P -c $(<:/=\)

.cc.obj:
	$(CXX) $(INCFLAGS) $(CXXFLAGS) $(CPPFLAGS) -P -c $(<:/=\)

{$(srcdir)}.cxx{}.obj:
	$(CXX) $(INCFLAGS) $(CXXFLAGS) $(CPPFLAGS) -P -c $(<:/=\)

{$(topdir)}.cxx{}.obj:
	$(CXX) $(INCFLAGS) $(CXXFLAGS) $(CPPFLAGS) -P -c $(<:/=\)

{$(hdrdir)}.cxx{}.obj:
	$(CXX) $(INCFLAGS) $(CXXFLAGS) $(CPPFLAGS) -P -c $(<:/=\)

.cxx.obj:
	$(CXX) $(INCFLAGS) $(CXXFLAGS) $(CPPFLAGS) -P -c $(<:/=\)

{$(srcdir)}.cpp{}.obj:
	$(CXX) $(INCFLAGS) $(CXXFLAGS) $(CPPFLAGS) -P -c $(<:/=\)

{$(topdir)}.cpp{}.obj:
	$(CXX) $(INCFLAGS) $(CXXFLAGS) $(CPPFLAGS) -P -c $(<:/=\)

{$(hdrdir)}.cpp{}.obj:
	$(CXX) $(INCFLAGS) $(CXXFLAGS) $(CPPFLAGS) -P -c $(<:/=\)

.cpp.obj:
	$(CXX) $(INCFLAGS) $(CXXFLAGS) $(CPPFLAGS) -P -c $(<:/=\)

{$(srcdir)}.c{}.obj:
	$(CC) $(INCFLAGS) $(CFLAGS) $(CPPFLAGS) -c $(<:/=\)

{$(topdir)}.c{}.obj:
	$(CC) $(INCFLAGS) $(CFLAGS) $(CPPFLAGS) -c $(<:/=\)

{$(hdrdir)}.c{}.obj:
	$(CC) $(INCFLAGS) $(CFLAGS) $(CPPFLAGS) -c $(<:/=\)

.c.obj:
	$(CC) $(INCFLAGS) $(CFLAGS) $(CPPFLAGS) -c $(<:/=\)

$(DLLIB): $(DEFFILE) $(OBJS)
	@-$(RM) $@
	$(LDSHARED) $(DLDFLAGS) $(LIBPATH) $(OBJS), $(@:/=\), nul, $(LIBS) $(LOCAL_LIBS), $(DEFFILE), $(RESFILE)



$(DEFFILE): 
	$(RUBY) -e "puts 'EXPORTS', '_Init_$(TARGET)'"  > $@

$(OBJS): {.;$(VPATH)}ruby.h {.;$(VPATH)}defines.h
