require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + "/http_client.rb")
require 'json'

class TeamCityFacade
  @httpclient
  API_URL = "/httpAuth/app/rest"
  GUEST_API_URL = "/guestAuth/app/rest"
  VERSIONS = {6 => GUEST_API_URL, 7 => API_URL}
  
  def initialize(base_url, version)
    raise "Wrong version" unless VERSIONS.keys.map{|k| k}.include? version
    @base_url = base_url + VERSIONS[version]
    if version == 7
      uri = URI.parse("#{base_url}/ntlmLogin.html")
      @httpclient = CookieAwareHttpClient.new uri
    else
      @httpclient = SimpleHttpClient.new
    end
  end
  
  def get_all_projects
    response = get "/projects"
    JSON.parse(response.body)
    response
  end
  
  def get_latest_tagged_build(build_type_id, tag)
    response = get "/builds/buildType:(id:#{build_type_id}),tags:#{tag}"
    return nil if response.is_a?(Net::HTTPNotFound)
    response_as_json = JSON.parse(response.body)
    last_tagged_build_number = response_as_json['number']
    last_tagged_build_number
  end
  
private
  
  def get url_part
    default_header = {
      "Content-type" => "application/json",
      "Accept" => "application/json"
    }
    uri = URI.parse(@base_url + url_part)
    response = @httpclient.get uri, default_header
    puts uri.inspect + " " + response.inspect
    response
  end
  
  def post url_part, body
    default_header = {
      "Content-type" => "application/json",
      "Accept" => "application/json"
    }
    response = @httpclient.post URI.parse(@base_url + url_part), body, default_header
    JSON.parse(response.body)
  end
  
end
