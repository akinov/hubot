# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md

# 時刻を受け取ってYYYY-mm-dd形式で返す
toYmdDate = (date) ->
  Y = date.getFullYear()
  m = ('0' + (date.getMonth() + 1)).slice(-2)
  d = ('0' + date.getDate()).slice(-2)
  return "#{Y}-#{m}-#{d}"

# 時刻を受け取ってhh:mm形式で返す
tohhmmTime = (date) ->
  hh = ('0' + date.getHours()).slice(-2)
  mm = ('0' + date.getMinutes()).slice(-2)
  return "#{hh}:#{mm}"

getKey = (user) ->



module.exports = (robot) ->
  robot.hear /^@(.*) task (.*)/i, (res) ->
    user = res.match[1].toLowerCase()
    key = "#{user}Task"

    # 日付を取得
    date = new Date

    # 要素の保存
    tasks = robot.brain.get(key) ? [] # keyを元に全要素を持ってくる。なければ空Objectをセット
    tasks.push { created: toYmdDate(date), task: res.match[2] }
    robot.brain.set key, tasks # すべての要素を保存
    robot.logger.info(robot.brain.get(key))
    res.send "ok"

  robot.respond /task clear/i, (res) ->
    # keyを設定
    user = res.message.user.name
    key = "#{user}Task"
    robot.brain.remove(key)

  robot.respond /task (\d+) del/i, (res) ->
    i = res.match[1]
    # keyを設定
    user = res.message.user.name
    key = "#{user}Task"
    tasks = robot.brain.get(key) ? [] # keyを元に全要素を持ってくる。なければ空Objectをセット
    task = tasks[i]
    tasks.splice(i, 1)
    robot.brain.set key, tasks
    res.send "del #{task.task}"

  robot.respond /task$/i, (res) ->
    # keyを設定
    user = res.message.user.name
    key = "#{user}Task"

    tasks = robot.brain.get(key) ? []
    message = tasks.map (task, i) ->
      "[#{i}] #{task.task}\t\t登録日:#{task.created.slice(5)}"
    .join '\n'
    res.send "#{message}"

  robot.hear /^now (.*)/i, (res) ->
    # keyを設定
    user = res.message.user.name
    key = "#{user}TimeTracker"

    # 日付を取得
    date = new Date
    ymd = toYmdDate date

    # 要素の保存
    tasks = robot.brain.get(key) ? {} # keyを元に全要素を持ってくる。なければ空Objectをセット
    today_tasks = tasks[ymd] ? []
    today_tasks.push { time: tohhmmTime(date), task: res.match[1] }
    tasks[ymd] = today_tasks # 追加要素を作成
    robot.brain.set key, tasks # すべての要素を保存
    robot.logger.info(robot.brain.get(key))

  robot.respond /集計/i, (res) ->
    # keyを設定
    user = res.message.user.name
    key = "#{user}TimeTracker"

    # 日付を取得
    date = new Date
    ymd = toYmdDate date

    tasks = robot.brain.get(key) ? {}
    today_tasks = tasks[ymd] ? []
    message = today_tasks.map (task) ->
      "#{task.time} #{task.task}"
    .join '\n'
    res.send "#{message}"
