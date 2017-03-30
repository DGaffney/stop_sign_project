class Reporting
  def self.generate
    ssls = StopSignLog.where("voted_as.presence" => true, "voted_as.full_scene" => true).fields(:observation_timestamp).collect{|x| Time.at(x.observation_timestamp)}
    violation_counts = Hash[ssls.collect{|x| x.strftime("%H")}.counts.sort_by{|k,v| k}]
    ssls_weekend = StopSignLog.where("voted_as.presence" => true, "voted_as.full_scene" => true).fields(:observation_timestamp).select{|x| Time.at(x.observation_timestamp).strftime("%w") == "0" || Time.at(x.observation_timestamp).strftime("%w") == "6"}.collect{|x| Time.at(x.observation_timestamp)}
    weekend_violation_counts = Hash[ssls_weekend.collect{|x| x.strftime("%H")}.counts.sort_by{|k,v| k}]
    ssls_weekday = StopSignLog.where("voted_as.presence" => true, "voted_as.full_scene" => true).fields(:observation_timestamp).select{|x| !(Time.at(x.observation_timestamp).strftime("%w") == "0" && Time.at(x.observation_timestamp).strftime("%w") == "6")}.collect{|x| Time.at(x.observation_timestamp)}
    weekday_violation_counts = Hash[ssls_weekday.collect{|x| x.strftime("%H")}.counts.sort_by{|k,v| k}]
    def time_converter
      {"04" => "00",
      "05" => "01",
      "06" => "02",
      "07" => "03",
      "08" => "04",
      "09" => "05",
      "10" => "06",
      "11" => "07",
      "12" => "08",
      "13" => "09",
      "14" => "10",
      "15" => "11",
      "16" => "12",
      "17" => "13",
      "18" => "14",
      "19" => "15",
      "20" => "16",
      "21" => "17",
      "22" => "18",
      "23" => "19",
      "00" => "20",
      "01" => "21",
      "02" => "22",
      "03" => "23"}
    end
    current_violation_ratio = Vote.where(vote_method: "stop_violations", vote: 0).count/(Vote.where(vote_method: "stop_violations", vote: 0).count.to_f+Vote.where(vote_method: "stop_violations", vote: 1).count)
    obs_expanded = {}
    proj_started = ObservationPeriod.order(:start_time).first.start_time
    proj_ended = ObservationPeriod.order(:end_time).last.end_time
    ObservationPeriod.to_a.each do |op|
      obs_expanded[op.observation_timestamp.strftime("%H")] ||= []
      obs_expanded[op.observation_timestamp.strftime("%H")] << op.interevent_time
    end
    coverage_ratio = obs_expanded.collect{|k,v| [k,(proj_ended-proj_started)/(24*v.sum)]}
    obs_expanded_weekend = {}
    obs_expanded_weekday = {}
    proj_started = ObservationPeriod.order(:start_time).first.start_time
    proj_ended = ObservationPeriod.order(:end_time).last.end_time
    ObservationPeriod.to_a.each do |op|
      if op.observation_timestamp.strftime("%w") == "0" || op.observation_timestamp.strftime("%w") == "6"
        obs_expanded_weekend[op.observation_timestamp.strftime("%H")] ||= []
        obs_expanded_weekend[op.observation_timestamp.strftime("%H")] << op.interevent_time
      else
        obs_expanded_weekday[op.observation_timestamp.strftime("%H")] ||= []
        obs_expanded_weekday[op.observation_timestamp.strftime("%H")] << op.interevent_time
      end
    end;false
    (proj_ended-proj_started)/60/60/24
    weekend_coverage_ratio = obs_expanded.collect{|k,v| [k,((proj_ended-proj_started)*2/7.0)/(24*v.sum)]}.sort_by{|k,v| k}
    weekday_coverage_ratio = obs_expanded.collect{|k,v| [k,((proj_ended-proj_started)*5/7.0)/(24*v.sum)]}.sort_by{|k,v| k}
    csv = CSV.open("report.csv", "w")
    csv << ["Full"]
    csv << ["Hour UTC", "Hour EST", "Obs Count", "Obs Coverage", "Percent Violation" "Re-scaled count" "Hour EST", "Number of Violations","Number of Violations During Ban"]
    "00".upto("23").to_a.collect{|x| [x, time_converter[x]]}.sort_by{|k,v| v.to_i}.each do |hour_utc, hour_est|
    row = [hour_utc, hour_est, obs_expanded[hour_utc].count, Hash[coverage_ratio][hour_utc]]
    end
    puts weekend_coverage_ratio.collect{|x|x.join(",")}
    time_converter
  end
end
