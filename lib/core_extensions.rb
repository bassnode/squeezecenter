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
  
  def classify
    self.sub(/.*\./, '').singularize.camelcase
  end
  
  def pluralize
    self + 's'
  end
    
end