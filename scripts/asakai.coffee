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
#   hubot asakai_members ls - 朝会のメンバーを表示
#   hubot asakai_members add <name> - 朝会のメンバーを追加
#   hubot asakai_members rm <name> - 朝会のメンバーを削除
#   hubot asakai_members gacha - 朝会メンバーガチャ
#   hubot asakai_members gacha3 - 朝会メンバー3連ガチャ
#   hubot asakai_note show - 朝会で覚えていたいことを見る
#   hubot asakai_note change <message> - 朝会で覚えていたいこと覚えさせる
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

gobi = [
  "ですよ！"
  "です。"
  "みたいです。"
  "みたいですよ〜。"
  "だ。"
  "だ！"
  "だよ。"
  "だね。"
  "っぽい。"
  "っぽい！"
  "ですわよ。"
  "ですな。"
  "でごわす。"
  "ですなぁ。"
]


emos = [
  "🤔"
  "😶"
  "😺"
  "😸"
  "😻"
  "😿"
  "😹"
  "😽"
  "😀"
]

BRAIN_KEYS_MEMBERS = 'members'
BRAIN_KEYS_NOTICE = 'asakai_notice'

module.exports = (robot) ->

  robot.respond /asakai_members ls/i, (res) ->
    members = robot.brain.get(BRAIN_KEYS_MEMBERS)
    res.send JSON.stringify members

  robot.respond /asakai_members add (.+)/i, (res) ->
    name = res.match[1]
    members = robot.brain.get(BRAIN_KEYS_MEMBERS) or []
    members.push {name}
    robot.brain.set(BRAIN_KEYS_MEMBERS, members)
    res.send "added #{name}"
    res.send JSON.stringify members

  robot.respond /asakai_members rm (.+)/i, (res) ->
    name = res.match[1]
    members = robot.brain.get(BRAIN_KEYS_MEMBERS) or []
    newMembers = members.filter (member)-> member.name isnt name
    robot.brain.set(BRAIN_KEYS_MEMBERS, newMembers)
    res.send "removed #{name}"
    res.send JSON.stringify newMembers

  robot.respond /asakai_members gacha(\d*)$/i, (res) ->
    members = robot.brain.get(BRAIN_KEYS_MEMBERS) or []
    count = Number(res.match[1] || 1)
    if count in [1, NaN]
      res.send "@#{members.random()?.name}"
    else
      res.send members.random(count).map(({name} = {name: null})-> "@#{name}" ).join(' -> ')

  robot.respond /gacha (.+)$/i, (res) ->
    items = res.match[1].split(/\s+/)
    res.send items.random()

  robot.respond /asakai_note show/i, (res) ->
    note = robot.brain.get(BRAIN_KEYS_NOTICE)
    res.send JSON.stringify note

  robot.respond /asakai_note change (.+)/i, (res) ->
    note = res.match[1]
    robot.brain.set(BRAIN_KEYS_NOTICE, note)
    res.reply "覚えました"
    res.send JSON.stringify note



  #robot.messageRoom = (_, m)-> console.log m
  new CronJob '0 30 12 * * 1-5', ->
  #new CronJob '30 * * * * 1-5', ->
    robot.messageRoom process.env.ASAKAI_ROOM_NAME, """
    *---------- #{moment().format('M月D日(dddd)')} ----------*
    @channel :cat: 日報を作成しましょう :cat:
    ```
    *やったこと*
    - done →  ％

    *やること*
    - doing

    *困ってること*
    - とくになし

    *頭の中*
    - #{emos.random()}

    ```
    """
  , null, true

  new CronJob '0 15 14 * * 1-5', ->
  #new CronJob '0 * * * * 1-5', ->
    members = robot.brain.get(BRAIN_KEYS_MEMBERS) or []
    robot.messageRoom process.env.ASAKAI_ROOM_NAME, "@channel 日次会の時間#{gobi.random()} 今日の司会は @#{members.random()?.name} お願いします！"
    note = robot.brain.get(BRAIN_KEYS_NOTICE) or "忘れた"
    robot.messageRoom process.env.ASAKAI_ROOM_NAME, "忘れちゃいけないこと: #{note}"
  , null, true
