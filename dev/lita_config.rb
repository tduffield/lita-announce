Lita.configure do |config|
  config.robot.log_level = :debug
  config.robot.adapter = :slack
  config.robot.admins = ["1"]

  config.adapters.slack.token = ENV["SLACK_TOKEN"]
end
