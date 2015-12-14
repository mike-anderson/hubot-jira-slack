[![Image Alt](https://i.creativecommons.org/l/by-sa/4.0/80x15.png)](http://creativecommons.org/licenses/by-sa/4.0/)

# hubot-jira-connector

Use [jira-connector](https://www.npmjs.com/package/jira-connector) with Hubot

See [`src/hubot-jira-connector.coffee`](src/hubot-jira-connector.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-jira-connector --save`

Then add **hubot-jira-connector** to your `external-scripts.json`:

```json
[
  "hubot-jira-connector"
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

```
user1>> hubot list jira projects
hubot>> PROJ, APP

user1>> let's talk about APP-217
hubot>> <https://company.atlassian.net/browse/APP-217|APP-217>: Application is broken
Reporter: *Duologic*    Priority: *Urgent*

user1>> hubot comments for ticket PROJ-13
*user1*: We need to fix this.
--
*user2*: I already fix this in pull request #42
--

user1>> hubot debug ticket PROJ-14
hubot>> { <json output of ticket> }
```
