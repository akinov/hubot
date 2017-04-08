# 時刻を受け取ってYYYY-mm-dd形式で返す
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

  robot.respond /task clear/i, (res) ->
    robot.logger.info res
    user = res.message.user.name.toLowerCase()
    key = "#{user}Task"
    robot.brain.remove(key)

  robot.respond /task (\d+) del/i, (res) ->
    i = res.match[1]
    user = res.message.user.name.toLowerCase()
    key = "#{user}Task"
    tasks = robot.brain.get(key) ? [] # keyを元に全要素を持ってくる。なければ空Objectをセット
    task = tasks[i]
    tasks.splice(i, 1)
    robot.brain.set key, tasks
    res.send "del #{task.task}"

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
