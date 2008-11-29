module RubySqueeze
  
  class Item
    attr_reader :id, :attributes
  
    @@api_connection = nil
    
    
    class << self
      attr_accessor :api_name
      def api_name
        self.to_s.downcase + "s"
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
        "CONNECTING NOW"
        @@api_connection = SqueezeServer.new(args)
      end
      
      # def api_name(name)
      #   @@api_name = name
      # end
      
      def invoke(command)
        connection.invoke(command)
      end
    end
    
    def initialize(id)
      @id = id
    end
    
    # So each instance can access the API connection
    def connection
      self.class.connection
    end
  
    def invoke(command)
      self.class.invoke(command)
    end
  
    
    # Doesn't work yet
    def self.count
      invoke "info total #{api_name} ?"
    end
  
    # if we go module route
    # def self.included(base)
    #   base.extend(ClassMethods)
    # end
  end
  
end