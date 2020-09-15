require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|

  t.libs << 'test'
  t.test_files = FileList['test/coverage_support.rb', 'test/test*.rb']
  t.verbose = true
  t.options = '-v'

end
