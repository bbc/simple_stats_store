Gem::Specification.new do |s|
  s.name        = 'simple_stats_store'
  s.version     = '1.0.4'
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary     = 'Simple Stats Store'
  s.description = 'Using SQLite3 to store statistics from a multithreaded application'
  s.authors     = ['Joe Haig']
  s.email       = 'joe.haig@bbc.co.uk'
  s.files       = Dir['README.md', 'lib/**/*.rb' ]
  s.homepage    = 'https://github.com/bbc/simple_stats_store'
  s.license     = 'MIT'
end
