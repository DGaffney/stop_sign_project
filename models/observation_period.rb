class ObservationPeriod
  include MongoMapper::Document
  key :start_time, Time
  key :end_time, Time
  key :interevent_time, Float
  key :observation_timestamp, Time
  key :processed, Boolean

  def self.import(import_file = "#{CONFIG["project_dir"]}stream_record.log")
    CSV.read(import_file).each do |row|
      if ObservationPeriod.first(observation_timestamp: Time.at(row.last.to_i)).nil?
        op = ObservationPeriod.first_or_create(observation_timestamp: Time.at(row.last.to_i))
        op.start_time = Time.at(row.first.to_i)
        op.end_time = Time.at(row[1].to_i)
        op.interevent_time = row[2].to_f
        op.processed = false
        op.save!
      end
    end
  end
  
  def logs
    StopSignLog.where(observation_timestamp: self.observation_timestamp.utc.to_i).to_a
  end
end
