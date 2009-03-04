module RubySqueeze
  
  class Item
    attr_reader :id, :name, :attributes
  
    @@api_connection = nil
    
    class << self
      
      attr_accessor :api_name      
      def api_name
        @api_name || self.to_s.downcase
      end
      
      def api_name=(name)
        @api_name = name
      end
      
      def connection
        if !connected?
          puts "Connecting"
          connect
        end
        @@api_connection
      end
    
      def connected?
        !@@api_connection.nil?
      end
    
      def connect(args={})
        @@api_connection = SqueezeServer.new(args)
      end
      
      # Sends a command to the SqueezeServer API.
      def invoke(command, urldecode=true)
        connection.invoke(command, urldecode)
      end
      
      def query_from_opts(opts)
        limit = opts[:limit] ? opts.delete(:limit) : 10000
        offset = opts[:offset] ? opts.delete(:offset) : 0
        by_id = opts.keys.map{|k| k.to_s}.grep(/(.+)_id$/).first
        if by_id.nil?
          raise "Can't run - no *_id opts passed!"
        else
          clause = "#{by_id}:#{opts[by_id.to_sym]}"
          "#{self.api_name.pluralize} #{offset} #{limit} #{clause}"
        end
        
      end
      
      def find(opts)
        query = query_from_opts(opts)
        res = invoke(query, false)
        
        puts "SEARCH RES: #{res}"
        return nil unless res

        ret = []
        # Make a grouped hash from the results 
        hash = res.split(' ').group_by do |a|
          a.split('%3A').first
        end
        
        # Create an object for each result
        hash['id'].size.times do |n|
          attrs = {}
          hash.each do |key, vals|
            attrs[key] = vals[n].nil? ? nil : vals[n].split(/%3A/).last.urldecode
          end
          ret << self.new(attrs.symbolize_keys)
        end

        if opts[:first]
          ret.first
        else
          ret
        end
      end
      
      
      def search(term, opts={})
        connection.search(term, opts.merge(:type => api_name.to_sym))
      end
      
    end #class methods
    
    def initialize(attributes={})
      @id = attributes.delete(:id).to_i if attributes[:id]
      @name = attributes.delete(:name) || attributes.delete(:title)
      
      # Maybe just for Track here?
      @duration = attributes.delete(:duration).to_f
      @album = attributes.delete(:album)
      @artist = attributes.delete(:artist)
      @genre = attributes.delete(:genre)
    end
    
    # So each instance can access the API connection
    def connection
      self.class.connection
    end
  
    # Sends a command to the SqueezeServer API.
    def invoke(command, urldecode=true)
      self.class.invoke(command, urldecode)
    end
    
    
    # Returns the total number of records
    # for the current item type.
    def self.count
      invoke "info total #{api_name.pluralize} ?"
    end
  end
  
end