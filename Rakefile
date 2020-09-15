require 'rake/testtask'

task :default => :coverage

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
  t.options = '-v'
end

task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['test'].execute
end
