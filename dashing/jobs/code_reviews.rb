require 'octokit'

$client = Octokit::Client.new(:access_token => ENV["GITHUB_CLIENT_TOKEN"])

code_reviewers = {
  "brandizzi" => {"label" => "Adam"},
  "inacionery" => {"label" => "Inácio"},
  "leoadb" => {"label" => "Leonardo"},
  "marcellustavares" => {"label" => "Marcellus"},
  "pedroqueiroz94" => {"label" => "Pedrinho"},
  "rafaprax" => {"label" => "Praxedes"}
}

ddm_code_reviewers = {
  "com-liferay-dynamic-data-mapping" => {"label" => "DDM"}
}

workflow_code_reviewers = {
  "com-liferay-portal-workflow" => {"label" => "WF"}
}

def photo_user_profile(owner)
  user = $client.user owner
  user['avatar_url']
end

code_reviewers.each {|owner, mapping| mapping['avatar_url'] = photo_user_profile(owner)}

def portal_number_of_open_pull_requests(owner)
  begin
    open_pull_requets = $client.pull_requests('%{owner}/liferay-portal' % {owner: owner}, :state => 'open')
    open_pull_requets.count
  rescue
  end
end

def portal_ee_number_of_open_pull_requests(owner)
  begin
    open_pull_requets = $client.pull_requests('%{owner}/liferay-portal-ee' % {owner: owner}, :state => 'open')
    open_pull_requets.count
  rescue
  end
end

def ddm_number_of_open_pull_requests(owner)
  begin
    open_pull_requets = $client.pull_requests('%{owner}/com-liferay-dynamic-data-mapping' % {owner: owner}, :state => 'open')
    open_pull_requets.count
  rescue
  end
end

def workflow_number_of_open_pull_requests(owner)
  begin
    open_pull_requets = $client.pull_requests('%{owner}/com-liferay-portal-workflow' % {owner: owner}, :state => 'open')
    open_pull_requets.count
  rescue
  end
end

SCHEDULER.every '5m', :first_in => 0 do
  code_reviewers.each {|owner, mapping| mapping['value'] = portal_number_of_open_pull_requests(owner).to_i}
  code_reviewers.each {|owner, mapping| mapping['value'] = mapping['value'].to_i + portal_ee_number_of_open_pull_requests(owner).to_i}
  code_reviewers.each {|owner, mapping| mapping['value'] = mapping['value'].to_i + ddm_number_of_open_pull_requests(owner).to_i}
  code_reviewers.each {|owner, mapping| mapping['value'] = mapping['value'].to_i + workflow_number_of_open_pull_requests(owner).to_i}

  workflow_code_reviewers.each {|owner, mapping| mapping['value'] = workflow_number_of_open_pull_requests("liferay").to_i}
  code_reviewers = workflow_code_reviewers.merge(code_reviewers)

  ddm_code_reviewers.each {|owner, mapping| mapping['value'] = ddm_number_of_open_pull_requests("liferay").to_i}
  code_reviewers = ddm_code_reviewers.merge(code_reviewers)

  send_event('code-reviews', { items: code_reviewers.values})
end