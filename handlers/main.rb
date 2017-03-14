get "/" do
  @total_time = ObservationPeriod.fields(:interevent_time).collect(&:interevent_time).sum
  erb :"index"
end

get "/train/presence" do
  @ssl = StopSignLog.where(:human_votes_car_present => [], gif_saved: true).first || StopSignLog.get_random
  @vote_type = "Car Presence"
  @vote_method = "presence"
  @vote_negative = "No Car"
  @vote_affirmative = "Yes Car"
  @vote_text = "Is there a moving car in this GIF? Press J if there isn't, K if there is (or just click the links below)"
  erb :"vote"
end

get "/train/stop_violations" do
  @ssl = StopSignLog.where(:human_votes_car_stop_violated => [], gif_saved: true).first || StopSignLog.get_random
  @vote_type = "Car Stop Violation"
  @vote_method = "stop_violations"
  @vote_negative = "No Stop"
  @vote_affirmative = "Yes Stop"
  @vote_text = "Is a car present in this GIF *and* is it blowing the stop sign? Press J if there isn't, K if there is (or just click the links below)"
  erb :"vote"
end

get "/train/wrong_way_violations" do
  @ssl = StopSignLog.where(:human_votes_car_wrong_way_violated => [], gif_saved: true).first || StopSignLog.get_random
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
    if params[:vote_method] == "presence"
      @ssl.human_votes_car_present ||= []
      @ssl.human_votes_car_present << 1
    elsif params[:vote_method] == "stop_violations"
      @ssl.human_votes_car_stop_violated ||= []
      @ssl.human_votes_car_stop_violated << 1
    elsif params[:vote_method] == "wrong_way_violations"
      @ssl.human_votes_car_wrong_way_violated ||= []
      @ssl.human_votes_car_wrong_way_violated << 1
    end
  elsif params[:vote_result] == "negative"
    if params[:vote_method] == "presence"
      @ssl.human_votes_car_present ||= []
      @ssl.human_votes_car_present << 0
    elsif params[:vote_method] == "stop_violations"
      @ssl.human_votes_car_stop_violated ||= []
      @ssl.human_votes_car_stop_violated << 0
    elsif params[:vote_method] == "wrong_way_violations"
      @ssl.human_votes_car_wrong_way_violated ||= []
      @ssl.human_votes_car_wrong_way_violated << 0
    end
  end
  @ssl.save!
  redirect "/train/#{params[:vote_method]}"
end