VOTE_TYPES = {
  "presence" => {"machine_vote_yes": "Machine thinks there's a car in this GIF", "machine_vote_no": "Machine thinks there's not a car in this GIF", "vote_type" => "Car Presence", "vote_negative" => "No Car", "vote_affirmative" => "Yes Car", "vote_text" => "Is there a moving car in this GIF? Press J if there isn't, K if there is (or just click the links below)"},
  "stop_violations" => {"machine_vote_yes": "Machine thinks there's a car running the stop sign in this GIF", "machine_vote_no": "Machine thinks there's not a car running the stop sign in this GIF", "vote_type" => "Car Stop Violation", "vote_negative" => "No Stop", "vote_affirmative" => "Yes Stop", "vote_text" => "Is a car present in this GIF *and* is it blowing the stop sign? Press J if there isn't, K if there is (or just click the links below)"},
  "wrong_way_violations" => {"machine_vote_yes": "Machine thinks there's a car going the wrong way in this GIF", "machine_vote_no": "Machine thinks there's not a car going the wrong way in this GIF", "vote_type" => "Car Wrong Way Violation", "vote_negative" => "No Wrong Way", "vote_affirmative" => "Yes Wrong Way", "vote_text" => "Is there a car going the wrong way (wrong here is any car moving left-to-right)? Press J if there isn't, K if there is (or just click the links below)"}
}
get "/" do
  @total_time = ObservationPeriod.fields(:interevent_time).collect(&:interevent_time).sum
  erb :"index"
end

get "/train/:vote_method*" do
  @previous_stop_id = params["splat"][0].split("/").last
  @vote_method = params["vote_method"]
  @vote_type = VOTE_TYPES[@vote_method]["vote_type"]
  @vote_negative = VOTE_TYPES[@vote_method]["vote_negative"]
  @vote_affirmative = VOTE_TYPES[@vote_method]["vote_affirmative"]
  @vote_text = VOTE_TYPES[@vote_method]["vote_text"]
  @ssl = StopSignLog.get_random(@vote_method, @previous_stop_id)
  erb :"vote"
end

get "/vote/:vote_method/:stop_id/:vote_result" do
  @ssl = StopSignLog.first(stop_id: params[:stop_id])
  @ssl.order_hash[params[:vote_method]] ||= 0
  @ssl.order_hash[params[:vote_method]] += 1
  if params[:vote_result] == "affirmative"
    v = Vote.new(stop_id: params[:stop_id], vote_method: params[:vote_method], vote: 1, vote_ip: request.ip)
    v.save!
  elsif params[:vote_result] == "negative"
    v = Vote.new(stop_id: params[:stop_id], vote_method: params[:vote_method], vote: 0, vote_ip: request.ip)
    v.save!
  end
  @ssl.save!
  redirect "/train/#{params[:vote_method]}/#{@ssl.stop_id}"
end

get "/machine/:vote_method*" do
  @previous_stop_id = params["splat"][0].split("/").last
  @vote_method = params["vote_method"]
  @ssl = StopSignLog.get_random(@vote_method, @previous_stop_id)
  @vote_text = "The machine hasn't voted on this yet"
  @vote_direction = nil
  if @ssl.voted_as[@vote_method] == true
    @vote_text = VOTE_TYPES[@vote_method]["machine_vote_yes"]
    puts VOTE_TYPES[@vote_method]
    puts VOTE_TYPES[@vote_method]["machine_vote_yes"]
    @vote_direction = true
  elsif @ssl.voted_as[@vote_method] == false
    @vote_text = VOTE_TYPES[@vote_method]["machine_vote_no"]
    puts VOTE_TYPES[@vote_method]
    puts VOTE_TYPES[@vote_method]["machine_vote_no"]
    @vote_direction = false
  end
  erb :"machine"
end