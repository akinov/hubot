# Description:
#   GitHub のメンションお知らせ
#
# Configuration:
#   GITHUB_TOKEN
#   REPO_PATHS "owner_name/repo_name_1,owner_name/repo_name_2,other_owner_name/repo_name_3"
#   DEVELOPER_ROOM_NAME
#
# Dependencies:
#   "github": "^12.1.0"
#   "cron": "^1.3.0"
#   "moment": "^2.20.1"
#
# Commands:
#   hubot mention_check user_id - 昨日から今までのメンションをお知らせ

GitHubApi = require 'github'
moment = require 'moment'
{CronJob} = require 'cron'
moment.locale('ja')

github = new GitHubApi

github.authenticate
  type: 'token'
  token: process.env.GITHUB_TOKEN

# ower_name/repo_name1,ower_name/repo_name2,...
repoPaths = process.env.REPO_PATHS.split(',')
  .map (path)->
    path.split('/')
  .map ([owner, repo]) ->
    {owner, repo}

fetchEvents = ({owner, repo, per_page})-> new Promise (resolve, reject) ->
  github.issues.getEventsForRepo
    owner: owner
    repo: repo
    per_page: per_page or 30
  .then (result) ->
    resolve result.data
  .catch (result) ->
    reject result

fetchAllRepoEvents = ({per_page}) -> new Promise (resolve, reject) ->
  promises = repoPaths.map ({repo, owner})-> fetchEvents({repo, owner, per_page})
  Promise.all(promises)
    .then (results) ->
      resolve results.flatten()
    .catch (results) ->
      resolve results

Array.prototype.flatten = -> @reduce(((sum, item) => sum.concat(item)), [])


module.exports = (robot) ->

  robot.respond /mention_check (.+)/i, (res) ->
    name = res.match[1]
    yesterday = moment().subtract(1, 'day')
    res.send "#{yesterday.format('M月D日(ddd)HH時mm分')}以降の#{name}あてメンションをチェックします...."

    fetchAllRepoEvents(per_page: 100).then (messages) ->
      mentioned = messages
        .filter(({event})-> event is 'mentioned')
        .filter(({created_at})-> yesterday.isBefore created_at)
        .filter(({actor})-> actor.login.toLowerCase() is name.toLowerCase())
        .map (d)->
          "@#{d.actor.login} #{d.issue.html_url}  (#{moment(d.created_at).format('MM月DD日(ddd)HH時mm分')}) "
      res.send 'ないよ' if mentioned.length is 0
      mentioned.forEach (m)-> res.send m
    .catch (e) ->
      res.send "失敗しました"
      console.error e

  brainKey = 'last_fetched_github_mention'

  # 10分おきに起動
  new CronJob '0 0,10,20,30,40,50 * * * *', ->
    rawLastFetched = robot.brain.get(brainKey) ? moment().subtract(1, 'hour').format()
    lastFetched = moment(rawLastFetched)

    # フェッチ時間を保存
    robot.brain.set brainKey, moment().format()

    fetchAllRepoEvents(per_page: 50).then (messages) ->
      mentioned = messages
        .filter(({event})-> event is 'mentioned')
        .filter(({created_at})-> lastFetched.isBefore created_at)
        .map (d)->
          "@#{d.actor.login} チェック！ :eye: #{d.issue.html_url} (#{moment(d.created_at).format('M月D日(ddd)HH時mm分')})"
      mentioned.forEach (m)-> robot.messageRoom process.env.DEVELOPER_ROOM_NAME, m
  , null, true

