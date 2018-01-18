# Description:
#   GitHub のメンションお知らせ
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
#   "moment": "^2.20.1"
#
# Commands:
#   hubot mention_check - 昨日から今までのメンションをお知らせ

GitHubApi = require 'github'
moment = require 'moment'
{CronJob} = require 'cron'

github = new GitHubApi

github.authenticate
  type: 'token'
  token: process.env.GITHUB_TOKEN

fetchEvents = -> new Promise (resolve, reject) ->
  github.issues.getEventsForRepo
    owner: process.env.REPO_OWNER
    repo: process.env.REPO_NAME
    per_page: 300
  .then (result) ->
    resolve result
  .catch (result) ->
    reject result

start = (res)->

module.exports = (robot) ->


  robot.respond /mention_check/i, (res) ->
    yeasterday = moment().subtract(1, 'day')
    res.send "#{yeasterday.format('M月D日HH時mm分')}以降のメンションをチェックします...."
    fetchEvents().then (messages) ->
      mentioned = messages.data
        .filter(({event})-> event is 'mentioned')
        .filter(({created_at})-> yeasterday.isBefore created_at)
        .map (d)->
          "@#{d.actor.login} #{d.issue.html_url}  (#{moment(d.created_at).format('YYYY-MM-DD HH:mm')}) "
      res.send 'ないよ' if mentioned.length is 0
      mentioned.forEach (m)-> res.send m
    .catch (e) ->
      res.send "失敗しました"
      console.error e

  lastFetched = moment().subtract(1, 'day')

  new CronJob '0 0,30 10-19 * * 1-5', ->
    fetchEvents().then (messages) ->
      mentioned = messages.data
        .filter(({event})-> event is 'mentioned')
        .filter(({created_at})-> lastFetched.isBefore created_at)
        .map (d)->
          "@#{d.actor.login} check #{d.issue.html_url} (#{moment(d.created_at).format('YYYY-MM-DD HH:mm')}) "
      lastFetched = moment()
      mentioned.forEach (m)-> robot.messageRoom process.env.DEVELOPER_ROOM_NAME, m
  , null, true

