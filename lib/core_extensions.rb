class String
  def urldecode
    CGI::unescape(self)
  end
  
  def urlencode
    CGI::escape(self)
  end
  
  # Some bastardized ActiveSupport:
  def singularize
    self.gsub(/s$/, '')
  end
  
  def camelize(first_letter_in_uppercase = true)
    if first_letter_in_uppercase
      self.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
    else
      self.first + camelize(self)[1..-1]
    end
  end
  
  def classify
    self.sub(/.*\./, '').singularize.camelize
  end
  
  def pluralize
    self + 's'
  end
    
end

class Hash
  def symbolize_keys
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end

  def symbolize_keys!
    self.replace(self.symbolize_keys)
  end
end

