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

checkPullRequests = -> new Promise (resolve, reject) ->
  prs = null

  github.pullRequests.getAll
    owner: process.env.REPO_OWNER
    repo: process.env.REPO_NAME
    state: 'open'
    sort: "updated"
    direction: "desc"
  .then (result) ->
    prs = result.data
    promises = prs.map (pr)-> checkPullRequestReviews pr.number

    Promise.all promises
  .then (reviews) ->

    resolve prs.map (pr, index)->
      requestedReviewers = pr.requested_reviewers.map((u) -> u.login)
      reviewingUsers = for userName, status of reviews[index] when (status isnt 'APPROVED' and userName isnt pr.user.login) then userName
      reviewers = requestedReviewers.concat(reviewingUsers).map (userName)-> "@#{userName}"

      "@#{pr.user.login} の「#{pr.title.slice(0, 20)}... (#{pr.html_url})」が#{reviewers}#{if reviewers.join(',') then "のレビュー" else "マージ"}を待ってるよ！"
  .catch (result) ->
    reject result

checkPullRequestReviews = (number)-> new Promise (resolve, reject) ->
  github.pullRequests.getReviews
    owner: process.env.REPO_OWNER
    repo: process.env.REPO_NAME
    number: number
  .then (result) ->
    resolve result.data
      .map((d) -> [d.user.login, d.state])
      .reduce(((sum, item) -> sum[item[0]] = item[1]; sum), {})
  .catch (e)-> reject e

module.exports = (robot) ->
  robot.respond /prs/i, (res) ->
    res.send 'プルリクチェックします...'
    checkPullRequests().then (messages) ->
      if messages.lengsh isnt 0
        res.send messages.join("\n")
      else
        res.send "オープンなプルリクはありません"
    .catch (e) ->
      res.send "失敗しました"
      console.error e

  new CronJob '0 0 10,13,16,19 * * 1-5', ->
    checkPullRequests().then (messages)->
      if messages.length isnt 0
        robot.messageRoom process.env.DEVELOPER_ROOM_NAME, "プルリクチェックの時間です"
        robot.messageRoom process.env.DEVELOPER_ROOM_NAME, messages.join("\n")
  , null, true
