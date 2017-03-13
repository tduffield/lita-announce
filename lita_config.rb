require "lita/adapters/slack"

Lita.configure do |config|
  config.robot.log_level = :debug
  config.robot.adapter = :slack
  config.robot.admins = ["1"]

  # Use the redis host linked via docker-compose
  config.redis[:host] = "redis"

  config.adapters.slack.token = ENV["SLACK_TOKEN"]
end
