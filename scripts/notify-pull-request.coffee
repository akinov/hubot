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

emo = [
  "🤩"
  "😺"
  "🙌"
  "👶"
  "🐱"
  "🐙"
  "🧟‍♂️"
  "🧟‍♀️"
  "🍣"
  "✨"
]

translation =
  APPROVED: "承認"
  COMMENTED: "コメント"
  CHANGES_REQUESTED: "改善アドバイス"

emo.sample = -> @[Math.floor Math.random() * @length]

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
    promises = prs.map (pr)->
      fetchLastReviewStates pr.number, pr.user.login

    Promise.all promises
  .then (eachReviewStates) ->

    resolve prs.map (pr, index)->
      requestedReviewers = pr.requested_reviewers.map (u) -> u.login
      reviewStates = eachReviewStates[index]

      [
        "#{emo.sample()} @#{pr.user.login} の「#{pr.title.slice(0, 20)}... (#{pr.html_url})」: "
        (for userName        in requestedReviewers then "@#{userName}のレビューを待ってるよ！").join ''
        (for userName, state of reviewStates       then "@#{userName}が#{translation[state]}したよ！").join ''
      ].join('')
  .catch (result) ->
    reject result

# レビュー中レビュワーの最新状態を取得する
fetchLastReviewStates = (number, reviewee)-> new Promise (resolve, reject) ->
  github.pullRequests.getReviews
    owner: process.env.REPO_OWNER
    repo: process.env.REPO_NAME
    number: number
  .then (result) ->
    reviewStates = result.data
      .map (d) ->
        [d.user.login, d.state]
      .reduce((sum, [userName, state]) ->
        # レビュイー自身は飛ばす
        if userName isnt reviewee
          sum[userName] = state
        sum
      , {})
    # {"user1": "APPROVED", "user2": "COMMENTED"...}
    resolve reviewStates

  .catch (e)-> reject e

module.exports = (robot) ->
  robot.respond /prs/i, (res) ->
    res.send 'プルリクチェックします...'
    checkPullRequests().then (messages) ->
      if messages.length isnt 0
        res.send messages.join("\n")
      else
        res.send "#{emo.sample()}オープンなプルリクはありません#{emo.sample()}"
    .catch (e) ->
      res.send "失敗しました"
      console.error e

  new CronJob '0 0 10,13,16,18 * * 1-5', ->
    checkPullRequests().then (messages)->
      robot.messageRoom process.env.DEVELOPER_ROOM_NAME, "プルリクチェックの時間です"
      if messages.length isnt 0
        robot.messageRoom process.env.DEVELOPER_ROOM_NAME, messages.join("\n")
      else
        robot.messageRoom process.env.DEVELOPER_ROOM_NAME, "#{emo.sample()}オープンなプルリクはありません#{emo.sample()}"
  , null, true
