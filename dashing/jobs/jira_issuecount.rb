require 'net/http'
require 'json'
require 'time'
require 'open-uri'
require 'cgi'
require_relative '../conf/dashboard_config'

JIRA_ISSUECOUNT_CONFIG = DashboardConfig.load()

FILTER_MAPPING = {
  'issues-filter' => "project = 'PUBLIC - Liferay Portal Community Edition' AND issuetype in (Bug, 'Regression Bug') AND component in (calendar, subcomponents(LPS, 'Dynamic Data Lists', 'true'), subcomponents(LPS, 'Web Form', 'true'), subcomponents(LPS, 'Dynamic Data Mapping', 'true'), subcomponents(LPS, Forms, 'true'), subcomponents(LPS, Polls, 'true'), subcomponents(LPS, Workflow, 'true'), subcomponents(LPS, 'Business Productivity', 'true')) AND status in (Verified, Reopened, 'In Progress', 'In Review') AND affectedVersion >= '7.0.0 M1' AND (labels not in (6.2.x-only) OR labels is EMPTY) AND ('Fix Priority' in (5, 4, 3, 2, 1) OR assignee in membersOf(liferay-staff) AND assignee != 'support-se@liferay.com')",
  'fp-5-filter' => "project = 'PUBLIC - Liferay Portal Community Edition' AND issuetype in (Bug, 'Regression Bug') AND component in (calendar, subcomponents(LPS, 'Dynamic Data Lists', 'true'), subcomponents(LPS, 'Web Form', 'true'), subcomponents(LPS, 'Dynamic Data Mapping', 'true'), subcomponents(LPS, Forms, 'true'), subcomponents(LPS, Polls, 'true'), subcomponents(LPS, Workflow, 'true'), subcomponents(LPS, 'Business Productivity', 'true')) AND status in (Verified, Reopened, 'In Progress', 'In Review') AND (affectedVersion >= '7.0.0 M1') AND (labels not in (6.2.x-only) OR labels is EMPTY) AND ('Fix Priority' in (5, 4, 3, 2, 1) OR assignee in membersOf(liferay-staff) AND assignee != 'support-se@liferay.com') AND 'Fix Priority' = '5'",
  'fp-4-filter' => "project = 'PUBLIC - Liferay Portal Community Edition' AND issuetype in (Bug, 'Regression Bug') AND component in (calendar, subcomponents(LPS, 'Dynamic Data Lists', 'true'), subcomponents(LPS, 'Web Form', 'true'), subcomponents(LPS, 'Dynamic Data Mapping', 'true'), subcomponents(LPS, Forms, 'true'), subcomponents(LPS, Polls, 'true'), subcomponents(LPS, Workflow, 'true'), subcomponents(LPS, 'Business Productivity', 'true')) AND status in (Verified, Reopened, 'In Progress', 'In Review') AND (affectedVersion >= '7.0.0 M1') AND (labels not in (6.2.x-only) OR labels is EMPTY) AND ('Fix Priority' in (5, 4, 3, 2, 1) OR assignee in membersOf(liferay-staff) AND assignee != 'support-se@liferay.com') AND 'Fix Priority' = '4'",
  'fp-3-filter' => "project = 'PUBLIC - Liferay Portal Community Edition' AND issuetype in (Bug, 'Regression Bug') AND component in (calendar, subcomponents(LPS, 'Dynamic Data Lists', 'true'), subcomponents(LPS, 'Web Form', 'true'), subcomponents(LPS, 'Dynamic Data Mapping', 'true'), subcomponents(LPS, Forms, 'true'), subcomponents(LPS, Polls, 'true'), subcomponents(LPS, Workflow, 'true'), subcomponents(LPS, 'Business Productivity', 'true')) AND status in (Verified, Reopened, 'In Progress', 'In Review') AND (affectedVersion >= '7.0.0 M1') AND (labels not in (6.2.x-only) OR labels is EMPTY) AND ('Fix Priority' in (5, 4, 3, 2, 1) OR assignee in membersOf(liferay-staff) AND assignee != 'support-se@liferay.com') AND 'Fix Priority' = '3'"
}

FILTER_LAST_COUNT = {
  'issues-filter' => nil,
  'fp-5-filter' => nil,
  'fp-4-filter' => nil,
  'fp-3-filter' => nil
}

def number_of_issues(url, username, password, jql)
  jql = CGI.escape(jql)
  uri = URI.parse("#{url}/rest/api/2/search?jql=#{jql}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  request = Net::HTTP::Get.new(uri.request_uri)

  if !username.nil? && !username.empty?
    request.basic_auth(username, password)
  end

  JSON.parse(http.request(request).body)["total"]
end

FILTER_MAPPING.each do |mapping_name, filter|
  SCHEDULER.every '10m', :first_in => 0 do
    total = number_of_issues(JIRA_ISSUECOUNT_CONFIG[:jira_url], ENV["JIRA_USERNAME"], ENV["JIRA_PASSWORD"], filter)
    last = FILTER_LAST_COUNT[mapping_name]

    send_event(mapping_name, {current: total, last: last})

    FILTER_LAST_COUNT[mapping_name] = total
  end
end
