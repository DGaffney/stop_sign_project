class MachineLearner
  include MongoMapper::Document
  key :vote_method, String
  key :accuracy, Float
  key :conmat, Hash
  
  def estimated_count
    marked_true = StopSignLog.count("voted_as.#{self.vote_method}" => true)
    marked_false = StopSignLog.count("voted_as.#{self.vote_method}" => false)
    return (marked_true*(self.conmat["tp"].to_f / (self.conmat["fp"].to_f + self.conmat["tp"].to_f))+marked_false*(self.conmat["fn"].to_f / (self.conmat["fn"].to_f + self.conmat["tp"].to_f))).to_i
  end
  
  def precision
    self.conmat["tp"].to_f / (self.conmat["tp"].to_f + self.conmat["fp"].to_f )
  end

  def recall
    self.conmat["tp"].to_f / (self.conmat["tp"].to_f + self.conmat["fn"].to_f )
  end
end