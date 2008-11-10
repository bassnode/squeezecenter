require 'net/telnet'

class RubySqueeze::SqueezeServer
  attr_reader :host, :port
  
  def initialize(api, host, port)
    @api = api
    @connected = false
    @players = nil
    @host = host
    @port = port
  end
  
  def self.open(host = "localhost", port = 9000, api_port = 9090)
    connection = self.raw_connection(host, api_port)
    self.new(RubySqueeze::SqueezeAPI.new(connection), host, port)
  end
  
  def self.raw_connection(host, port)
    Net::Telnet::new("Host" => host, "Port" => port, "Telnetmode" => false, "Prompt" => /\n/)
  end
  
  # If username and password are given, we try to authenticate
  # with the password-protected SqueezeCenter.  Not all systems
  # will require authentication.
  def connect(username = nil, password = nil)
    if username.nil? and password.nil? 
      raise AuthenticationError unless self.version
    else
      @api.authenticate(username, password)
      raise AuthenticationError unless self.version
    end
    @connected = true
  end
  
  def disconnect
    @api.invoke("exit")
    @connected = false
    true
  end
  
  def connected?
    @connected
  end
  
  def version
    @api.invoke("version ?")
  end
  
  def players
     @players || scan_for_players   
  end
  
  # Can pass 'current' to get current track's cover.jpg
  def artwork_path_for(track_id)
    artwork_path track_id, :cover
  end

  # Can pass 'current' to get current track's thumb.jpg  
  def thumbnail_path_for(track_id)
    artwork_path track_id, :thumb
  end
  
  # Get the number of +type+ in the system.
  # Valid +types+ include songs, artists, albums, genres
  def total(type='songs')
    raise "Invalid type passed" unless %w(songs artists albums genres).include?(type)
    @api.invoke("info total #{type} ?")
  end
  
  def list_all(type, search=nil)
    raise "Invalid type passed" unless %w(songs artists albums genres years musicfolder playlists).include?(type)
    search = " search:#{search}" if search
    @api.invoke("#{type} 0 1000#{search}")
  end
  
  # Searches for the passed +query+ and returns a Hash
  # containing the found artists, albums and tracks.
  def search(query, limit = 100)
    res = @api.invoke("search 0 #{limit} term:#{query}", false)
    return nil unless res
    
    hash = {:counts => {}}
    # Get counts
    res.scan(/((\w+_)?count_?%3A(\d+))/).each do |count|
      key = count[1].nil? ? 'count' : count[1].gsub(/_/,'')
      hash[:counts][key.to_sym] = count.last.to_i
    end    
    
    # Group each individual type of each result into a hash
    %w(album track contributor genre).each do |type|
      hash[type.to_sym] = Hash[*res.scan(/(#{type}_id%3A\w+ #{type}%3A[\w%\d]+)/).flatten.collect{|r| r.split(/\s/).collect{|a| a.gsub(/#{type}.*%3A/, '').urldecode} }.flatten]
    end
    
    hash
  end
  
  protected
    def scan_for_players
      @players = []
      player_count = @api.invoke("player count ?").to_i
      player_count.times do |x|
        player_id = @api.invoke("player id #{x-1} ?")
        @players << RubySqueeze::Player.new(@api, player_id)
      end
      @players
    end
    
    def artwork_path(track_id, type)
      "http://#{@host}:#{@port}/music/#{track_id}/#{type.to_s}.jpg"
    end
end

class AuthenticationError < Exception; end