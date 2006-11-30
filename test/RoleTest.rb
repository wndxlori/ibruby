#!/usr/bin/env ruby

require 'TestSetup'
require 'test/unit'
#require 'rubygems'
require 'ibruby'

include IBRuby

# This test case isn't working as I cannot get the basic operation of roles to work under ISQL so I am unsure
# how they are supposed to work.

class DatabaseTest < Test::Unit::TestCase
   CURDIR      = "#{Dir.getwd}"
   DB_FILE     = "#{CURDIR}#{File::SEPARATOR}role_unit_test.ib"
   
   def setup
      puts "#{self.class.name} started." if TEST_LOGGING
      if File.exist?(DB_FILE)
         db = Database.new(DB_FILE)
         db.drop
      end

#connect "role_unit_test.ib" user "newuser" password "password" role "sales";
#insert into sales_test values(1);
      #create the user we will use to grant permission to
      sm = ServiceManager.new('localhost')
      sm.connect(DB_USER_NAME, DB_PASSWORD)

      au = AddUser.new('newuser', 'password', 'first', 'middle', 'last')
      au.execute(sm)
      
      @database = Database::create(DB_FILE, DB_USER_NAME, DB_PASSWORD, 1024, 'ASCII')
      
      @connection = @database.connect(DB_USER_NAME, DB_PASSWORD)
      @connection.execute_immediate( 'create role sales' )
      @connection.execute_immediate( 'create table sales_test(sales_drone integer)' )
      @connection.execute_immediate( 'grant insert on sales_test to sales' )
      # no permission to this table (notsales)
      @connection.execute_immediate( 'create table notsales(sales_drone integer)' )
      # add 'newuser' into sales role
      @connection.execute_immediate( 'grant sales to newuser' )
      @connection.close
   end
   
   def teardown
      #~ if File::exist?(DB_FILE)
         #~ db = Database.new(DB_FILE)
         #~ db.drop(DB_USER_NAME, DB_PASSWORD)
      #~ end
      puts "#{self.class.name} finished." if TEST_LOGGING
   end
   
   
   #test we can connect with the role
   def test01
     
   end
   
end
