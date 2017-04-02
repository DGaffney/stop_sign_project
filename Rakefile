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
  while true
    begin
      puts Time.now
      StopSignLog.generate_stats
      puts "Sleeping for an hour!"
      sleep(3600)
    rescue
      retry
    end
  end
end
