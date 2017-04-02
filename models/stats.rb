class Stats
  include MongoMapper::Document
  key :name, String
  key :hourly, Hash
  key :daily, Hash
  key :total_transits, Integer
  key :violation_rate, Float
  key :observed_count, Integer
  key :extrapolated_count, Integer
  key :observation_period_count, Integer
  key :stop_sign_log_count, Integer
  key :seconds_observed, Float
  key :total_study_time, Float
  key :current_violation_votes, Array
  key :presence_vote_count, Integer
  key :full_scene_vote_count, Integer
  key :stop_violations_vote_count, Integer
  key :wrong_way_violations_vote_count, Integer
end