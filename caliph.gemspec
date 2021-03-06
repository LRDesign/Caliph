Gem::Specification.new do |spec|
  spec.name		= "caliph"
  #{MAJOR: incompatible}.{MINOR added feature}.{PATCH bugfix}-{LABEL}
  spec.version		= "0.3.1"
  author_list     = { "Evan Dorn" => 'evan@lrdesign.com', "Judson Lester" => 'judson@lrdesign.com' }
  spec.authors		= author_list.keys
  spec.email		  = spec.authors.map {|name| author_list[name]}
  spec.summary		= "TDD-suitable Ruby tool for generating command-line commands via an OOP interface."
  spec.description = <<-EndDescription
    TDD-suitable Ruby tool for generating command-line commands via an OOP interface.
  EndDescription

  spec.homepage        = "https://github.com/LRDesign/Caliph"
  spec.required_rubygems_version = Gem::Requirement.new(">= 0") if spec.respond_to? :required_rubygems_version=

  # Do this: y$@"
  # !!find lib bin doc spec spec_help -not -regex '.*\.sw.' -type f 2>/dev/null
  spec.files		= %w[
    lib/caliph/command-chain.rb
    lib/caliph/command-line-dsl.rb
    lib/caliph/command-line.rb
    lib/caliph/command-run-result.rb
    lib/caliph/define-op.rb
    lib/caliph/describer.rb
    lib/caliph/shell-escaped.rb
    lib/caliph/testing/mock-command-line.rb
    lib/caliph/testing/record-commands.rb
    lib/caliph.rb
    lib/caliph/shell.rb
    spec/command-chain.rb
    spec/command-line-dsl.rb
    spec/command-line.rb
    spec_help/gem_test_suite.rb
    spec_help/spec_helper.rb
  ]

  spec.test_file        = "spec_help/gem_test_suite.rb"
  spec.licenses = ["MIT"]
  spec.require_paths = %w[lib/]
  spec.rubygems_version = "1.3.5"

  spec.has_rdoc		= true
  spec.extra_rdoc_files = Dir.glob("doc/**/*")
  spec.rdoc_options	= %w{--inline-source }
  spec.rdoc_options	+= %w{--main doc/README }
  spec.rdoc_options	+= ["--title", "#{spec.name}-#{spec.version} Documentation"]

  #spec.add_dependency("", "> 0")

  #spec.post_install_message = "Thanks for installing my gem!"
end
