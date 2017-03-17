class RunPredictor

  def can_be_learned(method)
    return Vote.where(vote_method: method).count > 300 && Vote.where(vote_method: method, vote: 0).distinct(:stop_id).count > 100 && Vote.where(vote_method: method, vote: 1).distinct(:stop_id).count > 100
  end

  #eventually this needs memory optimization.
  def export_datasheet(vote_method, time)
    csv = CSV.open("#{CONFIG["project_dir"]}datasheet_#{vote_method}_#{time.to_i}.csv", "w")
    vote_avgs = []
    StopSignLog.fields(:stop_id, :ml_row).each do |ssl|
      if Vote.where(stop_id: ssl.stop_id, vote_method: vote_method).count >= 1
        vote_avg = Vote.where(stop_id: ssl.stop_id, vote_method: vote_method).to_a.collect(&:vote).average
        if vote_avg > 0.5
          vote_avg = 1
        else
          vote_avg = 0
        end
        row = [vote_avg]
        vote_avgs << vote_avg
        ssl.ml_row.collect{|x| row << x}
        csv << row
      end
    end
    csv.close
    return "datasheet_#{vote_method}_#{time.to_i}.csv"
  end
  
  def run
    begin
      time = Time.now
      ["presence", "full_scene", "stop_violations", "wrong_way_violations"].each do |vote_method|
        if can_be_learned(vote_method)
          puts "Updating model of #{vote_method}"
          filename = export_datasheet(vote_method, time)
          ml = MachineLearner.first_or_create(vote_method: vote_method)
          prev_acc = ml.accuracy.to_f
          start_time = Time.now
          results = `python #{CONFIG["project_dir"]}/predictor.py --file #{CONFIG["project_dir"]}datasheet_#{vote_method}_#{time.to_i}.csv --prev_acc #{prev_acc} --vote_method #{vote_method} &`
          ml.accuracy = (results.strip.split(",").first.to_f.round(4)*100)
          ml.conmat = {"tp" => results.strip.split(",")[1].to_i, "tn" => results.strip.split(",")[2].to_i, "fp" => results.strip.split(",")[3].to_i, "fn" => results.strip.split(",")[4].to_i}
          ml.save!
          `rm #{CONFIG["project_dir"]}datasheet_#{vote_method}_#{time.to_i}.csv`
        end
      end
      StopSignLog.bulk_train_ml
    rescue Exception => e
      puts "Weird issue happened: #{e}"
    end
  end
end