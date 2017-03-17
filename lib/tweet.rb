class Tweet
  def self.client
    Twitter::REST::Client.new do |config|
      config.consumer_key        = CONFIG["consumer_key"]
      config.consumer_secret     = CONFIG["consumer_secret"]
      config.access_token        = CONFIG["access_token"]
      config.access_token_secret = CONFIG["access_token_secret"]
    end
  end

  def self.tweet(imgur_url)
    `wget #{imgur_url}v`
    begin
      client.update_with_media(self.text.shuffle.first+" "+self.hashtags.shuffle.first, File.new(imgur_url.split("/").last+"v"))
    rescue
      client.update_with_media(self.text.shuffle.first+" "+self.hashtags.shuffle.first+" (#{imgur_url})")
    end
    `rm #{imgur_url.split("/").last}v`
  end

  def self.hashtags
    ["#YOLO", "#NobodyLovesMe", "#Whoops", "#Stahp"]
  end
  
  def self.text
    ["I think I saw another just now", "That poor stop sign...", "Another one!"]
  end
end