class MachineLearner
  include MongoMapper::Document
  key :vote_method, String
  key :accuracy, Float
  key :conmat, Hash
  
  def estimated_count
    marked_true = StopSignLog.count("voted_as.#{ml.vote_method}" => true)
    marked_false = StopSignLog.count("voted_as.#{ml.vote_method}" => false)
    return (marked_true*(ml.conmat["tp"].to_f / (ml.conmat["fp"].to_f + ml.conmat["tp"].to_f))+marked_false*(ml.conmat["fn"].to_f / (ml.conmat["fn"].to_f + ml.conmat["tp"].to_f))).to_i
  end
end