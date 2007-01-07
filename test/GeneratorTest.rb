#!/usr/bin/env ruby

require 'TestSetup'
require 'test/unit'
#require 'rubygems'
require 'ibruby'

include IBRuby

class GeneratorTest < Test::Unit::TestCase
   CURDIR  = "#{Dir.getwd}"
   DB_FILE = "#{CURDIR}#{File::SEPARATOR}generator_unit_test.ib"
   
   def setup
      puts "#{self.class.name} started." if TEST_LOGGING
      if File::exist?(DB_FILE)
         Database.new(DB_FILE).drop(DB_USER_NAME, DB_PASSWORD)
      end
      @database     = Database::create(DB_FILE, DB_USER_NAME, DB_PASSWORD)
      @connections  = []
      
      @connections.push(@database.connect(DB_USER_NAME, DB_PASSWORD))
   end
   
   def teardown
      @connections.each do |cxn|
         cxn.close if cxn.open?
      end
      @connections.clear
      if File::exist?(DB_FILE)
         Database.new(DB_FILE).drop(DB_USER_NAME, DB_PASSWORD)
      end
      puts "#{self.class.name} finished." if TEST_LOGGING
   end
   
   def test01
      assert(Generator::exists?('TEST_GEN', @connections[0]) == false)
      g = Generator::create('TEST_GEN', @connections[0])
      10.times() { assert(Generator::exists?('TEST_GEN', @connections[0])) }
      assert(g.last == 0)
      assert(g.next(1) == 1)
      assert(g.last == 1)
      assert(g.next(10) == 11)
      assert(g.connection == @connections[0])
      assert(g.name == 'TEST_GEN')
      
      g.drop
      assert(Generator::exists?('TEST_GEN', @connections[0]) == false)
    end
    
    def test02
      4.times() do 
        @connections[0].execute_immediate( 'create table sample(a integer not null)' )
        @connections[0].execute_immediate( 'alter table sample add primary key (a)' )
        assert(Generator::exists?('SAMPLE_GEN', @connections[0]) == false)
        g = Generator::create('SAMPLE_GEN', @connections[0])
        g.drop
        @connections[0].execute_immediate( 'drop table sample' )
      end
    end
end
