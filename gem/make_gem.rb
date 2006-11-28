#!/usr/bin/env ruby

require 'rubygems'
require 'fileutils'
require 'find'

include FileUtils

# Check the platform.
basedir       = File::dirname(Dir::getwd)
srcdir        = "#{basedir}#{File::SEPARATOR}src#{File::SEPARATOR}"
libdir        = "#{basedir}#{File::SEPARATOR}lib#{File::SEPARATOR}"
exmpdir       = "#{basedir}#{File::SEPARATOR}examples#{File::SEPARATOR}"
testdir       = "#{basedir}#{File::SEPARATOR}test#{File::SEPARATOR}"
library       = nil
platform      = nil
fileset       = []
major_version = 0
minor_version = 4
build_number  = 1
version       = "#{major_version}.#{minor_version}.#{build_number}"
if PLATFORM.include?('powerpc-darwin')
   library  = 'fireruby.bundle'
   platform = Gem::Platform::DARWIN
elsif PLATFORM.include?('win32')
   library  = 'fireruby.so'
   platform = Gem::Platform::WIN32
elsif PLATFORM.include?('linux')
   library  = 'fireruby.so'
   platform = Gem::Platform::LINUX_586
else
   raise "Unrecognised platform, gem creation cancelled."
end
gem = "fireruby-#{version}-#{platform}.gem"

# Check if we're not on Mac OS X.
if platform == Gem::Platform::DARWIN
   # Remove the .so library if it exists.
   if File.exist?("#{libdir}#{File::SEPARATOR}fireruby.so")
      puts "Removing the fireruby.so file from the lib directory."
      rm("#{libdir}fireruby.so")
   end
else
   # Remove the .bundle library if it exists.
   if File.exist?("#{libdir}#{File::SEPARATOR}fireruby.bundle")
      puts "Removing the fireruby.bundle file from the lib directory."
      rm("#{libdir}fireruby.bundle")
   end
end

# Remove any database file before creating the gem file.
puts "Removing unneeded database files."
Find.find(basedir) do |name|
   if /.+\.fdb$/.match(name) != nil
      rm(name)
   end
end


# Change to the base directory.
puts "Changing directory to #{basedir}."
Dir::chdir(basedir)

# Check that the library exists.
if File::exist?("#{srcdir}#{library}")
   puts "Copying '#{library}' into #{libdir}."
   if platform == Gem::Platform::DARWIN
      FileUtils::cp("#{srcdir}#{library}", "#{libdir}fr_lib.bundle")
   else
      FileUtils::cp("#{srcdir}#{library}", "#{libdir}fr_lib.so")
   end
else
   raise "The #{library} library file does not exist in the #{srcdir} directory."
end

# Generate the list of files.
fileset = Dir.glob("{lib,test,doc,examples}/**/*")

spec = Gem::Specification.new do |s|
   s.name             = 'fireruby'
   s.version          = version
   s.author           = 'Peter Wood'
   s.email            = 'paw220470@yahoo.ie'
   s.homepage         = 'http://rubyforge.org/projects/fireruby/'
   s.platform         = platform
   s.summary          = 'Ruby interface library for the Firebird database.'
   s.description      = 'FireRuby is an extension to the Ruby programming '\
                        'language that provides access to the Firebird open '\
                        'source RDBMS. FireRuby is based in the Firebird C '\
                        'API and has no additional dependencies. The FireRuby '\
                        'library wraps the API calls in a Ruby OO interface.'
   s.files            = fileset
   s.require_path     = 'lib'
   s.autorequire      = 'fireruby'
   s.test_files       = ["test#{File::SEPARATOR}UnitTest.rb"]
   s.has_rdoc         = true
   s.rdoc_options     = ["--main", "doc/README"]
   s.extra_rdoc_files = ["doc/README"]
end

Gem::manage_gems
Gem::Builder.new(spec).build
