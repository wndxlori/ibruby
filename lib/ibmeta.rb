#-------------------------------------------------------------------------------
# ibmeta.rb
#-------------------------------------------------------------------------------
# Copyright © Peter Wood, 2005; Richard Vowles, 2006
#
# The contents of this file are subject to the Mozilla Public License Version
# 1.1 (the "License"); you may not use this file except in compliance with the
# License. You may obtain a copy of the License at
#
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
# the specificlanguage governing rights and  limitations under the License.
#
# The Original Code is the FireRuby extension for the Ruby language.
#
# The Initial Developer of the Original Code is Peter Wood. All Rights
# Reserved. All modifications (and all InterBaseMetaFunctions) are by Richard Vowles
# (richard@developers-inc.co.nz). 

module IBRuby
  class InterBaseIndex < Struct.new(:table, :name, :unique, :columns, :direction, :active) #:nodoc:
  
    INDEX_ACTIVE = :INDEX_ACTIVE
    INDEX_INACTIVE = :INDEX_INACTIVE

    def to_sql
      sql = "create"
      if unique == true
        sql << " unique"
      end
      sql << " index"
      
      if !@direction.nil?
        case @direction
          when InterBaseMetaFunction::ASCENDING
            sql << " asc"
          when InterBaseMetaFunction::DESCENDING
            sql << " desc"
        end
      end
      
      sql << " on #{@table} ("
      columns.each() do |col|
        sql << ", " unless col == columns.first
        sql << columns.name
      end
      
      sql << ")"
      
      sql
    end
    
    def create(conn)
      conn.execute_immediate(to_sql)
    end
    
    def rename(conn, new_name)
      old_name = @name
      @name = new_name
      begin
        create(conn)
        @name = old_name
        remove(conn)
      ensure
        @name = old_name
      end
    end
    
    def change_activation(conn, activation)
      sql = "alter index #{@name} "
      sql << (activation == InterBaseIndex::INDEX_ACTIVE) ? "active" : "inactive"
      conn.execute_immediate( sql )      
    end

    def remove(conn)
      conn.execute_immediate( "DROP INDEX #{name}" )
    end
  end
  
  class InterBaseTable 
    attr_reader :name, :columns, :indices
    
    def initialize(name, columns=[], indices=[])
      @name = name.upcase
      @columns = columns
      @indices = indices
    end
    
    def load(conn)
      @columns = InterBaseMetaFunctions.table_meta_data(conn,@name,true)
      @indices = InterBaseMetaFunctions.indices(conn,@name)
    end
    
    def create_table(conn)
      conn.execute_immediate( to_sql )
      
      if !indices.nil?
        indices.each() {|index| index.create(conn) }
      end
    end
    
    ## returns an array of sql required to create the table and all dependents
    def to_sql
      sql = []
      
      sql << to_sql_create_table
      
      if !indices.nil?
        indices.each() {|index| sql << index.to_sql }
      end
      
      sql.each() { |sqls| puts sqls }
      
      sql
    end
    
    private
    def to_sql_create_table
      sql = "create table #{name} ("
      
      if !columns.nil?
        columns.each() do |col|
          sql << ", " unless col == columns.first
          sql << col.to_sql
        end
      end
      
      sql << ")"
      
      puts sql
      sql
    end
  end
  
  # InterBaseMetaFunctions
  # Rather than requiring Ruby on Rails for access to these useful functions, I decided to move
  # them here instead.
  # 
  
  class InterBaseMetaFunctions
  
    ASCENDING = :ASCENDING
    DESCENDING = :DESCENDING
    
    def self.quote( value, column_meta_data )
      if column_meta_data.expects_quoting
        '#{value}'
      elsif ((column_meta_data.type == InterBaseColumn::BLOB) && (column_meta_data.sub_type != 1 ) )
        raise IBRubyException.new("'#{value}' is not a valid default for this column #{column_meta_data.name}.")
      else
        value
      end
    end
    
    
    def self.table_names(conn)
      tables = []
      
      conn.execute_immediate("select rdb$relation_name from rdb$relations where rdb$relation_name not starting 'RDB$' and rdb$flags=1") do |row|
        tables << ib_to_ar_case(row[0].to_s.rstrip)
      end
      
      tables
    end
    
    def self.indices(conn, table_name)
      indices = []
      
      # we must make sure the current transaction is committed, otherwise this won't work!
      indicesSQL = <<-END_SQL
      select rdb$index_name, rdb$unique_flag,RDB$INDEX_INACTIVE,RDB$INDEX_TYPE  from rdb$indices
         where rdb$relation_name = '#{table_name.to_s.upcase}' and rdb$index_name not starting 'RDB$PRIMARY'
      END_SQL
      
      #~ puts "SQL"
      #~ puts indicesSQL
      
      conn.execute_immediate(indicesSQL) do |row|
        #puts "index #{ib_to_ar_case(row[0].to_s.rstrip)}"
        indices << InterBaseIndex.new(table_name, ib_to_ar_case(row[0].to_s.rstrip), 
               row[1].to_i == 1, [], 
               (row[3] == 1)?InterBaseMetaFunctions::DESCENDING : InterBaseMetaFunctions::ASCENDING, 
               (row[2] == 1)?InterBaseIndex::INDEX_INACTIVE : InterBaseIndex::INDEX_ACTIVE)
      end
      
      #puts "Indices size #{indices.size}"
      
      if !indices.empty? 
        indices.each() do |index|
          sql = "select rdb$field_name from rdb$index_segments where rdb$index_name = '#{index.name.upcase}' order by rdb$index_name, rdb$field_position"
          
          #puts "index SQL: #{sql}"
          
          conn.execute_immediate(sql) do |row|
            index.columns << table_meta_data(conn, table_name, true, row[0].to_s.rstrip )
          end # each row in the index and get the InterBaseColumn
        end # each index
      end # if we found indices
      
      indices
    end
    
    def self.remove_index(conn, index_name)
      conn.execute_immediate( "DROP INDEX #{index_name}" )
    end
    
    # This class method fetches the type details for a named table. The
    # method returns a hash that links column names to InterBaseColumn objects.
    #
    # ==== Parameters
    # table::       A string containing the name of the table.
    # connection::  A reference to the connection to be used to determine
    #               the type information.
    # extract_ordered: if true then returns an ordered array of columns otherwise returns hash with col names
    # column_name: if true then returns a single column (not array or hash)
    #
    # ==== Exception
    # IBRubyException::  Generated if an invalid table name is specified
    #                      or an SQL error occurs.
    def self.table_meta_data(connection, table, extract_ordered = false, column_name = nil)
      # Check for naughty table names.
      if /\s+/ =~ table
        raise IBRubyException.new("'#{table}' is not a valid table name.")
      end
      
      extract_ordered = true if !column_name.nil?
      
      types     = extract_ordered ? [] : {}
      begin
        # r.rdb$field_source,
        sql = "SELECT r.rdb$field_name, f.rdb$field_type, "\
                 "f.rdb$field_length, f.rdb$field_precision, f.rdb$field_scale * -1, "\
                 "f.rdb$field_sub_type, "\
                 "COALESCE(r.rdb$default_source, f.rdb$default_source) rdb$default_source, "\
                 "COALESCE(r.rdb$null_flag, f.rdb$null_flag) rdb$null_flag, rdb$character_length "\
          "FROM rdb$relation_fields r "\
          "JOIN rdb$fields f ON r.rdb$field_source = f.rdb$field_name "\
          "WHERE r.rdb$relation_name = '#{table.to_s.upcase}'";
        
        if !column_name.nil?
          sql << " AND r.rdb$field_name = '#{column_name.to_s.upcase}'"
        elsif extract_ordered
          sql << " ORDER BY r.rdb$field_position"
        end
        
        puts "sql: #{sql}"
        
        #            sql = "SELECT RF.RDB$FIELD_NAME, F.RDB$FIELD_TYPE, "\
        #                  "F.RDB$FIELD_LENGTH, F.RDB$FIELD_PRECISION, "\
        #                  "F.RDB$FIELD_SCALE * -1, F.RDB$FIELD_SUB_TYPE "\
        #                  "FROM RDB$RELATION_FIELDS RF, RDB$FIELDS F "\
        #                  "WHERE RF.RDB$RELATION_NAME = UPPER('#{table}') "\
        #                  "AND RF.RDB$FIELD_SOURCE = F.RDB$FIELD_NAME"
        
        #connection.start_transaction do |tx|
        #  tx.execute(sql) 
        connection.execute_immediate(sql) do |row|
            sql_type   = InterBaseColumn.to_base_type(row[1], row[5])
            type       = nil
            field_name = row[0].strip
            
            #column_name, table_name, type, default_source=nil, null_flag=false, length=nil, precision=nil, scale=nil, sub_type=nil )
            #row[0], row
            case sql_type
            when InterBaseColumn::BLOB
              type = InterBaseColumn.new(field_name, table, sql_type, row[6], !row[7].nil?, nil, nil, nil, row[5] )
            when InterBaseColumn::CHAR, InterBaseColumn::VARCHAR
              type = InterBaseColumn.new(field_name, table, sql_type, row[6], !row[7].nil?, row[8] )
              # row[8] is the real length, field_length depends on the character set being used
            when InterBaseColumn::DECIMAL, InterBaseColumn::NUMERIC
              type = InterBaseColumn.new(field_name, table, sql_type, row[6], !row[7].nil?, nil, row[3], row[4] )
            else
              type = InterBaseColumn.new(field_name, table, sql_type, row[6], !row[7].nil? )
            end
            
            if extract_ordered
              types << type
            else
              types[field_name] = type
            end
            
            puts "col: #{type.to_sql}"
          end
          
        #end
      end
      if ( types.size > 1 )
        types
      elsif (types.size == 1)
        types[0]
      else
        nil
      end
    end
    
    
    # end of InterBaseMetaFunctions class
  end
  
  
  # This class is used to represent SQL table column tables.
  class InterBaseColumn
    # A definition for a base SQL type.
    BOOLEAN                          = :BOOLEAN
    
    # A definition for a base SQL type.
    BLOB                             = :BLOB
    
    # A definition for a base SQL type.
    CHAR                             = :CHAR
    
    # A definition for a base SQL type.
    DATE                             = :DATE
    
    # A definition for a base SQL type.
    DECIMAL                          = :DECIMAL
    
    # A definition for a base SQL type.
    DOUBLE                           = :DOUBLE
    
    # A definition for a base SQL type.
    FLOAT                            = :FLOAT
    
    # A definition for a base SQL type.
    INTEGER                          = :INTEGER
    
    # A definition for a base SQL type.
    NUMERIC                          = :NUMERIC
    
    # A definition for a base SQL type.
    SMALLINT                         = :SMALLINT
    
    # A definition for a base SQL type.
    TIME                             = :TIME
    
    # A definition for a base SQL type.
    TIMESTAMP                        = :TIMESTAMP
    
    # A definition for a base SQL type.
    VARCHAR                          = :VARCHAR
    
    # data type can be returned when arithmetic occurs, e.g. SMALLINT * -1 returns a INT64
    INT64                            = :INT64
    
    # Attribute accessor.
    attr_accessor :type, :length, :precision, :scale, :sub_type, :name, :table_name, :default, :not_null
    
    def self.expects_quoting(col)
      case col.type
        when InterBaseColumn::NUMERIC, InterBaseColumn::DECIMAL, InterBaseColumn::INTEGER, InterBaseColumn::DOUBLE, InterBaseColumn::FLOAT
          false
        when InterBaseColumn::CHAR, InterBaseColumn::VARCHAR
          true
        else
          if ((col.type == InterBaseColumn::BLOB) && (col.sub_type == 1 ) )
            true
          else
            nil
          end
      end
    end
    
    def expects_quoting
      InterBaseColumn.expects_quoting(self)
    end
    
    # This is the constructor for the InterBaseColumn class.
    #
    # ==== Parameters
    # type::       The base type for the InterBaseColumn object. Must be one of the
    #              base types defined within the class.
    # length::     The length setting for the type. Defaults to nil.
    # precision::  The precision setting for the type. Defaults to nil.
    # scale::      The scale setting for the type. Defaults to nil.
    # sub_type::    The SQL sub-type setting. Defaults to nil.
    # default_source:: the whole string "default xxx" or "default 'xxx'"
    # not_null:   true for NOT NULL, false for nulls allowed
    # actual_default:: if specified then we don't bother processing default_source
    def initialize(column_name, table_name, type, default_source=nil, not_null=false, length=nil, precision=nil, scale=nil, sub_type=nil, actual_default=nil )
      @name = column_name
      @table_name = table_name
      @not_null = not_null
      @type      = type
      @length    = length
      @precision = precision
      @scale     = scale
      @sub_type  = sub_type
      
      if !default_source.nil?
        match = Regexp.new( '^\s*DEFAULT\s+(.*)\s*', Regexp::IGNORECASE )
        matchData = match.match(default_source.to_s)
        @default = matchData[1]
        
        if @default && InterBaseColumn.expects_quoting(self)
          len = @default.size - 2
          @default = @default[1..len]
        end
      elsif actual_default
        @default = actual_default
      else
        @default = nil
      end
    end
    
    
    # This method overloads the equivalence test operator for the InterBaseColumn
    # class.
    #
    # ==== Parameters
    # object::  A reference to the object to be compared with.
    def ==(object)
      result = false
      if object.instance_of?(InterBaseColumn)
        result = (@type      == object.type &&
                  @length    == object.length &&
                  @precision == object.precision &&
                  @scale     == object.scale &&
                  @sub_type   == object.sub_type)
      end
      result
    end
    
    
    # This method generates a textual description for a InterBaseColumn object.
    def to_s
      if @type == InterBaseColumn::DECIMAL or @type == InterBaseColumn::NUMERIC
            "#{@type.id2name}(#{@precision},#{@scale})"
      elsif @type == InterBaseColumn::BLOB
            "#{@type.id2name} SUB TYPE #{@sub_type}"
      elsif @type == InterBaseColumn::CHAR or @type == InterBaseColumn::VARCHAR
            "#{@type.id2name}(#{@length})"
      else
        @type.id2name
      end
    end
    
    def to_sql
      sql = name + " " + to_s
      if @default
        sql << " default "
        equote = expects_quoting
        sql << "'" if equote
        sql << @default
        sql << "'" if equote
      end
      if @not_null == true
        sql << " not null"
      end
      sql      
      # all manner of other things, we are ignoring (e.g. check constraints)
    end
    
    def to_base_type
      InterBaseColumn.to_base_type(self.type, self.sub_type)
    end
    
    # This class method converts a InterBase internal type to a InterBaseColumn base
    # type.
    #
    # ==== Parameters
    # type::     A reference to the Interbase field type value.
    # sub_type::  A reference to the Interbase field subtype value.
    def self.to_base_type(type, subtype)
      case type
      when 16  #  DECIMAL, NUMERIC
        if subtype
          subtype == 1 ? InterBaseColumn::NUMERIC : InterBaseColumn::DECIMAL
        else
          InterBaseColumn::BIGINT
        end
      when 17  # BOOLEAN
        InterBaseColumn::BOOLEAN
        
      when 261 # BLOB
        InterBaseColumn::BLOB
        
      when 14  # CHAR
        InterBaseColumn::CHAR
        
      when 12  # DATE
        InterBaseColumn::DATE
        
      when 27  # DOUBLE, DECIMAL, NUMERIC
        if subtype
          subtype == 1 ? InterBaseColumn::NUMERIC : InterBaseColumn::DECIMAL
        else
          InterBaseColumn::DOUBLE
        end
        
      when 10  # FLOAT
        InterBaseColumn::FLOAT
        
      when 8   # INTEGER, DECIMAL, NUMERIC
        if subtype
          subtype == 1 ? InterBaseColumn::NUMERIC : InterBaseColumn::DECIMAL
        else
          InterBaseColumn::INTEGER
        end
        
      when 7   # SMALLINT, DECIMAL, NUMERIC
        if subtype
          subtype == 1 ? InterBaseColumn::NUMERIC : InterBaseColumn::DECIMAL
        else
          InterBaseColumn::SMALLINT
        end
        
      when 13  # TIME
        InterBaseColumn::TIME
        
      when 35  # TIMESTAMP
        InterBaseColumn::TIMESTAMP
        
      when 37  # VARCHAR
        InterBaseColumn::VARCHAR
      end
    end
    
    # we should also check to see if this table has indexes which need to be dropped and re-created
    # but the migrations user should really do that
    def rename( connection, new_column_name )
      connection.execute_immediate( "alter table #{@table_name} alter column #{@name} to #{new_column_name}" )
    end
    
    def change_column(conn, new_column)
      
      if new_column.type != self   # should use == defined above
        change_type_sql = "ALTER TABLE #{@table_name} alter column #{@name} type #{new_column.to_s}"
        conn.execute_immediate(change_type_sql)
      end

      if new_column.not_null != @not_null      
        # now change the NULL status, this may make the table invalid so...
        nullFlag = new_column.not_null ? "1" : "NULL"
        update_relations_fields_sql = 
           "UPDATE rdb$relation_fields set rdb$null_flags = #{nullFlag}"\
           " where rdb$relation_name='#{@table_name.upcase}' and "\
           "rdb$field_name='#{@name.upcase}'"
        conn.execute_immediate(update_relations_fields_sql)
      end
      
      # changed default or changed type
      if (new_column.default != @default) || (new_column.type != self)
        # now the default change, which is complicated!
        defaultSource = new_column.default.nil? ? "NULL" : ("default " << InterBaseMetaFunctions.quote(new_column.default, new_column ) )
        puts "alter table #{@table_name} add ib$$temp type #{new_column.to_s} #{defaultSource}"
        conn.execute_immediate("alter table #{@table_name} add ib$$temp #{new_column.to_s} #{defaultSource}")
        
        # standard hack to change the default type
        begin
          sql = <<-END_SQL
              update rdb$relation_fields set
              rdb$default_source=(select rdb$default_source from rdb$relation_fields where
                rdb$field_name='IB$$TEMP' and rdb$relation_name='#{@table_name.upcase}'),
              rdb$default_value=(select rdb$default_value from rdb$relation_fields where
                rdb$field_name='IB$$TEMP' and rdb$relation_name='#{@table_name.upcase}')
              where rdb$field_name='#{@name.upcase}' and rdb$relation_name='#{@table_name.upcase}';
          END_SQL
          conn.execute_immediate(sql)
        ensure
          conn.execute_immediate("alter table #{@table_name} drop ib$$temp" )
        end
       end
    end
    
  end # End of the InterBaseColumn class.
end # End of the IBRuby module.
