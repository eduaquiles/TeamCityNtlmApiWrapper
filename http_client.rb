require File.expand_path(File.dirname(__FILE__) + "/ntlm_authentication_helper.rb")

class CookieAwareHttpClient
  
  @cookie
  
  def initialize(uri)
    helper = NtlmAuthenticationHelper.new
    @cookie = helper.use_ntlm_to_get_cookie uri
  end
  
  def get uri, header = {}
    Net::HTTP.start(uri.host, uri.port) do |http|
      header["Cookie"] = @cookie
      http.get(uri.request_uri, header)
    end
  end
  
  def post uri, data, header = {}
    Net::HTTP.start(uri.host, uri.port) do |http|
      header["Cookie"] = @cookie
      http.post(uri.request_uri, data, header)
    end
  end
  
end

class SimpleHttpClient
  
  def get uri, header = {}
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.get(uri.request_uri, header)
    end
  end
  
  def post uri, data, header = {}
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.post(uri.request_uri, data, header)
    end
  end
end