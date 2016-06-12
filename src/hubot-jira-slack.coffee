# Description
#   Use jira-connector with Hubot, with improvements for slack.
#
# Configuration:
#   HUBOT_JIRA_CONNECTOR_HOST (company.atlassian.net)
#   HUBOT_JIRA_CONNECTOR_PRIVATE_KEY (/path/to/file.pem)
#   HUBOT_JIRA_CONNECTOR_CONSUMER_KEY
#   HUBOT_JIRA_CONNECTOR_TOKEN
#   HUBOT_JIRA_CONNECTOR_TOKEN_SECRET

# Commands:
#   hubot comments for <issue> - get comments for <issue>
#   hubot describe <issue> - return link, summary, assignee, status, reporter, priortiy and description of <issue>
#   hubot debug <issue> - debug json output of an issue (for development)
#   hubot find/show [me] issues with/containing "<search term>" - return list of issues containing the text "search term"
#   hubot what issues contain "<search term>"? - return list of issues containing the text "search term"
#   ... <issue> .. - return link, summary, assignee and status of <issue>
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


  format_ticket = (issue, includeFields) -> 
    fields = 
      issueKey:
        title: "Key"
        value: issue.key
        short: true
      summary:
        title: "Summary"
        value: issue.fields.summary
        short: true
      priority:
        title: "Priority"
        value: issue.fields.priority?.name
        short: true
      status:
        title: "Status"
        value: issue.fields.status?.name
        short: true
      reporter:
        title: "Reporter"
        value: issue.fields.reporter?.displayName 
        short: true
      assignee:
        title: "Assignee"
        value: issue.fields.assignee?.displayName
        short: true
      issueType:
        title: "Type"
        value: issue.fields.issuetype?.name
        short: true
      description:
        title: "Description"
        value: issue.fields.description

    issueKey = fields.issueKey.value
    summary = fields.summary.value
    issueType = fields.issueType.value

    text = "*<https://#{host}/browse/#{issueKey}|#{issueKey}: #{summary}>*"
    plaintext = "#{issueKey}: #{summary}"
    displayFields = includeFields.map (key) -> fields[key] 
    issueColour = switch issueType
      when "Story" then "#2ecc71"
      when "Bug" then "#e74c3c"
      when "Task" then "#3498db"
      when "Sub-task" then "#34495e"
      when "Epic" then "#9b59b6"
      else "#bdc3c7"

    formattedAttchment = 
      text: text
      color: issueColour
      mrkdwn_in: ['text']
      fields: displayFields
      fallback: plaintext 

    if displayFields.length == 0
      delete formattedAttchment.fields

    return formattedAttchment


  print_ticket = (key, res, includeFields=['assignee','status'], debug=false) ->
    get_ticket key, (issue) ->
      if debug
        res.send JSON.stringify issue, null, 2
      else
        robot.emit 'slack.attachment',
          channel: res.envelope.room
          attachments: format_ticket issue, includeFields
            

  print_comments = (key, res) ->
    get_ticket key, (issue) ->
      issuekey = issue.key
      comments = issue.fields.comment.comments

      commentAttachments = comments.map (comment) ->
        author = comment.author.displayName
        body = comment.body
        return {
          text: "*#{author}:* #{body}"
          mrkdwn_in: ['text']
        }

      if comments.length > 0 
        commentAttachments[0].pretext = "Comments for #{issuekey}:"
      else
        commentAttachments = [{
          pretext: "There are no comments for #{issuekey}"
        }]

      robot.emit 'slack.attachment', {
        channel: res.envelope.room,
        attachments: commentAttachments
      }


  print_ticket_search = (search, res) ->
    opts = 
      jql:"text ~ \"#{search}\"" 
      maxResults: 10
    jira.search.search opts, (err, response) ->
      issues = (format_ticket issue, [] for issue in response.issues)
      if issues.length > 0
        robot.emit 'slack.attachment', {
          channel: res.envelope.room,
          attachments: issues
        }
      else
        res.reply "I can't find anything"  


  robot.respond /debug issue ([A-Z]+-[0-9]+)/, (res) ->
    print_ticket res.match[1], res, null, true

  robot.respond /comments for ([A-Z]+-[0-9]+)/, (res) ->
    print_comments res.match[1], res

  robot.respond /describe ([A-Z]+-[0-9]+)/, (res) ->
    print_ticket res.match[1], res, ['assignee','status','reporter','priority','description']

  robot.respond /((what|find( me)*|show( me)*) issues (with|contain(ing)*) ")(.+)("(\?*))/, (res) ->
    group = res.match[7]
    if group and group.length > 0
      print_ticket_search group, res
    else 
      res.reply "I don't know what you want me to find, sorry"

  robot.hear /.*/, (res) ->
    # only respond if not directed at hubot
    robot_name = robot.alias or robot.name
    if (res.message.text.indexOf robot_name) != 0
      p = find_ticket_in_text res.message.text, res
