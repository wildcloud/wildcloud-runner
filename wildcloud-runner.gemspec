lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'wildcloud/runner/version'

Gem::Specification.new do |s|
  s.name        = 'wildcloud-runner'
  s.version     = Wildcloud::Runner::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Marek Jelen']
  s.email       = ['marek@jelen.biz']
  s.homepage    = 'http://github.com/wildcloud'
  s.summary     = 'Virtual environment manager'
  s.description = 'Builds and runs applications inside virtual environment'
  s.license     = 'Apache2'

  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency 'eventmachine', '0.12.10'
  s.add_dependency 'json', '1.6.4'
  s.add_dependency 'wildcloud-logger', '>= 0.0.2'
  s.add_dependency 'wildcloud-configuration', '0.0.1'

  s.files        = Dir.glob('{bin,lib}/**/*') + %w(LICENSE README.md CHANGELOG.md)
  s.executables = %w(wildcloud-runner)
  s.require_path = 'lib'
end