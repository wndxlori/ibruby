#!/usr/bin/env ruby

require 'TestSetup'
require 'test/unit'
#require 'rubygems'
require 'ibruby'

include IBRuby

class RowTest < Test::Unit::TestCase
   CURDIR  = "#{Dir.getwd}"
   DB_FILE = "#{CURDIR}#{File::SEPARATOR}boolean_unit_test.ib"
   
   def setup
      puts "#{self.class.name} started." if TEST_LOGGING
      if File::exist?(DB_FILE)
         Database.new(DB_FILE).drop(DB_USER_NAME, DB_PASSWORD)
      end
      
      database     = Database::create(DB_FILE, DB_USER_NAME, DB_PASSWORD)
      @connection  = database.connect(DB_USER_NAME, DB_PASSWORD)
      
      @connection.start_transaction do |tx|
         tx.execute('create table bool_types (col01 boolean)')
      end
    end

    # test to ensure we can insert boolean data directly in
    def test01
      @connection.start_transaction do |tx|
         tx.execute("delete from bool_types")
       end
      @connection.start_transaction do |tx|
         tx.execute("insert into bool_types values (false)")
         tx.execute("insert into bool_types values (true)")
         tx.execute("insert into bool_types values (null)")
       end
       
       checkBooleanValues
    end
    
    def checkBooleanValues
      sql = "select col01 from bool_types"
      rows = @connection.execute_immediate(sql)
      row = rows.fetch
      assert(row != nil )
      assert(row[0] == false)
      row = rows.fetch
      assert(row != nil )
      assert(row[0] == true)
      row = rows.fetch
      assert(row != nil )
      assert(row[0]==nil)
      
      rows.close
    end
    
    #test to ensure we can insert boolean data in using 
    def test02
      @connection.start_transaction do |tx|
         tx.execute("delete from bool_types")
       end
      @connection.start_transaction do |tx|
         stmt = Statement.new(@connection, tx,
                              "insert into bool_types values(?)",
                              3)
         
         stmt.execute_for([false])
         stmt.execute_for([true])
         stmt.execute_for([nil])
       end
       
       checkBooleanValues
     end
     
     #ensures that non-valid string names cause exceptions to be thrown
    def test03
      @connection.start_transaction do |tx|
         stmt = Statement.new(@connection, tx,
                              "insert into bool_types values(?)",
                              3)
        
         assert_raise(IBRuby::IBRubyException) do 
           stmt.execute_for(['fred'])
        end
      end
     end

    # does tests for proper handling of string names for booleans (true/false)
    def test04
      @connection.start_transaction do |tx|
         stmt = Statement.new(@connection, tx,
                              "insert into bool_types values(?)",
                              3)
        
	assert_nothing_raised() do 
           assert( stmt.execute_for(['false']) == 1 )
           assert( stmt.execute_for(['False']) == 1 )
           assert( stmt.execute_for(['true']) == 1 )
           assert( stmt.execute_for(['True']) == 1 )
        end
      end
     end


   def teardown
      @connection.close
      if File::exist?(DB_FILE)
         Database.new(DB_FILE).drop(DB_USER_NAME, DB_PASSWORD)
      end
      puts "#{self.class.name} finished." if TEST_LOGGING
   end
end
