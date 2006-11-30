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
         
         begin
           stmt.execute_for(['fred'])
           assert(false); # should never get here
        rescue IBRuby::IBRubyException => boom
           puts "Properly handled exception #{boom.message}" if TEST_LOGGING
           assert(true);
        end
      end
     end

    # does tests for proper handling of string names for booleans (true/false)
    def test04
      @connection.start_transaction do |tx|
         stmt = Statement.new(@connection, tx,
                              "insert into bool_types values(?)",
                              3)
         
         begin
           assert( stmt.execute_for(['false']) == 1 )
           assert( stmt.execute_for(['False']) == 1 )
           assert( stmt.execute_for(['true']) == 1 )
           assert( stmt.execute_for(['True']) == 1 )
        rescue IBRuby::IBRubyException
           assert(false); # should not throw exception using string names
        end
      end
     end


   def teardown
      @connection.close
      #~ if File::exist?(DB_FILE)
         #~ Database.new(DB_FILE).drop(DB_USER_NAME, DB_PASSWORD)
      #~ end
      puts "#{self.class.name} finished." if TEST_LOGGING
   end
   
   #~ def test01
      #~ row = Row.new(@results, @empty, 100)
      
      #~ assert(row.column_count == 28)
      #~ assert(row.number == 100)
      #~ assert(row.column_name(0) == 'RDB$FIELD_NAME')
      #~ assert(row.column_alias(10) == 'RDB$FIELD_TYPE')
      #~ assert(row[0] == 0)
      #~ assert(row['RDB$FIELD_TYPE'] == 0)
   #~ end
   
   #~ def test02
      #~ sql  = 'select COL01 one, COL02 two, COL03 three from rowtest'
      #~ rows = @connection.execute_immediate(sql)
      #~ data = rows.fetch
      
      #~ count = 0
      #~ data.each do |name, value|
         #~ assert(['ONE', 'TWO', 'THREE'].include?(name))
         #~ assert([1, 'Two', 3].include?(value))
         #~ count += 1
      #~ end
      #~ assert(count == 3)
      
      #~ count = 0
      #~ data.each_key do |name|
         #~ assert(['ONE', 'TWO', 'THREE'].include?(name))
         #~ count += 1
      #~ end
      #~ assert(count == 3)
      
      #~ count = 0
      #~ data.each_value do |value|
         #~ assert([1, 'Two', 3].include?(value))
         #~ count += 1
      #~ end
      #~ assert(count == 3)
      
      #~ assert(data.fetch('TWO') == 'Two')
      #~ assert(data.fetch('FOUR', 'LALALA') == 'LALALA')
      #~ assert(data.fetch('ZERO') {'NOT FOUND'} == 'NOT FOUND')
      #~ begin
         #~ data.fetch('FIVE')
         #~ assert(false, 'Row#fetch succeeded for non-existent column name.')
      #~ rescue IndexError
      #~ end
      
      #~ assert(data.has_key?('ONE'))
      #~ assert(data.has_key?('TEN') == false)
      
      #~ assert(data.has_column?('COL02'))
      #~ assert(data.has_column?('COL22') == false)
      
      #~ assert(data.has_alias?('TWO'))
      #~ assert(data.has_alias?('FOUR') == false)
      
      #~ assert(data.has_value?(3))
      #~ assert(data.has_value?('LALALA') == false)
      
      #~ assert(data.keys.size == 3)
      #~ data.keys.each do |name|
         #~ assert(['ONE', 'TWO', 'THREE'].include?(name))
      #~ end
      
      #~ assert(data.names.size == 3)
      #~ data.names.each do |name|
         #~ assert(['COL01', 'COL02', 'COL03'].include?(name))
      #~ end

      #~ assert(data.aliases.size == 3)
      #~ data.aliases.each do |name|
         #~ assert(['ONE', 'TWO', 'THREE'].include?(name))
      #~ end
      
      #~ assert(data.values.size == 3)
      #~ data.values.each do |value|
         #~ assert([1, 'Two', 3].include?(value))
      #~ end
      
      #~ array = data.select {|name, value| name == 'TWO'}
      #~ assert(array.size == 1)
      #~ assert(array[0][0] == 'TWO')
      #~ assert(array[0][1] == 'Two')
      
      #~ array = data.to_a
      #~ assert(array.size == 3)
      #~ assert(array.include?(['ONE', 1]))
      #~ assert(array.include?(['TWO', 'Two']))
      #~ assert(array.include?(['THREE', 3]))
      
      #~ hash = data.to_hash
      #~ assert(hash.length == 3)
      #~ assert(hash['ONE'] == 1)
      #~ assert(hash['TWO'] == 'Two')
      #~ assert(hash['THREE'] == 3)
      
      #~ array = data.values_at('TEN', 'TWO', 'THREE')
      #~ assert(array.size == 3)
      #~ assert(array.include?('Two'))
      #~ assert(array.include?(3))
      #~ assert(array.include?(nil))
      
      #~ rows.close
   #~ end
   
   #~ def test03
      #~ results = nil
      #~ row     = nil
      
      #~ begin
         #~ results = @connection.execute_immediate('select * from all_types')
         
         #~ row     = results.fetch
         
         #~ assert(row.get_base_type(0) == SQLType::BOOLEAN)
         #~ assert(row.get_base_type(1) == SQLType::BLOB)
         #~ assert(row.get_base_type(2) == SQLType::CHAR)
         #~ assert(row.get_base_type(3) == SQLType::DATE)
         #~ assert(row.get_base_type(4) == SQLType::DECIMAL)
         #~ assert(row.get_base_type(5) == SQLType::DOUBLE)
         #~ assert(row.get_base_type(6) == SQLType::FLOAT)
         #~ assert(row.get_base_type(7) == SQLType::INTEGER)
         #~ assert(row.get_base_type(8) == SQLType::NUMERIC)
         #~ assert(row.get_base_type(9) == SQLType::SMALLINT)
         #~ assert(row.get_base_type(10) == SQLType::TIME)
         #~ assert(row.get_base_type(11) == SQLType::TIMESTAMP)
         #~ assert(row.get_base_type(12) == SQLType::VARCHAR)
         
      #~ ensure
         #~ results.close if results != nil
      #~ end
   #~ end
end
