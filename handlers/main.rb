get "/" do
  @total_time = ObservationPeriod.fields(:interevent_time).collect(&:interevent_time).sum
  erb :"index"
end

get "/train/presence" do
  @ssl = StopSignLog.get_random
  @vote_type = "Car Presence"
  @vote_method = "presence"
  @vote_negative = "No Car"
  @vote_affirmative = "Yes Car"
  @vote_text = "Is there a moving car in this GIF? Press J if there isn't, K if there is (or just click the links below)"
  erb :"vote"
end

get "/train/stop_violations" do
  @ssl = StopSignLog.get_random
  @vote_type = "Car Stop Violation"
  @vote_method = "stop_violations"
  @vote_negative = "No Stop"
  @vote_affirmative = "Yes Stop"
  @vote_text = "Is a car present in this GIF *and* is it blowing the stop sign? Press J if there isn't, K if there is (or just click the links below)"
  erb :"vote"
end

get "/train/wrong_way_violations" do
  @ssl = StopSignLog.get_random
  @vote_type = "Car Wrong Way Violation"
  @vote_method = "wrong_way_violations"
  @vote_negative = "No Wrong Way"
  @vote_affirmative = "Yes Wrong Way"
  @vote_text = "Is there a car going the wrong way (wrong here is any car moving left-to-right)? Press J if there isn't, K if there is (or just click the links below)"
  erb :"vote"
end

get "/train/vote/:vote_method/:stop_id/:vote_result" do
  @ssl = StopSignLog.first(stop_id: params[:stop_id])
  if params[:vote_result] == "affirmative"
    v = Vote.new(stop_id: params[:stop_id], vote_method: params[:vote_method], vote: 1, session_id: @env["rack.session"]["session_id"])
    v.save!
  elsif params[:vote_result] == "negative"
    v = Vote.new(stop_id: params[:stop_id], vote_method: params[:vote_method], vote: 0, session_id: @env["rack.session"]["session_id"])
    v.save!
  end
  @ssl.save!
  redirect "/train/#{params[:vote_method]}"
end
