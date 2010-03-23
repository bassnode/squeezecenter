require 'lib/rubysqueeze'
require "pp"
player = Artist.connection.players.first
pl = player.current_playlist
t = pl.randomize

puts Track.count
puts Artist.count
puts Album.connection.inspect

def reload(filename)
  $".delete(filename + ".rb")
  require(filename)
end
