# Description:
#   朝会お知らせ
#
# Configuration:
#   ASAKAI_ROOM_NAME
#
# Dependencies:
#   "cron": "^1.3.0"
#   "moment": "^2.20.1"
#
# Commands:
#   hubot members ls - メンバーを表示
#   hubot members add <slack_account> <github_account> - メンバーを追加
#   hubot members rm <name> - メンバーを削除
#   hubot members gacha - メンバーガチャ
#   hubot members gacha3 - メンバー3連ガチャ
#   hubot gacha <item1 item2 item3> - ガチャ

moment = require 'moment'
{CronJob} = require 'cron'
moment.locale('ja')

# Sorry
Array.prototype.random = (number = 1)->
  dupped = @concat()
  result = []
  [0...number].forEach ->
    index = Math.floor(Math.random() * dupped.length)
    bingo = dupped.splice(index, 1)[0]
    result.push bingo
  if number is 1
    result[0]
  else
    result

BRAIN_KEYS_MEMBERS = 'members'

module.exports = (robot) ->

  robot.respond /members ls/i, (res) ->
    members = robot.brain.get(BRAIN_KEYS_MEMBERS)
    res.send JSON.stringify members

  robot.respond /members add (.+)\s+(.+)/i, (res) ->
    name = res.match[1]
    github = res.match[2]
    members = robot.brain.get(BRAIN_KEYS_MEMBERS) or []
    members.push {name, github}
    robot.brain.set(BRAIN_KEYS_MEMBERS, members)
    res.send "added #{name}"
    res.send JSON.stringify members

  robot.respond /members rm (.+)/i, (res) ->
    name = res.match[1]
    members = robot.brain.get(BRAIN_KEYS_MEMBERS) or []
    newMembers = members.filter (member)-> member.name isnt name
    robot.brain.set(BRAIN_KEYS_MEMBERS, newMembers)
    res.send "removed #{name}"
    res.send JSON.stringify newMembers

  robot.respond /members gacha(\d*)$/i, (res) ->
    members = robot.brain.get(BRAIN_KEYS_MEMBERS) or []
    count = Number(res.match[1] || 1)
    if count in [1, NaN]
      res.send "@#{members.random()?.name}"
    else
      res.send members.random(count).map(({name} = {name: null})-> "@#{name}" ).join(' -> ')

  robot.respond /gacha (.+)$/i, (res) ->
    items = res.match[1].split(/\s+/)
    res.send items.random()
