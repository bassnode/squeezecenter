require 'net/telnet'

module RubySqueeze
  
  class SqueezeServer
    
    class << self
      def connection
        @@connection
      end
    end
    
    def connection
      @@connection
    end

    def initialize(opts = {})
      @host     = opts[:host]     ? opts[:host]        : "localhost"
      @port     = opts[:port]     ? opts.delete(:port) : 9000
      api_port = opts[:api_port] ? opts[:api_port]    : 9090
      username = opts[:username] ? opts[:username]    : nil
      password = opts[:password] ? opts[:password]    : nil
      
      @@connection = raw_connection(@host, api_port)

      authenticate(username, password) unless username.nil? and password.nil? 
      
      raise AuthenticationError unless version
      @connected = true
    end
  
    # Send the +command+ to the API +connection+
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
      type = 'songs' if type == 'tracks'
      raise "Invalid type passed" unless %w(tracks artists albums genres).include?(type)
      invoke("info total #{type} ?")
    end
    
    # TODO: Make this more robust when results contain spaces!
    # Searches for the passed +query+ and returns a Hash
    # containing the found artists, albums and tracks.
    def total_search(query, opts={})
      item_type = opts.delete(:type)
      limit = opts[:limit] ? opts.delete(:limit) : 10000
      res = invoke("search 0 #{limit} term:#{query}", false)
      return nil unless res
    
      hash = {:counts => {}}
      # Get counts
      res.scan(/((\w+_)?count_?%3A(\d+))/).each do |count|
        key = count[1].nil? ? 'count' : count[1].gsub(/_/,'')
        hash[:counts][key.to_sym] = count.last.to_i
      end    
      
      raise "Invalid item_type passed: #{item_type}" if !item_type.nil? and ![:track, :artist, :album, :genre, :year].include?(item_type)
      
      # Group each individual type of each result into a hash
      %w(album track contributor genre).each do |type|
        next unless item_type.nil? or item_type != type
        key = type == 'contributor' ? :artist : type.to_sym
        hash[key] = Hash[*res.scan(/(#{type}_id%3A\w+ #{type}%3A[\w%\d]+)/).flatten.collect{ |r| 
          arr = r.split(/\s/).collect{|a| 
            a.gsub(/#{type}.*%3A/, '').urldecode
          } 
          Object.const_get(item_type.to_s.classify).new(:id => arr.first, :name => arr[1])
        }.flatten]
        
      end
      hash
    end
    
    def search(query, opts={})
      type = opts.delete(:type)
      klass = Object.const_get(type.to_s.classify)
      
      limit = opts[:limit] ? opts.delete(:limit) : 10000
      res = invoke("search 0 #{limit} term:#{query}", false)
      return nil unless res
    
      out = res.scan(/(#{klass.api_name}_id%3A\w+ #{klass.api_name}%3A[\w%\d]+)/).flatten.collect{ |r| 
        arr = r.split(/\s/).collect{|a| 
          a.gsub(/#{type}.*%3A/, '').urldecode
        } 
        # Create an object for each result
        klass.new(:id => arr.first, :name => arr[1])
      }.flatten
      
      limit==1 ? out.first : out
    end
    
    protected
    def scan_for_players
      @players = []
      player_count = invoke("player count ?").to_i
      player_count.times do |x|
        player_id = invoke("player id #{x-1} ?")
        @players << RubySqueeze::Player.new(self, player_id)
      end
      @players
    end
  
    def artwork_path(track_id, type)
      "http://#{@host}:#{@port}/music/#{track_id}/#{type}.jpg"
    end
    
    private
    def raw_connection(host, port)
      Net::Telnet::new("Host" => host, "Port" => port, "Telnetmode" => false, "Prompt" => /\n/)
    end
    
    def authenticate(username, password)
      @@connection.cmd("login #{username} #{password}")
    end
    
  end

  class AuthenticationError < Exception; end
end