require File.expand_path(File.dirname(__FILE__) + "/ntlm_authentication_helper.rb")

class SimpleHttpClient

  def get uri, header = {}
    please(:get, uri, nil, header)
  end

  def post uri, data, header = {}
    please(:post, uri, data, header)
  end
  
  def put uri, data, header = {}
    please(:put, uri, data, header)
  end
  
  def delete uri, header = {}
    please(:delete, uri, nil, header)
  end

protected
  
  def please action, uri, data, header
    Net::HTTP.start(uri.host, uri.port) do |http|
      args = [uri.request_uri, data, header].compact
      http.method(action).call(*args)
    end
  end
  
end

class CookieAwareHttpClient < SimpleHttpClient
  
  @cookie
  
  def initialize(uri)
    helper = NtlmAuthenticationHelper.new
    @cookie = helper.use_ntlm_to_get_cookie uri
  end
  
protected
  
  def please action, uri, data, header
    header["Cookie"] = @cookie
    super(action, uri, data, header)
  end
  
end
