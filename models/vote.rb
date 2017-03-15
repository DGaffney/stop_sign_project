class Vote
  include MongoMapper::Document
  timestamps!
  key :stop_id, String
  key :vote_method, String
  key :vote, Integer
  key :session_id, String
  
  def self.indices
    Vote.ensure_index(:vote_method)
    Vote.ensure_index([[:vote_method, 1], [:stop_id, 1]])
  end
end
