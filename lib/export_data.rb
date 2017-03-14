class ExportData
  def self.run
    `rsync -r #{CONFIG["raspi_rsync_addr"]}../videos .`
    `rsync -r #{CONFIG["raspi_rsync_addr"]}cases .`
    `rsync #{CONFIG["raspi_rsync_addr"]}stop_sign.log #{CONFIG["project_dir"]}stop_sign.log`
    `rsync #{CONFIG["raspi_rsync_addr"]}stream_record.log #{CONFIG["project_dir"]}stream_record.log`
  end
  
  def self.analyze_locally
    ObservationPeriod.import
    video_library = `ls #{CONFIG["project_dir"]}videos`.split("\n")
    ObservationPeriod.where(processed: false).each do |op|
      if video_library.include?(op.observation_timestamp.to_i.to_s+".avi")
        avi = op.observation_timestamp.to_i.to_s+".avi"
        `rm stop_sign.log`
        `python #{CONFIG["project_dir"]}analyze_video.py --video #{CONFIG["project_dir"]}videos/#{avi} --time #{avi.split(".").first}`
        `touch stop_sign.log`
        StopSignLog.import
        op.processed = true
        op.save!
      end
    end
  end
  
  def self.generate_gifs
    existing_gifs = `ls #{CONFIG["project_dir"]}public/gif_cases`.split("\n")
    StopSignLog.each do |ssl|
      ssl_filename = "#{ssl.observation_timestamp}_#{ssl.stop_id}.gif"
      if !existing_gifs.include?(ssl_filename)
        `ffmpeg -i #{CONFIG["project_dir"]}cases/#{ssl_filename.gsub(".gif", ".avi")} -vf scale=320:-1 -r 10 -f image2pipe -vcodec ppm - | convert -delay 5 -loop 0 - #{CONFIG["project_dir"]}public/gif_cases/#{ssl_filename}`
      end
    end
  end
  
  def self.generate_machine_learning_dataset(key="human_votes_car_present")
    dataset = CSV.open("machine_learning_#{key}.csv", "w")
    weird_ones = []
    StopSignLog.each do |ssl|
      votes = ssl.send(key)
      row = []
      x_dist = ssl.centroid_data.collect(&:first)
      x_diff_dist = []
      x_dist[0..-2].each_with_index do |val,i|
        x_diff_dist << val - x_dist[i+1]
      end
      y_dist = ssl.centroid_data.collect(&:last)
      y_diff_dist = []
      y_dist[0..-2].each_with_index do |val,i|
        y_diff_dist << val - y_dist[i+1]
      end
      if votes.average == 1
        row << 1
      elsif votes.average == 0
        row << 0
      else
        weird_ones << ssl
        next
      end
      row << [
        ssl.at_disallowed_time == true ? 1 : 0,
        ssl.daylight == true ? 1 : 0,
        ssl.number_stopped_frames,
        ssl.frame_count,
        ssl.x_velocity,
        ssl.event_at.days_to_week_start,
        ssl.event_at.hour,
        x_dist.average,
        x_dist.min,
        x_dist.max,
        x_dist.median,
        x_dist.sample_variance,
        x_diff_dist.average,
        x_diff_dist.min,
        x_diff_dist.max,
        x_diff_dist.median,
        x_diff_dist.sample_variance,
        y_dist.average,
        y_dist.min,
        y_dist.max,
        y_dist.median,
        y_dist.sample_variance,
        y_diff_dist.average,
        y_diff_dist.min,
        y_diff_dist.max,
        y_diff_dist.median,
        y_diff_dist.sample_variance
      ]
      dataset << row.flatten
    end
    dataset.close
  end
end
#ObservationPeriod.collection.drop
#StopSignLog.collection.drop
#ExportData.analyze_locally
#ExportData.generate_gifs