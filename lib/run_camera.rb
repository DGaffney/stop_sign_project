#This technique is from here: https://www.raspberrypi.org/forums/viewtopic.php?f=38&t=156555
class RunCamera
  def stream_photos
    `mkdir #{CONFIG["project_dir"]}pics`
    `mjpg_streamer -b -i "/usr/local/lib/input_uvc.so -d /dev/video0 -y -r 500x375 -f 20 -q 50"  -o "/usr/local/lib/output_file.so -f #{CONFIG["project_dir"]}pics -d 0"`
  end

  def get_stream_pid
    `ps -eaf | grep mjpg_streamer | grep STICK`.split("\n").reject{|x| x.include?("ps -eaf")}.first.split(" ")[1].to_i
  end

  def get_frame_count
    `ls #{CONFIG["project_dir"]}pics`.split("\n").count
  end

  def kill_stream(streamer_pid)
    `kill -SIGINT #{streamer_pid}`
  end
  
  def drop_frames(drop_frame_count)
    `ls #{CONFIG["project_dir"]}pics`.split("\n")[0..drop_frame_count].each do |frame|
      `rm #{CONFIG["project_dir"]}pics/#{frame}`
    end
  end

  def gen_video(time)
    `ffmpeg -framerate 25 -pattern_type glob -i '#{CONFIG["project_dir"]}pics/*.jpg' -c:v h264 -b:v 10000000 #{CONFIG["project_dir"]}videos/#{time}.mp4`
  end
  
  def convert_to_avi(time)
    `mkdir #{CONFIG["project_dir"]}videos`
    `ffmpeg -i #{CONFIG["project_dir"]}videos/#{time}.mp4 -vcodec mpeg4 -acodec ac3 #{CONFIG["project_dir"]}videos/#{time}.avi`
  end
  
  def clear_frames
    `rm #{CONFIG["project_dir"]}pics/*`
  end
  
  def analyze_video(time)
    `python #{CONFIG["project_dir"]}analyze_video.py --video #{CONFIG["project_dir"]}videos/#{time}.avi --time #{time}`
  end

  def remove_mp4(time)
    `rm #{CONFIG["project_dir"]}videos/#{time}.mp4`
  end

  def run
    while true
      puts "Hello again - time is now #{Time.now}, streaming starting"
      puts "Streaming"
      start_time = Time.now.utc
      stream_photos
      streamer_pid = get_stream_pid
      frame_count = get_frame_count
      drop_frame_count = 50
      while frame_count < 25*60+drop_frame_count && (Time.now.utc-start_time) < 10*60
        sleep(1)
        frame_count = get_frame_count
      end
      puts "Stream finished. Converting"
      kill_stream(streamer_pid)
      end_time = Time.now.utc
      drop_frames(drop_frame_count)
      time = Time.now.utc.to_i
      gen_video(time)
      convert_to_avi(time)
      clear_frames
      remove_mp4(time)
      puts "Conversion Finished. Analyzing"
      analyze_video(time)
      op = ObservationPeriod.first_or_create(observation_timestamp: Time.at(time))
      op.start_time = start_time
      op.end_time = end_time
      op.interevent_time = (end_time-start_time).to_f
      op.processed = false
      op.save!
      if `ls #{CONFIG["project_dir"]}`.split("\n").include?("stop_sign.log")
        ["presence", "stop_violations", "wrong_way_violations"].each do |vote_method|
          RunPredictor.run if rand < 0.10
        end
        StopSignLog.import
        op.processed = true
        op.save!
        `rm #{CONFIG["project_dir"]}stop_sign.log`
      end
      puts "Checking for unsaved imgurs..."
      [StopSignLog.where(imgur_url: nil).to_a, StopSignLog.where(imgur_url: "").to_a].flatten.each do |ssl|
        ssl_filename = "#{ssl.observation_timestamp}_#{ssl.stop_id}.gif"
        img_path = `python push_to_imgur.py -g public/gif_cases/#{ssl_filename}`.strip
        ssl.imgur_url = img_path
        ssl.save!
      end
      puts "Sleeping for one minute to allow Ctrl-C..."
      sleep(60)
    end
  end

  def video_check
    stream_photos
    streamer_pid = get_stream_pid
    frame_count = get_frame_count
    while frame_count < 100
      sleep(1)
      frame_count = get_frame_count
    end
    kill_stream(streamer_pid)
    time = Time.now.utc.to_i
    gen_video(time)
    convert_to_avi(time)
    clear_frames
    remove_mp4(time)
    analyze_video(time)
  end
end
#Record.new.video_check
