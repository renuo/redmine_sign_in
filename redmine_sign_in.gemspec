Gem::Specification.new do |s|
  s.name     = 'redmine_sign_in'
  s.version  = '0.1.0'
  s.authors  = [ 'Simon Isler' ]
  s.email    = [ 'simon.isler@renuo.ch' ]
  s.summary  = 'Sign in with Redmine for Rails applications'
  s.homepage = 'https://github.com/renuo/redmine_sign_in'
  s.license  = 'MIT'

  s.required_ruby_version = '>= 3.1.0'

  s.add_dependency 'rails', '>= 7.1.0'
  s.add_dependency 'oauth2', '>= 2.0.0'

  s.files = Dir["{app,config,lib}/**/*", "MIT-LICENSE", "README.md"]
end
