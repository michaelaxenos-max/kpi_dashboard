require_relative "lib/corepulse/version"

Gem::Specification.new do |spec|
  spec.name        = "corepulse"
  spec.version     = CorePulse::VERSION
  spec.authors     = ["Lumin Brands"]
  spec.email       = ["team@lumin-labs.com"]

  spec.summary     = "Hubstaff sync + KPI engine for the KPI dashboard"
  spec.description = "Vendored reconstruction of the corepulse engine: Hubstaff API " \
                     "client, sync services, multi-day task handling, and KPI calculation. " \
                     "Model-agnostic — the host app injects its ActiveRecord models via CorePulse.configure."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir["lib/**/*.rb"] + ["README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", ">= 1.0"
  spec.add_dependency "jwt", ">= 2.0"
end
