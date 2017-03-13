# Because we run Lita in a container, don't connect to STDIN
interactor :off

# Restart the lita CLI anytime we modify the lita_config or a lita file
guard "process", name: "Lita", command: "bundle exec lita" do
  watch("lita_config.rb")
  watch(%r{^lib/*})
end
