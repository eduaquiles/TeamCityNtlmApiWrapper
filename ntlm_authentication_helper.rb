require 'rubygems'
require 'win32/sspi'
require 'net/http'

class NtlmAuthenticationHelper 
  include Win32
  def get(uri)
    Net::HTTP.start(uri.host, uri.port) do |http|
      nego_auth = Win32::SSPI::NegotiateAuth.new
      
      resp = http.get(uri.request_uri)
      challenge_type = get_authentication_challenge_type(resp)
      
      resp = http.get(uri.request_uri, build_authorization_credentials_hash(challenge_type, nego_auth.get_initial_token(challenge_type)))
      resp = http.get(uri.request_uri, build_authorization_credentials_hash(challenge_type, nego_auth.complete_authentication(get_authentication_challenge_token(resp))))      
    end        
  end
  
  def use_ntlm_to_get_cookie(uri)
    Net::HTTP.start(uri.host, uri.port) do |http|
      nego_auth = Win32::SSPI::NegotiateAuth.new
      
      resp = http.get(uri.request_uri)
      challenge_type = get_authentication_challenge_type(resp)
      
      resp = http.get(uri.request_uri, build_authorization_credentials_hash(challenge_type, nego_auth.get_initial_token(challenge_type)))
      cookie = resp.response['set-cookie'].split('; ')[0]
      resp = http.get(uri.request_uri, build_authorization_credentials_hash(challenge_type, nego_auth.complete_authentication(get_authentication_challenge_token(resp)), {"Cookie" => cookie}))
      cookie = resp.response['set-cookie'].split('; ')[0]
      cookie
    end        
  end
  
private

  def build_authorization_credentials_hash(challenge_type, token, additional_headers={})
    { "Authorization" => challenge_type + " " + token }.merge(additional_headers)
  end

  def get_authentication_challenge_type(response)
    get_authentication_challenge(response).split(",").first.strip
  end

  def get_authentication_challenge_token(response)
    get_authentication_challenge(response).split(" ").last.strip
  end

  def get_authentication_challenge(response)
    response["WWW-Authenticate"] || response["www-authenticate"]
  end
end
