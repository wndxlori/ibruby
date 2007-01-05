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
minor_version = 5
build_number  = 3
version       = "#{major_version}.#{minor_version}.#{build_number}"
library  = 'ib_lib.so'
if PLATFORM.include?('win32')
   platform = Gem::Platform::WIN32
elsif PLATFORM.include?('linux')
   platform = Gem::Platform::LINUX_586
else
   raise "Unrecognised platform, gem creation cancelled."
end
gem = "ibruby-#{version}-#{platform}.gem"

# Check if we're not on Mac OS X.
   # Remove the .bundle library if it exists.
   if File.exist?("#{libdir}#{File::SEPARATOR}ibruby.bundle")
      puts "Removing the ibruby.bundle file from the lib directory."
      rm("#{libdir}ibruby.bundle")
   end

# Remove any database file before creating the gem file.
puts "Removing unneeded database files."
Find.find(basedir) do |name|
   if /.+\.ib$/.match(name) != nil
      rm(name)
   end
end


# Change to the base directory.
puts "Changing directory to #{basedir}."
Dir::chdir(basedir)

# Check that the library exists.
if File::exist?("#{srcdir}#{library}")
   puts "Copying '#{library}' into #{libdir}."
   FileUtils::cp("#{srcdir}#{library}", "#{libdir}ib_lib.so")
else
   raise "The #{library} library file does not exist in the #{srcdir} directory."
end

# Generate the list of files.
fileset = Dir.glob("{lib,test,doc,examples}/**/*")

spec = Gem::Specification.new do |s|
   s.name             = 'ibruby'
   s.version          = version
   s.author           = 'Peter Wood, Richard Vowles'
   s.email            = 'paw220470@yahoo.ie, richard@developers-inc.co.nz'
   s.homepage         = 'http://rubyforge.org/projects/ibruby/'
   s.platform         = platform
   s.summary          = 'Ruby interface library for the InterBase database.'
   s.description      = 'IBRuby is an extension to the Ruby programming '\
                        'language that provides access to the InterBase '\
                        'RDBMS. IBRuby is based in the InterBase C '\
                        'API and has no additional dependencies. The IBRuby '\
                        'library wraps the API calls in a Ruby OO interface.'
   s.files            = fileset
   s.require_path     = 'lib'
   s.autorequire      = 'ibruby'
   s.test_files       = ["test#{File::SEPARATOR}UnitTest.rb"]
   s.has_rdoc         = true
   s.rdoc_options     = ["--main", "doc/README"]
   s.extra_rdoc_files = ["doc/README"]
end

Gem::manage_gems
Gem::Builder.new(spec).build
