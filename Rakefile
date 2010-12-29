begin
    require 'jeweler'
    Jeweler::Tasks.new do |gemspec|
        gemspec.name = "simple_worker"
        gemspec.summary = "Classified"
        gemspec.description = "I could tell you, but then I'd have to..."
        gemspec.email = "travis@appoxy.com"
        gemspec.homepage = "http://github.com/appoxy/simple_worker"
        gemspec.authors = ["Travis Reeder"]
        gemspec.files = FileList['init.rb', 'lib/**/*.rb', 'rails/**/*.rb']
#        gemspec.add_dependency 'active_support' Causing issues when doing gem update, not sure why?
        gemspec.add_dependency 'appoxy_api'
    end

    Jeweler::GemcutterTasks.new
rescue LoadError
    puts "Jeweler not available. Install it with: sudo gem install jeweler -s http://gems.github.com"
end

task :test do
    require 'lib/simple_worker'
    ruby 'test/simple_worker_tests.rb'
end

