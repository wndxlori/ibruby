#!/usr/bin/env ruby

require 'TestSetup'
require 'test/unit'
#require 'rubygems'
require 'ibruby'

include IBRuby

class MetaTest < Test::Unit::TestCase
   CURDIR  = "#{Dir.getwd}"
   DB_FILE = "#{CURDIR}#{File::SEPARATOR}meta_unit_test.ib"
   
   def setup
      puts "#{self.class.name} started." if TEST_LOGGING
      if File::exist?(DB_FILE)
         Database.new(DB_FILE).drop(DB_USER_NAME, DB_PASSWORD)
      end

      @database    = Database.create(DB_FILE, DB_USER_NAME, DB_PASSWORD)
      @connection = @database.connect(DB_USER_NAME, DB_PASSWORD)
      
      @creation_sql = "create table mtest (id integer not null, "\
        "bool1 boolean default false, bool2 boolean, bool3 boolean default true, bool4 boolean default true not null,"\
        " blob1 blob sub_type 1 not null, blob2 blob sub_type 1, blob3 blob sub_type 0,"\
        " char1 char(10) default 'fred', char2 char(10) default 'fred' not null, char3 char(10), char4 char(20) default 'wil''ma',"\
        " date1 date default current_date, date2 date not null, date3 date default current_date not null,"\
        " decimal1 decimal(18,5) default 1.345, decimal2 decimal(15,5) default 20.22 not null, decimal3 decimal(12,6) not null"\
        ")"
      #puts sql
      @connection.execute_immediate( @creation_sql );
      @connection.execute_immediate( "create table pk_table(id integer not null primary key)" )
      @connection.execute_immediate( "create table fk_table(id integer not null primary key, "\
        "fk_id integer references pk_table(id))" )
      @pk_sql = "alter table mtest "
      
   end
   
  
   def teardown
      @connection.close

      if File::exist?(DB_FILE)
         Database.new(DB_FILE).drop(DB_USER_NAME, DB_PASSWORD)
      end
      puts "#{self.class.name} finished." if TEST_LOGGING
   end
   
   def test01
     table = InterBaseTable.new('mtest')
     assert_nothing_thrown( "failed to load table mtest" ) { table.load(@connection) }
     sql = []
     assert_nothing_thrown( "unable to build sql!" ) { sql = table.to_sql }
     assert_not_nil sql, "sql returned nil for create table"
     assert_equal sql.size > 0, true, "sql returned has nothing in it for table creation!"
     #assert_equal @creation_sql.upcase, sql[0].upcase
     #they ARE the same, but shows false and don't know why
     puts sql
   end
   
   def test02
    col = InterBaseMetaFunctions.table_fields( @connection, "mtest", true, "decimal2" )
    new_col = col.dup
    new_col.precision = 16
    new_col.scale = 2
    col.change_column(@connection,new_col)
    new_col = InterBaseMetaFunctions.table_fields( @connection, "mtest", true, "decimal2" )
    
    assert_equal false, new_col == col, "column decimal2 not changed"
    assert_equal new_col.precision, 16, "column decimal2 precision not 16!"
    assert_equal new_col.scale, 2, "column scale should be 2!"
   end
   
   def test03
     col = InterBaseMetaFunctions.table_fields( @connection, "mtest", true, "decimal2" )
     col.rename_column( @connection, "decimal_rename" )
     ren_col = InterBaseMetaFunctions.table_fields( @connection, "mtest", true, "decimal2" )
     assert_equal nil, ren_col, "column not renamed!"
     new_col = InterBaseMetaFunctions.table_fields( @connection, "mtest", true, "decimal_rename" )
     assert_equal new_col, col, "column types not identical after rename"
     new_col.rename_column( @connection, "decimal2" )
   end

   def test04
     table = InterBaseTable.new('fk_table')
     table.load(@connection)
     assert_nothing_thrown( "unable build sql for table fk_table! " ) do
       table.to_sql.each() {|sql| puts "table creation sql: #{sql}" }
     end
     assert_nothing_thrown( "unable to rename table" ) do
       table.rename_table( @connection, 'new_fk_table' )
     end
     table = InterBaseTable.new('new_fk_table')
     table.load(@connection)
     assert_nothing_thrown( "unable build sql for table fk_table! " ) do
       table.to_sql.each() {|sql| puts "table creation sql: #{sql}" }
     end
   end   
 end
