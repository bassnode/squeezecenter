module RubySqueeze
  
  class Item
    attr_reader :id, :name, :attributes
  
    @@api_connection = nil
    
    class << self
      
      attr_accessor :api_name      
      def api_name
        @api_name || self.to_s.downcase
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
          
        else
          clause = "#{by_id}:#{opts[by_id.to_sym]}"
        end
        "#{self.api_name.pluralize} #{offset} #{limit} #{clause}"
      end
      
      def find(opts)
        query = query_from_opts(opts)
        res = invoke(query, false)
        return nil unless res

        ret = []
        res.scan(/(id%3A\w+ #{self.api_name}%3A[\w%\d]+)/).each do |line|
          i = line.first.split(/\s/)
          #@FIXME This breaks on items with spaces in their names!!
          attrs = Hash[*i.map{ |p| p.split('%3A')}.flatten].symbolize_keys
          attrs[:name] = attrs[self.api_name.to_sym]
          attrs.delete(self.api_name.to_sym)
          attrs.delete(:count) # uneeded
          ret << self.new(attrs)
        end
        if opts[:first]
          ret.first
        else
          ret
        end
      end
      
    end #class methods
    
    def initialize(attributes={})
      @id = attributes.delete(:id).to_i if attributes[:id]
      @name = attributes.delete(:name)
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
      invoke "info total #{api_name} ?"
    end
  end
  
end