# Description
#   Use jira-connector with Hubot (OAuth)
#
# Configuration:
#   HUBOT_JIRA_CONNECTOR_HOST (company.atlassian.net)
#   HUBOT_JIRA_CONNECTOR_PRIVATE_KEY (/path/to/file.pem)
#   HUBOT_JIRA_CONNECTOR_CONSUMER_KEY
#   HUBOT_JIRA_CONNECTOR_TOKEN
#   HUBOT_JIRA_CONNECTOR_TOKEN_SECRET

# Commands:
#   hubot list jira projects - return list of jira projects (ticket types)
#   hubot debug ticket - debug json output of a ticket (for development)
#   hubot comments for ticket <ticket> - get comments for <ticket>
#   ... <ticket> .. - return link, summary, reporter and priority of <ticket>
#
# Author:
#   Duologic <jeroen@simplistic.be>
#

module.exports = (robot) ->
  fs = require 'fs'
  JiraClient = require "jira-connector"

  unique_array = (array) ->
    uniqueArray = array.filter (elem, pos) ->
      array.indexOf(elem) == pos
    uniqueArray

  host = process.env.HUBOT_JIRA_CONNECTOR_HOST

  filename = process.env.HUBOT_JIRA_CONNECTOR_PRIVATE_KEY
  contents = fs.readFileSync filename
  key = contents.toString()

  oauth =
      consumer_key: process.env.HUBOT_JIRA_CONNECTOR_CONSUMER_KEY
      private_key: key
      token: process.env.HUBOT_JIRA_CONNECTOR_TOKEN
      token_secret: process.env.HUBOT_JIRA_CONNECTOR_TOKEN_SECRET

  jira = new JiraClient host: host, oauth: oauth

  projects = []
  jira.project.getAllProjects '', (error, categories) ->
    console.log error if error
    projects = (category.key for category in categories)

  is_possible_ticket = (string) ->
    for project in projects
      if (string.indexOf project) == 0
        return true
    return false

  get_ticket = (key, callback) ->
    opts =
        issueKey: key
    jira.issue.getIssue opts, (error, issue) ->
      if issue != undefined
        callback(issue)

  find_ticket_in_text = (text, res) ->
    words = text.split(' ')
    for word in words
      words = words.concat(word.split('/'))
    for word in unique_array(words)
      if is_possible_ticket(word)
        print_ticket(word, res)

  print_comments = (key, res) ->
    get_ticket key, (issue) ->
      comments = issue.fields.comment.comments
      str = "Comments for #{key}:\n"
      for comment in comments
        author = comment.author.displayName
        body = comment.body
        str += "*#{author}:* #{body}\n--\n"
      res.send str

  print_ticket = (key, res, debug=false) ->
    if debug
      get_ticket key, (issue) ->
        res.send JSON.stringify issue, null, 4
    else
      get_ticket key, (issue) ->
        key = issue.key
        summary = issue.fields.summary
        reporter = issue.fields.reporter.displayName
        priority = issue.fields.priority.name
        res.send "<https://#{host}/browse/#{key}|#{key}>: #{summary}\n
Reporter: *#{reporter}*   Priority: *#{priority}*"

  match = 0

  robot.respond /list jira projects/, (res) ->
    if match == 0
      match += 1
      res.send projects
    return

  robot.respond /debug ticket (.+)/, (res) ->
    if match == 0
      match += 1
      print_ticket res.match[1], res, true
    return

  robot.respond /comments for ticket (.+)/, (res) ->
    if match == 0
      match += 1
      get_ticket res.match[1], (issue) ->
        issuekey = issue.key
        comments = issue.fields.comment.comments
        str = "Comments for #{issuekey}:\n"
        for comment in comments
          author = comment.author.displayName
          body = comment.body
          str += "*#{author}:* #{body}\n--\n"
        res.send str
    return

  robot.hear /.+/, (res) ->
    if match == 0
      match += 1
      p = find_ticket_in_text res.message.text, res
