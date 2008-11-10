require 'rubygems'
require 'lib/rubysqueeze'
require "pp"
squeezecenter = RubySqueeze::SqueezeServer.open
squeezecenter.connect
player = squeezecenter.players.first
#squeezecenter.list_all('songs', 'levee')
#pp squeezecenter.search('andy')
pp player.current_title
#player.jump_to(140)
# puts squeezecenter.artwork_path_for(218)
squeezecenter.disconnect
