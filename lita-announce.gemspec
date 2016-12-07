Gem::Specification.new do |spec|
  spec.name          = "lita-announce"
  spec.version       = "0.1.2"
  spec.authors       = ["Tom Duffield"]
  spec.email         = ["tom@chef.io"]
  spec.description   = "Lita plugin to make announcements across multiple channels."
  spec.summary       = "Lita plugin to make announcements across multiple channels."
  spec.homepage      = "http://github.com/tduffield/lita-announce"
  spec.license       = "Apache 2.0"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 4.7"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"
  spec.add_development_dependency "chefstyle", "~> 0.3"
end
