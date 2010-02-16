require "rake/testtask"

desc "Default task:  run all tests"
task :default => :test

Rake::TestTask.new do |test|
  test.libs    << "test"
  test.pattern =  "test/*_test.rb"
  test.warning =  true
  test.verbose =  true
end

desc "Clear all log files"
task :clear_logs do
  system( "rm #{File.join(File.dirname(__FILE__), *%w[log *.{log,html}])} " +
          "2> /dev/null" )
end