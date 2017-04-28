# 時刻を受け取ってYYYY-mm-dd形式で返す
toYmDate = (date) ->
  Y = date.getFullYear()
  m = ('0' + (date.getMonth() + 1)).slice(-2)
  d = ('0' + date.getDate()).slice(-2)
  return "#{Y}/#{m}"

toYmdDate = (date) ->
  Y = date.getFullYear()
  m = ('0' + (date.getMonth() + 1)).slice(-2)
  d = ('0' + date.getDate()).slice(-2)
  return "#{Y}/#{m}/#{d}"

# 時刻を受け取ってhh:mm形式で返す
tohhmmTime = (date) ->
  hh = ('0' + date.getHours()).slice(-2)
  mm = ('0' + date.getMinutes()).slice(-2)
  return "#{hh}:#{mm}"

beginnigOfDay = (date) ->
  date.setHours(0,0,0,0)

endOfDay = (date) ->
  date.setHours(23,59,59,999)

summarySpot = (spot) ->
  if spot.match(/toire|トイレ|といれ|:toilet:/i)
    return ':toilet:'
  else if spot.match(/gomi|ゴミ|ごみ/i)
    return ':put_litter_in_its_place:'
  else if spot.match(/掃除機|そうじき|床|ゆか|部屋|へや/i)
    return ':cyclone:'
  else
    return spot


firebase = require('firebase')
config = {
  apiKey: process.env.FIREBASE_API_KEY
  authDomain: process.env.FIREBASE_AUTH_DOMAIN
  databaseURL: process.env.FIREBASE_DATABASE_URL
  projectId: process.env.FIREBASE_PROJECT_ID
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID
};
firebase.initializeApp config
db = firebase.database()
Task = db.ref "tasks"
TimeTracker = db.ref "timeTrackers"
Souji = db.ref "soujis"


module.exports = (robot) ->
  robot.hear /^@(.*) task (.*)/i, (res) ->
    user = res.match[1].toLowerCase()
    ref = Task.child(user)
    date = new Date
    ref.push().set {
      user: res.message.user.name,
      task: res.match[2],
      created_date: toYmdDate(date),
      created_time: tohhmmTime(date),
      created: date.getTime() }
    res.send "ok"

  robot.respond /(souji|soji|掃除|そうじ)\s(.+)?/i, (res) ->
    user = res.message.user.name.toLowerCase()
    date = new Date
    ref = Souji.child(toYmDate(date))
    ref.push().set {
      user: user,
      spot: summarySpot(res.match[2] || ''),
      created_date: toYmdDate(date),
      created_time: tohhmmTime(date),
      created: date.getTime() }
    res.send "thx #{user}"

  robot.respond /掃除集計.*\s?(\d+\/\d+)?/i, (res) ->
    term = res.match[2] || toYmDate(new Date)
    ref = Souji.child(term)
    ref.once "value", (data) ->
      message = []
      souji = {}
      values = data.val()
      Object.keys(values).forEach (key) ->
        v = values[key]
        souji[v.user] = 0 if !souji[v.user]
        souji[v.user] += 1
      Object.keys(souji).forEach (user) ->
        message.push "#{user} #{souji[user]}"
      res.send message.join '\n'

  robot.respond /task clear/i, (res) ->
    robot.logger.info res
    user = res.message.user.name.toLowerCase()
    key = "#{user}Task"
    robot.brain.remove(key)

  robot.respond /task$/i, (res) ->
    user = res.message.user.name.toLowerCase()
    ref = Task.child(user)
    date = new Date
    ref.orderByChild("created").once "value", (data) ->
      message = []
      values = data.val()
      Object.keys(values).forEach (key) ->
        v = values[key]
        message.push "#{v.task}　登録日:#{v.created_date.slice(5)}"
      res.send message.join '\n'

  robot.hear /^now (.*)/i, (res) ->
    date = new Date
    user = res.message.user.name.toLowerCase()
    ref = TimeTracker.child([user,toYmdDate(date)].join('/'))
    ref.push().set {
      task: res.match[1],
      created: date.getTime(),
      created_date: toYmdDate(date),
      created_time: tohhmmTime(date)
    }


  robot.respond /集計/i, (res) ->
    date = new Date
    user = res.message.user.name
    ref = TimeTracker.child([user,toYmdDate(date)].join('/'))
    ref.orderByChild("created").once "value", (data) ->
      message = []
      values = data.val()
      Object.keys(values).forEach (key) ->
        v = values[key]
        message.push "#{v.created_time} #{v.task}"
      res.send message.join '\n'
