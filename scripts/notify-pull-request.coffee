# Description:
#   プルリクお知らせ
#
# Configuration:
#   GITHUB_TOKEN
#   REPO_OWNER
#   REPO_NAME
#   DEVELOPER_ROOM_NAME
#
# Dependencies:
#   "github": "^12.1.0"
#   "cron": "^1.3.0"
#
# Commands:
#   hubot prs - プルリクお知らせ

GitHubApi = require 'github'
{CronJob} = require 'cron'

github = new GitHubApi

github.authenticate
  type: 'token'
  token: process.env.GITHUB_TOKEN

checkPullRequest = -> new Promise (resolve, reject) ->
  github.pullRequests.getAll
    owner: process.env.REPO_OWNER
    repo: process.env.REPO_NAME
    state: 'open'
    sort: "updated"
    direction: "desc"
  .then (result) ->
    resolve result.data.map (pr)->
      reviewers = pr.requested_reviewers.map((u) -> "@#{u.login}").join(', ')
      "@#{pr.user.login} の「#{pr.title.slice(0, 20)}... (#{pr.html_url})」が#{reviewers}#{if reviewers then "のレビュー" else "マージ"}を待ってるよ！"
  .catch (result) ->
    reject result


module.exports = (robot) ->
  robot.respond /prs/i, (res) ->
    res.send 'プルリクチェックします...'
    checkPullRequest().then (messages) ->
      if messages.lengsh isnt 0
        res.send messages.join("\n")
      else
        res.send "オープンなプルリクはありません"
    .catch (e) ->
      res.send "失敗しました"
      console.error e

  new CronJob '0 0 10,13,16,19 * * 1-5', ->
    checkPullRequest().then (messages)->
      if messages.length isnt 0
        robot.messageRoom process.env.DEVELOPER_ROOM_NAME, "プルリクチェックの時間です"
        robot.messageRoom process.env.DEVELOPER_ROOM_NAME, messages.join("\n")
  , null, true
