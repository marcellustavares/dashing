require 'octokit'

$client = Octokit::Client.new(:access_token => ENV["GITHUB_CLIENT_TOKEN"])

code_reviewers = {
  "brandizzi" => {label: "Adam"},
  "diogo-lins" => {label: "Diogo"},
  "inacionery" => {label: "Inácio"},
  "thiago-rocha" => {label: "Java"},
  "leoadb" => {label: "Leonardo"},
  "marcellustavares" => {label: "Marcellus"},
  "pedroqueiroz94" => {label: "Pedrinho"},
  "rafaprax" => {label: "Praxedes"}
}

def photo_user_profile(owner)
  user = $client.user owner
  user['avatar_url']
end

code_reviewers.each {|owner, mapping| mapping['avatar_url'] = photo_user_profile(owner)}

def number_of_open_pull_requests(owner)
  open_pull_requets = $client.pull_requests('%{owner}/liferay-portal' % {owner: owner}, :state => 'open')
  open_pull_requets.count
end

SCHEDULER.every '5m' do
  code_reviewers.each {|owner, mapping| mapping['value'] = number_of_open_pull_requests(owner)}

  send_event('code-reviews', { items: code_reviewers.values })
end