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
         db.drop(DB_USER_NAME, DB_PASSWORD)
      end

#connect "role_unit_test.ib" user "newuser" password "password" role sales;
#insert into sales_test values(1);
      Database::create(DB_FILE, DB_USER_NAME, DB_PASSWORD)
      createUser
      createRoleAndAllocate
    end
    
    def createUser
      #create the user we will use to grant permission to
      sm = ServiceManager.new('localhost')
      sm.connect(DB_USER_NAME, DB_PASSWORD)

      au = AddUser.new('newuser', 'password', 'first', 'middle', 'last')
      au.execute(sm)
      sm.disconnect
    end
    
    def createRoleAndAllocate
      database = Database::new(DB_FILE)
      @connection = database.connect(DB_USER_NAME, DB_PASSWORD)
      @connection.execute_immediate( 'create role sales' )
      @connection.execute_immediate( 'create table sales_test(sales_drone integer)' )
      @connection.execute_immediate( 'grant insert on sales_test to sales' )
      # no permission to this table (notsales)
      @connection.execute_immediate( 'create table notsales(sales_drone integer)' )
      # add 'newuser' into sales role
      @connection.execute_immediate( 'grant sales to newuser' )
      @connection.close
    end
    
    def dropRole
     database = Database::new(DB_FILE)
     @connection = database.connect(DB_USER_NAME, DB_PASSWORD)
     @connection.execute_immediate( 'drop role sales' )
     @connection.close
   end
   
   def dropUser
      sm = ServiceManager.new('localhost')
      sm.connect(DB_USER_NAME, DB_PASSWORD)

      au = RemoveUser.new('newuser')
      au.execute(sm)
      sm.disconnect
   end
   
   def teardown
      dropRole
      dropUser
      
      #~ if File::exist?(DB_FILE)
         #~ db = Database.new(DB_FILE)
         #~ db.drop(DB_USER_NAME, DB_PASSWORD)
      #~ end
      puts "#{self.class.name} finished." if TEST_LOGGING
   end
      
   #test we can connect with the role
   def test02
     database = Database::new(DB_FILE)
     @connection = database.connect('newuser', 'password', Connection::ROLE => 'SALES' )
     assert_nothing_raised() do
     
       assert(@connection.execute_immediate( 'insert into sales_test values(1)' ) == 1 )
     
     end
     @connection.close
   end
   
   def test01
     database = Database::new(DB_FILE)
     @connection = database.connect('newuser', 'password' )
     assert_raise(IBRuby::IBRubyException) do
       @connection.execute_immediate( 'insert into sales_test values(10)' )
       
       puts "No role passed but can insert into sales_test!" if TEST_LOGGING
     end
     @connection.close
   end
   
end
