Gem::Specification.new do |s|
  s.name        = 'active_record_translated'
  s.version     = '0.0.1'
  s.date        = '2016-02-23'
  s.summary     = 'ActiveRecord attributes translated'
  s.description = 'A gem for translating ActiveRecord model attributes'
  s.authors     = ['Mārcis Viškints']
  s.email       = 'marcis.viskints@gmail.com'
  s.homepage    = 'https://github.com/marcisv/activerecord-translated'
  s.license     = 'MIT'

  s.files       = ['lib/active_record_translated.rb']
  s.test_files  = Dir["spec/**/*"]

  s.add_dependency 'activerecord', '>= 3.0'
  s.add_dependency 'activesupport', '>= 3.0'

  s.add_development_dependency 'rspec', '~> 3.4.0'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'sqlite3'
end
