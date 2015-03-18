Gem::Specification.new do |spec|
  spec.name          = "lita-translation"
  spec.version       = "1.0.0"
  spec.authors       = ["Michael Chua"]
  spec.email         = ["chua.mbt@gmail.com"]
  spec.description   = %q{Language translation plugin that uses Microsoft's Translator API. }
  spec.summary       = %q{Language translation plugin that uses Microsoft's Translator API. }
  spec.license       = "MIT"
  spec.metadata      = { "lita_plugin_type" => "handler" }
  spec.homepage      = "https://github.com/chua-mbt/lita-translation"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 4.2"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"
end
