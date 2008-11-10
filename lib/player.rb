require 'uri'

class RubySqueeze::Player
  attr_accessor :id
  
  def initialize(api, player_id)
    @api = api
    @id = player_id
  end
  
  # def id
  #   URI.unescape(@id)
  # end
  
  def name
    player_query("name")
  end
  
  def ip_address
    URI.unescape(player_query("ip")).split(":").first
  end
  
  def port
    URI.unescape(player_query("ip")).split(":")[1].to_i
  end
  
  def model
    player_query("model")
  end
  
  def display_type
    player_query("displaytype")
  end
  
  def sleep(sleep_time_in_seconds)
    player_command("sleep #{sleep_time_in_seconds}") == false
  end
  
  def time_until_sleep
    player_command("sleep ?").to_f
  end
  
  def turn_on
    player_command("power 1") == false
  end
  
  def turn_off
    player_command("power 0") == false
  end
  
  def on?
    player_command("power ?") == "1"
  end
  
  def off?
    player_command("power ?") == "0"
  end
  
  def display_message(line_1, line_2, duration)
    player_command("display #{URI.escape(line_1)} #{URI.escape(line_2)} #{duration}") == false
  end
  
  def signal_strength
    player_command("signalstrength ?").to_i
  end
  
  def current_display_text
    URI.unescape(player_command("display ? ?"))
  end
  
  def current_title
    @api.invoke("#{@id} current_title ?")
  end
  
  def current_playlist
    RubySqueeze::Playlist.new(@api, self)
  end
  
  # Skip to +seconds+ in the currently playing track
  # Prepend with "-" to use endpoint as start.
  def jump_to(seconds)
    player_command("time #{seconds}")
  end
  
  protected
    def player_query(query)
      @api.invoke("player #{query} #{@id} ?")
    end
    
    def player_command(command)
      @api.invoke("#{@id} #{command}")
    end
end