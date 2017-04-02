load 'environment.rb'
task :record_data do
  RunCamera.new.run
end

task :analyze_data do
  while true
    puts Time.now
    RunPredictor.new.run
    puts "Sleeping for an hour!"
    sleep(3600)
  end
end

task :summarize_data do
  StopSignLog.generate_stats
end
