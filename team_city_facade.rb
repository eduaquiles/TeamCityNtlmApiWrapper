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
  end
  
  def get_all_pinned_builds build_type_id
    response = get "/builds/?locator=buildType:(id:#{build_type_id}),pinned:true"
    return [] if response.is_a?(Net::HTTPNotFound)
    builds = JSON.parse(response.body)
    return [] if builds["count"] == 0
    builds["build"].map{ |b| b["number"] }
  end
  
  def pin_build(build_type_id, number, reason)
    response = put("/builds/buildType:#{build_type_id},number:#{number}/pin/",reason, {"Content-type" => "text/plain"})
    return true if response.is_a?(Net::HTTPNoContent)
    return false
  end
  
  def unpin_build(build_type_id, number)
    response = delete("/builds/buildType:#{build_type_id},number:#{number}/pin/", {"Content-type" => "text/plain"})
    return true if response.is_a?(Net::HTTPNoContent)
    return false
  end
  
  def get_tagged_builds(build_type_id, tag, since_build)
    response = get "/builds?locator=sinceBuild:(buildType:#{build_type_id},number:#{since_build}),buildType:(id:#{build_type_id}),tags:#{tag}"
    return [] if response.is_a?(Net::HTTPNotFound)
    response_as_json = JSON.parse(response.body)
    return [] if response_as_json["count"] == 0
    response_as_json["build"].map{|b| b["number"]}
  end
  
  def get_tags(build_type_id, build_number)
    response = get "/builds/buildType:(id:#{build_type_id}),number:#{build_number}/tags/"
    return [] if response.is_a?(Net::HTTPNotFound)
    return [] if response.body == "null"
    tags = JSON.parse(response.body)
    [tags["tag"]].flatten
  end
  
  def tag_build(build_type_id, number, tag_name)
    body = {:tag => tag_name}.to_json
    #put replaces all the tags of the build
    #post just adds
    response = post("/builds/buildType:#{build_type_id},number:#{number}/tags/", body)
    return true if response.is_a?(Net::HTTPNoContent)
    return false
  end
  
  def untag_build(build_type_id, number, tag_name_to_remove)
    tags = get_tags(build_type_id, number)
    tags -= [tag_name_to_remove]
    body = {:tag => tags}.to_json
    response = put("/builds/buildType:#{build_type_id},number:#{number}/tags/", body)
    return true if response.is_a?(Net::HTTPNoContent)
    return false
  end
  
  BuildTypes = Struct.new(:id,:name,:project)
  def get_build_types
    response = get "/buildTypes"
    return [] if response.is_a?(Net::HTTPNotFound)
    
    build_types = JSON.parse(response.body)["buildType"]
    build_types.map{|bt| BuildTypes.new(bt["id"],bt["name"],bt["projectName"])}
  end
  
private
  
  def get(url_part, header = {"Content-type" => "application/json", "Accept" => "application/json" })
    uri = URI.parse(@base_url + url_part)
    @httpclient.get uri, header
  end
  
  def put(url_part, body, header = {"Content-type" => "application/json", "Accept" => "application/json" })
    response = @httpclient.put URI.parse(@base_url + url_part), body, header
  end
  
  def post(url_part, body, header = {"Content-type" => "application/json", "Accept" => "application/json" })
    response = @httpclient.post URI.parse(@base_url + url_part), body, header
  end
  
  def delete(url_part, header = {"Content-type" => "application/json", "Accept" => "application/json" })
    response = @httpclient.delete URI.parse(@base_url + url_part), header
  end 
  
end
