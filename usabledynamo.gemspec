# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "usabledynamo"
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY  
  s.summary     = "ActiveRecord like AWS-DynamoDB Client using API version 2012-08-10."
  s.email       = "support@usablelabs.com"
  s.homepage    = "http://github.com/thawatchai/usabledynamo"
  s.description = "ActiveRecord like AWS-DynamoDB Client using API version 2012-08-10."
  s.authors     = ['Thawatchai Piyawat', 'John Tjanaka']

  s.rubyforge_project = "usabledynamo"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("rails", ">= 3.0")
end
