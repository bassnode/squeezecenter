class RubySqueeze::SqueezeAPI
  def initialize(connection)
    @connection = connection 
  end
  
  def authenticate(username, password)
    @connection.cmd("login #{username} #{password}")
  end
  
  def invoke(command, urldecode=true)
    cleaned_command = command.gsub('?', '').strip
    puts "COMMAND:      #{command}"
    response = @connection.cmd(command)
    return false if response.nil? || response.strip.eql?(command)
    
    puts "RESPONSE:     #{response}"
    if urldecode
      response.gsub(cleaned_command, '').strip.urldecode.gsub(command,'').strip
    else
      response.gsub(cleaned_command.gsub(':', '%3A'), '').strip.gsub(command,'').strip
    end
  end
  
end
