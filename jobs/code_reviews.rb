require 'net/http'
require 'json'
require 'time'
require 'open-uri'
require 'cgi'

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

  code_reviewers.each {|owner, mapping| mapping['value'] = number_of_open_pull_requests(owner)}

  send_event('code-reviews', { items: code_reviewers.values })
end