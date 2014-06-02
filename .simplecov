SimpleCov.start do
  coverage_dir "corundum/docs/coverage"
  add_filter "./spec"
  add_filter {|path|
    path =~ %r{vendor/.*/ruby/.*/gems}
  }
end
