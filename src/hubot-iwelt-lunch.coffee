# Description
#   Simple Hubot script to list the current lunch dishes
#
# Commands:
#   hubot lunch - List the daily Benedini lunch dishes
#   hubot lunch 2017-3-30 - List Benedini's lunch dishes of 2017-3-30
#
# Author:
#   Jonas Friedmann <j@frd.mn>

API_URL="https://benedini.intern.iwelt.de/api/get_meals"

# transform_to_emoji_numbers = (numbers) ->
#   digit_word_map = {
#     0: ':zero:',
#     1: ':one:',
#     2: ':two:',
#     3: ':three:',
#     4: ':four:',
#     5: ':five:',
#     6: ':six:',
#     7: ':seven:',
#     8: ':eight:',
#     9: ':nine:'
#   }
#
#   return (numbers.toString().split('').map (number) -> digit_word_map[number]).join('')

construct_meal_plan = (res, json, weekday) ->
  data = JSON.parse json

  if (!data? || data.length == 0)
    console.log("Error reading data")
    console.log(data)
    return "Error reading JSON from server. Please try again later!"
  else
    dailies = []
    alerts = []
    foods = []

    for dish in data
      if dish.ordered
        orderAmountString = "(#{dish.ordered} Bestellungen)"
      else
        orderAmountString = ""

      dishPrice = (dish.price / 100).toFixed(2)
      dishString = "- #{dish.meal}: `#{dishPrice}` #{orderAmountString}"

      if dish.daily isnt true
        foods.push dishString
      else
        dailies.push dishString

    if (data.some (dish) -> /burger/i.test(dish.meal))
      alerts = ["🍔🍔🍔🍔🍔🍔 *BURGERALARM*  🍔🍔🍔🍔🍔🍔"].concat alerts

    if (data.some (dish) -> /currywurst/i.test(dish.meal))
      alerts = ["🔔🔔🔔🔔🔔🔔 *CURRYWURST* 🔔🔔🔔🔔🔔🔔"].concat alerts

    responseString = ""
    if alerts.length > 0
      responseString += "#{alerts.join("\n")}\n"
    if foods.length > 0
      responseString += "\n*Fest*:\n#{foods.join("\n")}\n"
    if dailies.length > 0
      responseString += "\n*Tagesgerichte*:\n#{dailies.join("\n")}\n"

    return responseString

speiseplan = (robot, response) ->
  if response.match[1]
    today = response.match[1]
  else
    now = new Date()
    today = now.getFullYear() + "-" + (now.getMonth()+1) + "-" + (now.getDate())

  data = JSON.stringify({
    date: today
  })

  robot.http(API_URL)
    .header('Content-Type', 'application/json')
    .post(data) (err, res, body) =>
      meal_plan = construct_meal_plan(res, body, today)
      response.send "#### Benedini Speiseplan für #{today}:\n#{meal_plan}"

module.exports = (robot) ->
  robot.respond /lunch ?(\S*)/i, (response) ->
    speiseplan(robot, response)
