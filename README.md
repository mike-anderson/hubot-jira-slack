[![Image Alt](https://i.creativecommons.org/l/by-sa/4.0/80x15.png)](http://creativecommons.org/licenses/by-sa/4.0/)

# hubot-jira-slack

Based on [hubot-jira-connector](https://github.com/Duologic/hubot-jira-connector), use [jira-connector](https://www.npmjs.com/package/jira-connector) with Hubot, specifically adapted for Slack.

## Installation

In hubot project repo, run:

`npm install hubot-jira-slack --save`

Then add **hubot-jira-slack** to your `external-scripts.json`:

```json
[
  "hubot-jira-slack"
]
```

## Configuration

To use this, you'll need to setup an application link using OAuth with Jira, see [jira-connector documentation](https://github.com/floralvikings/jira-connector#oauth-authentication) for more information.

Following environment variables are required before running:

```
export HUBOT_JIRA_CONNECTOR_HOST=company.atlassian.net
export HUBOT_JIRA_CONNECTOR_PRIVATE_KEY=/path/to/private-key.pem
export HUBOT_JIRA_CONNECTOR_CONSUMER_KEY=<key configured in jira>
export HUBOT_JIRA_CONNECTOR_TOKEN=<token from jira>
export HUBOT_JIRA_CONNECTOR_TOKEN_SECRET=<token secret from jira>
```

## Sample Interaction

### Issue Summaries

Mention an issue (in capitalized format) in any channel that hubot is listening on to get a short summar of an issue: 
 - Issue Key
 - Issue Name
 - Assignee
 - Status

 Issue type is denoted by the attachement color

| Issue Type    | Color         | Hex Code |
| ------------- | ------------- | -------- |
| Story         | Green         | #2ecc71  |
| Epic          | Purple        | #9b59b6  |
| Bug           | Red           | #e74c3c  |
| Task          | Blue          | #3498db  |
| Sub-Task      | Black         | #34495e  |

 ![Issue Summary](http://andersonapps.ca/readme_embeds/hubot-jira-slack/letstalkabout.png)

### Describe Issue

Get a more complete summary of an issue by asking hubot directly: `hubot describe <ISSUE-KEY>`

- Issue Key
- Issue Name
- Assignee
- Status
- Reporter
- Priority
- Description

![Issue Description](http://andersonapps.ca/readme_embeds/hubot-jira-slack/describe.png)

### Get Issue Comments

Get issue comments for by asking hubot directly: `hubot commends for <ISSUE-KEY>`

![Comments](http://andersonapps.ca/readme_embeds/hubot-jira-slack/comments.png)

### Find Issues

Find issues using a blind text search by asking hubot directly `hubot find issues containing "<TEXT>"` (the quotes are required)

other variants of the question will work
- `hubot find me issues containing "<TEXT>"`
- `hubot show issues containing "<TEXT>"`
- `hubot show me issues containing "<TEXT>"`
- `hubot show issues with "<TEXT>"`
- `hubot find issues with "<TEXT>"`
- `hubot what issues contain "<TEXT>"?`

The JQL query executed is: `text ~ "<TEXT>"`

![Find Issues](http://andersonapps.ca/readme_embeds/hubot-jira-slack/find.png)


# Changes from hubot-jira-connector

hubot-jira-slack adds the following
- Issues are sent as slack attachments, allowing for link formatting
- The attachment color is set based on the issue-type
- Comment lists are also sent as slack attachments to provide better formatting and shorten long comments
- In addition to printing a short summary when an issue is mentioned, you can also call `hubot describe <ISSUE#>` to get a more detailed view (seen below)
- You can call `hubot find issues containing "<TEXT>"` to get a list of (up to 10) issues containing that text
