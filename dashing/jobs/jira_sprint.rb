require 'net/http'
require 'date'
require 'json'
require 'time'
require 'open-uri'
require 'cgi'
require_relative '../conf/dashboard_config'

JIRA_SPRINT_CONFIG = DashboardConfig.load()

def forms_get_in_progress(url, username, password)
  uri = URI.parse("#{url}/rest/api/2/search?jql=component%20in%20(Forms%2C%20subcomponents(LPS%2C%20%27Dynamic%20Data%20Lists%27%2C%20%27true%27)%2C%20subcomponents(LPS%2C%20%27Web%20Form%27%2C%20%27true%27)%2C%20subcomponents(LPS%2C%20%27Dynamic%20Data%20Mapping%27%2C%20%27true%27)%2C%20subcomponents(LPS%2C%20Polls%2C%20%27true%27))%20and%20status%20%3D%20%27In%20Progress%27%20%20and%20project%20%3D%20'PUBLIC%20-%20Liferay%20Portal%20Community%20Edition'%20and%20status%20%3D%20'In%20Progress'%20%20and%20project%20%3D%20%22PUBLIC%20-%20Liferay%20Portal%20Community%20Edition%22%20&fields=key,summary,assignee,status")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  request = Net::HTTP::Get.new(uri.request_uri)

  if !username.nil? && !username.empty?
    request.basic_auth(username, password)
  end

  data = JSON.parse(http.request(request).body)

  sprint_statistics = {}

  wip_issues = []

  data["issues"].each {|issue| wip_issues.push({'title' => get_issue_title(issue), 'assignee' => issue["fields"]["assignee"]["displayName"]})}

  sprint_statistics['wip_issues'] = wip_issues

  sprint_statistics
end

def workflow_get_in_progress(url, username, password)
  uri = URI.parse("#{url}/rest/api/2/search?jql=component%20in%20(subcomponents(LPS%2C%20Workflow%2C%20%27true%27)%2C%20subcomponents(LPS%2C%20%27Business%20Productivity%27%2C%20%27true%27)%2C%20subcomponents(LPS%2C%20Calendar%2C%20%27true%27))%20and%20status%20%3D%20'In%20Progress'%20%20and%20project%20%3D%20%22PUBLIC%20-%20Liferay%20Portal%20Community%20Edition%22%20&fields=key,summary,assignee,status")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  request = Net::HTTP::Get.new(uri.request_uri)

  if !username.nil? && !username.empty?
    request.basic_auth(username, password)
  end

  data = JSON.parse(http.request(request).body)

  sprint_statistics = {}

  wip_issues = []

  data["issues"].each {|issue| wip_issues.push({'title' => get_issue_title(issue), 'assignee' => issue["fields"]["assignee"]["displayName"]})}

  sprint_statistics['wip_issues'] = wip_issues

  sprint_statistics
end

def get_issue_title(issue)
  title = issue["key"] + " " + issue["fields"]["summary"][0..40]

  if (issue["fields"]["summary"].length > 40)
    title += "..."
  end

  title
end

SCHEDULER.every '15m', :first_in => 0 do
  forms_get_in_progress = forms_get_in_progress(JIRA_SPRINT_CONFIG[:jira_url], ENV["JIRA_USERNAME"], ENV["JIRA_PASSWORD"])

  send_event('forms-wip-tasks', {tasks: forms_get_in_progress['wip_issues']})

  workflow_get_in_progress = workflow_get_in_progress(JIRA_SPRINT_CONFIG[:jira_url], ENV["JIRA_USERNAME"], ENV["JIRA_PASSWORD"])

  send_event('workflow-wip-tasks', {tasks: workflow_get_in_progress['wip_issues']})
end