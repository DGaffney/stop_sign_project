class MachineLearner
  include MongoMapper::Document
  key :vote_method, String
  key :accuracy, Float
  key :conmat, Hash
end