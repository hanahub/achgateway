require 'addressable/uri'

module DataConverter

  def self.hash_to_query_string(hash_data)
    uri = Addressable::URI.new
    begin
      uri.query_values = hash_data
    rescue
      raise TypeError.new("Can not convert to query string")
    end
    uri.query
  end

  def self.query_string_to_hash(query_string)
    CGI.parse(query_string).transform_values(&:first)
  end

end
