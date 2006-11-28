#!/usr/bin/env ruby

require 'ibruby'

include IBRuby

db = Database.new('localhost::c:/dbs/depot.ib')
c  = db.connect('sysdba', 'masterkey' )
t  = c.start_transaction
ARGV.each do |table|
   count = 0
#   s = Statement.new(c, t, "SELECT * FROM #{table}", 3)
   r = ResultSet.new(c,t,"SELECT * FROM #{table}", 3, [])
   r.each do |row|
      row.each {|column,value| puts "#{column}='#{value},'"}
      #puts row.join(", ")
   end
end
