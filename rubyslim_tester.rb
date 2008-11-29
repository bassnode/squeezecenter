require 'rubygems'
require 'lib/rubysqueeze'
require "pp"

puts Song.count
puts Artist.count
puts Album.connection.inspect