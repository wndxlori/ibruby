#-------------------------------------------------------------------------------
# ibmeta.rb
#-------------------------------------------------------------------------------
# Copyright � Peter Wood, 2005; Richard Vowles, 2006
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
  class InterBaseIndex
  
    attr_accessor :table, :name, :unique, :columns, :direction, :active
    
    def initialize(table, name, unique, columns, direction = nil, active = nil)
      @table = table
      @name = name
      @unique = unique
      @columns = columns
      @direction = direction
      @active = active
    end
  
    INDEX_ACTIVE = :INDEX_ACTIVE
    INDEX_INACTIVE = :INDEX_INACTIVE

    def to_sql
      sql = "create"
      if unique == true
        sql << " unique"
      end
      if @direction
        case @direction
          when InterBaseMetaFunctions::ASCENDING
            sql << " asc"
          when InterBaseMetaFunctions::DESCENDING
            sql << " desc"
        end
      end
      
      sql << " index"
      
      sql << " #{@name}"
      
      sql << " on #{@table} ("
      columns.each() do |col|
        sql << ", " unless col == columns.first
        sql << ((col.instance_of? InterBaseColumn) ? col.name : col.to_s)
      end
      
      sql << ")"
      
      #puts "sql is #{sql}"
      
      sql
    end
    
    def create_index(conn)
      #puts #{to_sql} vs #{self.to_sql}"
      conn.execute_immediate(self.to_sql)
    end
    
    def rename_index(conn, new_name)
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

    def remove_index(conn)
      conn.execute_immediate( "DROP INDEX #{name}" )
    end
  end
  
  class InterBaseConstraint
    attr_accessor :name, :type, :columns, :table, :foreign_cols, :foreign_table_name
    
    PRIMARY_KEY = :PRIMARY_KEY
    FOREIGN_KEY = :FOREIGN_KEY
    
    # columns are strings only, not complete columns. if they are complete columns
    # then we just get their name
    def initialize(type, columns, foreign_cols=nil, foreign_table_name=nil, name=nil)
      @name = name
      @type = type
      @columns = columns
      @foreign_cols=foreign_cols
      @foreign_table_name=foreign_table_name
      
      #puts "constraint created #{to_sql}"
    end
    
    def to_sql
      tab_name = table.nil? ? "NULL" : table.name
      sql = "alter table #{tab_name} add "
      
      if @type == :PRIMARY_KEY
        sql << "primary key ("
        sql << cycle_cols
        sql << ")"
      elsif @type == :FOREIGN_KEY
        sql << "foreign key ("
        sql << cycle_cols
        sql << ") references #{foreign_table_name} ("
        sql << cycle_cols(foreign_cols)
        sql << ")"
      else
        raise NotImplementedError, "Other constraints #{@type.to_s} not implemented yet"
      end
    end
    
    private
      def cycle_cols(columns=@columns)
        sql = ""
        if !columns.nil?
          col_count = 0
          columns.each() do |col|
            sql << ", " unless col_count == 0
            col_count += 1 # can't use columns.first as it may not be passed first by each????
            if col === InterBaseColumn
              sql << col.name
            else
              sql << col.to_s
            end
          end
        end
        
        sql
      end
    
  end
  
  class InterBaseTable 
    attr_accessor :name, :columns, :indices, :constraints
    
    SQL_ALL = :SQL_ALL
    SQL_TABLE = :SQL_TABLE
    SQL_INDICES = :SQL_INDICES
    SQL_PRIMARY_KEYS = :SQL_PRIMARY_KEYS
    SQL_FOREIGN_KEYS = :SQL_FOREIGN_KEYS
    
    def initialize(name, columns=[], indices=[], constraints=[] )
      #puts "table name new table: #{name}"
      @name = name.to_s.upcase
      @columns = columns
      @indices = indices
      @constraints = constraints
      
      if @constraints
        @constraints.each() {|c| c.table = self }
      end
    end
    
    def load(conn)
      @columns = InterBaseMetaFunctions.table_fields(conn,@name,true)
      @indices = InterBaseMetaFunctions.indices(conn,@name)
      @constraints = InterBaseMetaFunctions.table_constraints(conn,@name)
      
      #puts "#{@constraints.size} constraints found"
      
      @constraints.each() {|c| c.table = self }
      
      @loaded = true
    end
    
    def drop_table(conn)
      #puts "DROP TABLE #{name}"
      conn.execute_immediate( "DROP TABLE #{name}" )
    end
    
    def create_table(conn)
      to_sql.each() do |sql|
        #puts "executing: #{sql}"
        conn.execute_immediate( sql )
      end
    end
    
    ## returns an array of sql required to create the table and all dependents
    # when reconstructing the database, create all the tables, then create the primary keys and then
    # create the foreign keys and then the indices
    def to_sql(sql_restriction=:SQL_ALL)
      sql = []
      
      if ( [:SQL_ALL, :SQL_TABLE].include?(sql_restriction) )
        sql << to_sql_create_table
      end
      
      if ( [:SQL_ALL, :SQL_INDICES].include?(sql_restriction) && @indices )
        @indices.each() {|index| sql << index.to_sql }
      end
      
      if ( [:SQL_ALL, :SQL_PRIMARY_KEYS].include?(sql_restriction) && @constraints )
        @constraints.each() do |c| 
          if (c.type == InterBaseConstraint::PRIMARY_KEY) 
            sql << c.to_sql
          end 
        end
      end
      
      if ( [:SQL_ALL, :SQL_FOREIGN_KEYS].include?(sql_restriction) && @constraints )
        @constraints.each() do |c| 
          if (c.type == InterBaseConstraint::FOREIGN_KEY) 
            sql << c.to_sql
          end 
        end
      end
      
      sql
    end
    
    def rename_table(conn, ntable_name)
      new_table_name = ntable_name.to_s.upcase
      
      if @loaded.nil? or !@loaded
        load(conn)
      end
      
      old_table_name = @name
      load(conn)  # load the definition
      @name = new_table_name
      to_sql(:SQL_TABLE).each() {|sql| conn.execute_immediate(sql) }
      # copy all the data across
      conn.execute_immediate( "insert into #{new_table_name} select * from #{old_table_name}")
      to_sql(:SQL_PRIMARY_KEYS).each() {|sql| conn.execute_immediate(sql) }
      to_sql(:SQL_FOREIGN_KEYS).each() {|sql| conn.execute_immediate(sql) }
      @indices.each() do |index| 
        index.remove_index(conn)
        index.table = new_table_name
        index.create_index(conn)
      end
      @name = old_table_name
      drop_table(conn)
    end
    
    private
    def to_sql_create_table
      sql = "create table #{name} ("
      
      if !columns.nil?
        col_count = 0
        columns.each() do |col|
          sql << ", " unless col_count == 0
          col_count += 1
          sql << col.to_sql
        end
      end
      
      sql << ")"
      
      #puts sql
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
        "\'#{value}\'"
      elsif ((column_meta_data.type == InterBaseColumn::BLOB) && (column_meta_data.sub_type != 1 ) )
        raise IBRubyException.new("'#{value}' is not a valid default for this column #{column_meta_data.name}.")
      else
        value
      end
    end
    
    
    def self.table_names(conn)
      tables = []
      
      conn.execute_immediate("select rdb$relation_name from rdb$relations where rdb$relation_name not starting 'RDB$' and rdb$flags=1") do |row|
        tables << row[0].to_s.rstrip
      end
      
      tables
    end
    
    def self.indices(conn, table_name)
      indices = []
      
      # we must make sure the current transaction is committed, otherwise this won't work!
      indicesSQL = <<-END_SQL
      select rdb$index_name, rdb$unique_flag,RDB$INDEX_INACTIVE,RDB$INDEX_TYPE  from rdb$indices
         where rdb$relation_name = '#{table_name.to_s.upcase}' and rdb$index_name not starting 'RDB$'
      END_SQL
      
      #~ puts "SQL"
      #~ puts indicesSQL
      
      conn.execute_immediate(indicesSQL) do |row|
        #puts "index #{ib_to_ar_case(row[0].to_s.rstrip)}"
        indices << InterBaseIndex.new(table_name, row[0].to_s.rstrip, 
               row[1].to_i == 1, [], 
               (row[3] == 1)?InterBaseMetaFunctions::DESCENDING : InterBaseMetaFunctions::ASCENDING, 
               (row[2] == 1)?InterBaseIndex::INDEX_INACTIVE : InterBaseIndex::INDEX_ACTIVE)
      end
      
      #puts "Indices size #{indices.size}"
      
      if !indices.empty? 
        indices.each() do |index|
          sql = "select rdb$field_name from rdb$index_segments where rdb$index_name "\
                 "= '#{index.name.upcase}' order by rdb$index_name, rdb$field_position"
          
          #puts "index SQL: #{sql}"
          
          conn.execute_immediate(sql) do |row|
            index.columns << table_fields(conn, table_name, true, row[0].to_s.rstrip )
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
    def self.table_fields(connection, table, extract_ordered = false, column_name = nil)
      # Check for naughty table names.
      if /\s+/ =~ table.to_s
        raise IBRubyException.new("'#{table.to_s}' is not a valid table name.")
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
        
        #puts "sql: #{sql}"
        
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
              type = InterBaseColumn.new(field_name, table.to_s, sql_type, row[6], !row[7].nil?, nil, nil, nil, row[5] )
            when InterBaseColumn::CHAR, InterBaseColumn::VARCHAR
              type = InterBaseColumn.new(field_name, table.to_s, sql_type, row[6], !row[7].nil?, row[8] )
              # row[8] is the real length, field_length depends on the character set being used
            when InterBaseColumn::DECIMAL, InterBaseColumn::NUMERIC
              type = InterBaseColumn.new(field_name, table.to_s, sql_type, row[6], !row[7].nil?, nil, row[3], row[4] )
            else
              type = InterBaseColumn.new(field_name, table.to_s, sql_type, row[6], !row[7].nil? )
            end
            
            if extract_ordered
              types << type
            else
              types[field_name] = type
            end
            
            #puts "col: #{type.to_sql}"
          end
          
        #end
      end
      if ( types.size > 1 || column_name.nil? )
        types
      elsif (types.size == 1)
        types[0]
      else
        nil
      end
    end # table_fields
    
    def self.table_constraints(conn, table_name)
      sql = "select rdb$constraint_name, rdb$constraint_type, rdb$index_name "\
      "from rdb$relation_constraints "\
        "where rdb$constraint_type in ('FOREIGN KEY', 'PRIMARY KEY' ) "\
        "and rdb$relation_name = '#{table_name.to_s.upcase}'"
        
      constraints = []
      
      conn.execute_immediate(sql) do |constraint|
        constraint_name = constraint[0].strip
        constraint_type = ( constraint[1].strip == 'PRIMARY KEY' ) ? 
          InterBaseConstraint::PRIMARY_KEY : InterBaseConstraint::FOREIGN_KEY;
        representing_index = constraint[2]
        # now we need to get the columns that are being keyed on on this table, that is the same
        # for PK and FK
        columns = []
        conn.execute_immediate( "select rdb$field_name "\
              "from rdb$index_segments where rdb$index_name='#{representing_index}'") do |col|
          columns << col[0].to_s.strip
        end
        # and now for foreign keys, we need to find out what the foreign key index name is
        if constraint_type == InterBaseConstraint::FOREIGN_KEY
          fk_columns = []
          foreign_key_index = nil
          foreign_key_table = nil
          conn.execute_immediate( "select rdb$foreign_key from rdb$indices "\
                "where rdb$index_name='#{representing_index}'") do |fk|
            foreign_key_index = fk[0].strip
          end
          conn.execute_immediate( "select rdb$relation_name from rdb$indices "\
                "where rdb$index_name='#{foreign_key_index}'") do |fk|
            foreign_key_table = fk[0].strip
          end
          conn.execute_immediate( "select rdb$field_name "\
              "from rdb$index_segments where rdb$index_name='#{foreign_key_index}'") do |col|
            fk_columns << col[0].to_s.strip
          end
          
          constraints << InterBaseConstraint.new( constraint_type, columns, fk_columns, foreign_key_table )
        else
          constraints << InterBaseConstraint.new( constraint_type, columns  )
        end #if constraints_type
      end #conn.execute_immediate
      
      constraints
    end #def table_constraints

    def self.db_type_cast( conn, column_type, column_value )
      sql = "SELECT CAST(#{column_value} AS #{column_type}) FROM RDB$DATABASE ROWS 1 TO 1"
      #puts "db_type_cast: #{sql}"
      retVal = nil
      conn.execute_immediate(sql) do |row|
        retVal = row[0]
      end
      retVal
    end
    
    
    # end of InterBaseMetaFunctions class
  end
  
  
  # This class is used to represent SQL table column tables.
  class InterBaseColumn
    # allow these to be overriden
    @@default_precision = 10
    @@default_scale = 2
    @@default_length = 252  #so string indexes work by default
  
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
        when InterBaseColumn::NUMERIC, InterBaseColumn::DECIMAL, InterBaseColumn::INTEGER, 
                InterBaseColumn::DOUBLE, InterBaseColumn::FLOAT
          false
        when InterBaseColumn::CHAR, InterBaseColumn::VARCHAR, InterBaseColumn::BLOB, 
                InterBaseColumn::DATE, InterBaseColumn::TIME, InterBaseColumn::TIMESTAMP
          true
        else
          nil
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
    def initialize(column_name, table_name, type, default_source=nil, not_null=false, 
          length=nil, precision=10, scale=0, sub_type=nil, actual_default=nil )
      @name = column_name
      @table_name = table_name
      @not_null = not_null
      @type      = type
      @length    = length
      @precision = precision
      @scale     = scale
      @sub_type  = sub_type

      
      if !actual_default.nil?
        #puts "actual default #{actual_default}"
        @default = actual_default
      else
        validate_default_source(default_source)
      end
    end
    
    def validate
      # ensure sensible defaults are set      
      @precision = @@default_precision if @precision.nil?
      @scale = @@default_scale if @scale.nil?  
      @length = @@default_length if @length.nil?
    end
    
    def validate_default_source(default_source)
      if !default_source.nil?
        #puts "checking default: #{default_source}"
        match = Regexp.new( '^\s*DEFAULT\s+(.*)\s*', Regexp::IGNORECASE )
        matchData = match.match(default_source.to_s)
        if matchData
          @default = matchData[1]
          
          #puts "result was #{@default} type is #{@type}"
          
          if @default
            if InterBaseColumn.expects_quoting(self)
              len = @default.size - 2
              @default = @default[1..len]
            else
              case @type
               when InterBaseColumn::BOOLEAN
                 @default = "true".casecmp( @default.to_s ) == 0
               when InterBaseColumn::DECIMAL, InterBaseColumn::NUMERIC
                 @default = BigDecimal.new( @default.to_s )
               when InterBaseColumn::DOUBLE, InterBaseColumn::FLOAT
                 @default = @default.to_f
               when InterBaseColumn::INTEGER
                 @default = @default.to_i
               when InterBaseColumn::DATE, InterBaseColumn::TIME, InterBaseColumn::TIMESTAMP
                 if @default.to_s !~ /^current/i
                   @default = InterBaseMetaFunctions.db_type_cast( @default, to_s )
                 end
              end
            end
          end
         end
      else
        #puts "default source passed is null"
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
      validate  # ensure sensible defaults

      if @type == InterBaseColumn::DECIMAL or @type == InterBaseColumn::NUMERIC
            "#{@type.id2name}(#{@precision},#{@scale})"
      elsif @type == InterBaseColumn::BLOB
            "#{@type.id2name} SUB_TYPE #{@sub_type}"
      elsif @type == InterBaseColumn::CHAR or @type == InterBaseColumn::VARCHAR
            "#{@type.id2name}(#{@length})"
      elsif @type == InterBaseColumn::DOUBLE
            "DOUBLE PRECISION"
      else
        @type.id2name
      end
    end
    
    def to_sql
      sql = name + " " + to_s
      if !@default.nil?
        sql << " default "
        equote = expects_quoting
        sql << "'" if equote
        sql << @default.to_s
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
          InterBaseColumn::INT64 # can't actually define a column of this type
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
    def rename_column( connection, new_column_name )
      #puts "alter table #{@table_name} alter column #{@name} to #{new_column_name}"
      connection.execute_immediate( "alter table #{@table_name} alter column #{@name} to #{new_column_name}" )
    end
    
    # this column does not exist in the database, please create it!
    def add_column( connection )
      validate  # ensure sensible defaults
      #puts "alter table #{@table_name} add #{self.to_sql}"
      connection.execute_immediate( "alter table #{@table_name} add #{self.to_sql}" )
    end
    
    def change_column(conn, new_column)
      new_column.validate  # ensure sensible defaults
      
      if new_column.type != self   # should use == defined above
        change_type_sql = "ALTER TABLE #{@table_name} alter #{@name} type #{new_column.to_s}"
        #puts change_type_sql
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
        defaultSource = new_column.default.nil? ? "" : ("default " << InterBaseMetaFunctions.quote(new_column.default.to_s, new_column ) )
        #puts "alter table #{@table_name} add ib$$temp type #{new_column.to_s} #{defaultSource}"
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
