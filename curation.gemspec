require_relative 'lib/curation/version'

Gem::Specification.new do |spec|
  spec.name          = "curation"
  spec.version       = Curation::VERSION
  spec.authors       = ["Arnaud Levy"]
  spec.email         = ["contact@arnaudlevy.com"]

  spec.summary       = 'Curation of content'
  spec.description   = %q{When you build content curation tools, you need to extract the content of pages (title, text, image...). This requires different strategies and some fine tuning to work efficiently.}
  spec.homepage      = "https://github.com/arnaudlevy/curation"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/arnaudlevy/curation"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency "metainspector"
  spec.add_dependency "nokogiri"
end
