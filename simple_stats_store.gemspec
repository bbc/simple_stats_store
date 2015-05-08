Gem::Specification.new do |s|
  s.name        = 'simple_stats_store'
  s.version     = '0.0.1'
  s.date        = '2015-04-30'
  s.summary     = 'Simple Stats Store'
  s.description = 'Using SQLite3 to store statistics from a multithreaded application'
  s.authors     = ['Joe Haig']
  s.email       = 'joe.haig@bbc.co.uk'
  s.files       = Dir['README.md', 'lib/**/*.rb' ]
  s.homepage    = 'https://github.com/bbc/simple_stats_store'
  s.add_dependency 'activerecord'
  s.add_dependency 'activerecord-rescue_from_duplicate'
  s.add_dependency 'sqlite3'
  s.license     = 'MIT'
end
