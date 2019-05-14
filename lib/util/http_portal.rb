require 'curb'

module Http
  class Portal

    def send(url, body)
      curlObj = Curl::Easy.new(url)
      curlObj.connect_timeout = 30
      curlObj.timeout = 30
      curlObj.header_in_body = false
      curlObj.ssl_verify_peer = true
      curlObj.post_body = body
      curlObj.perform
      @response = curlObj.body_str
    end

    def response
      return @response if valid_response?(@response)
      raise StandardError.new("Invalid Response From Payment Gateway")
    end

    private

    def valid_response?(response)
      response != {} && response != nil && response != ""
    end

  end

end
