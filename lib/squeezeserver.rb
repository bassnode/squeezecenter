require 'net/telnet'

module RubySqueeze
  class SqueezeServer
    attr_reader :host, :port, :api, :connection
    
    class << self
      def connection
        @@connection
      end
    end
    
    def connection
      @@connection
    end

    def initialize(opts = {})
      host     = opts[:host]     ? opts[:host]        : "localhost"
      port     = opts[:port]     ? opts.delete(:port) : 9000
      api_port = opts[:api_port] ? opts[:api_port] : 9090
      username = opts[:username] ? opts[:username] : nil
      password = opts[:password] ? opts[:password] : nil
      
      @@connection = raw_connection(host, api_port)

      authenticate(username, password) unless username.nil? and password.nil? 
      
      raise AuthenticationError unless version
      @connected = true
    end
  
    def raw_connection(host, port)
      Net::Telnet::new("Host" => host, "Port" => port, "Telnetmode" => false, "Prompt" => /\n/)
    end
    
    def authenticate(username, password)
      @@connection.cmd("login #{username} #{password}")
    end

    def invoke(command, urldecode=true)
      cleaned_command = command.gsub('?', '').strip
      puts "COMMAND:      #{command}"
      response = @@connection.cmd(command)
      return false if response.nil? || response.strip.eql?(command)
    
      puts "RESPONSE:     #{response}"
      if urldecode
        response.gsub(cleaned_command, '').strip.urldecode.gsub(command,'').strip
      else
        response.gsub(cleaned_command.gsub(':', '%3A'), '').strip.gsub(command,'').strip
      end
    end
  
    def disconnect
      invoke("exit")
      @connected = false
      true
    end
  
    def connected?
      @connected
    end
  
    def version
      invoke("version ?")
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
      invoke("info total #{type} ?")
    end
    
    # Searches for the passed +query+ and returns a Hash
    # containing the found artists, albums and tracks.
    def search(query, item_type=nil, limit = 10000)
      res = invoke("search 0 #{limit} term:#{query}", false)
      return nil unless res
    
      hash = {:counts => {}}
      # Get counts
      res.scan(/((\w+_)?count_?%3A(\d+))/).each do |count|
        key = count[1].nil? ? 'count' : count[1].gsub(/_/,'')
        hash[:counts][key.to_sym] = count.last.to_i
      end    
    
      # Group each individual type of each result into a hash
      %w(album track contributor genre).each do |type|
        key = type == 'contributor' ? :artist : type.to_sym
        hash[key] = Hash[*res.scan(/(#{type}_id%3A\w+ #{type}%3A[\w%\d]+)/).flatten.collect{|r| r.split(/\s/).collect{|a| a.gsub(/#{type}.*%3A/, '').urldecode} }.flatten]
      end

      if item_type
        item_type = item_type.sym
        raise "Invalid item_type passed" unless [:song, :artist, :album, :genre, :year].include?(item_type)
        hash[item_type]
      else
        hash
      end
    end
  
    protected
      def scan_for_players
        @players = []
        player_count = invoke("player count ?").to_i
        player_count.times do |x|
          player_id = invoke("player id #{x-1} ?")
          @players << RubySqueeze::Player.new(@api, player_id)
        end
        @players
      end
    
      def artwork_path(track_id, type)
        "http://#{@host}:#{@port}/music/#{track_id}/#{type}.jpg"
      end
  end

  class AuthenticationError < Exception; end
end