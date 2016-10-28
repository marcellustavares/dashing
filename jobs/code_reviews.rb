require 'net/http'
require 'json'
require 'time'
require 'open-uri'
require 'cgi'

code_reviewers = {
  "brandizzi" => {label: "Adam"},
  "brunobasto" => {label: "Timão"},
  "diogo-lins" => {label: "Diogo"},
  "inacionery" => {label: "Inácio"},
  "thiago-rocha" => {label: "Java"},
  "leoadb" => {label: "Leonardo"},
  "marcellustavares" => {label: "Marcellus"},
  "rafaprax" => {label: "Praxedes"}
}

def photo_user_profile(owner)
  uri = URI.parse("https://api.github.com/users/#{owner}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'  
  request = Net::HTTP::Get.new(uri.request_uri)
  user = JSON.parse(http.request(request).body)  
  avatar_url = user['avatar_url']
end

code_reviewers.each {|owner, mapping| mapping['avatar_url'] = photo_user_profile(owner)}

def number_of_open_pull_requests(owner)
  uri = URI.parse("https://api.github.com/repos/#{owner}/liferay-portal/pulls")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  puts uri.request_uri
  request = Net::HTTP::Get.new(uri.request_uri)
  pulls = JSON.parse(http.request(request).body)
  pulls.count
end

SCHEDULER.every '10m' do
  code_reviewers.each {|owner, mapping| mapping['value'] = number_of_open_pull_requests(owner)}

  puts code_reviewers

  send_event('code-reviews', { items: code_reviewers.values })
end