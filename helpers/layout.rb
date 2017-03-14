module LayoutHelper  
  def include_css(*files)
    if files.last.is_a?(Hash)
      options = files.pop
    else
      options = {}
    end
    files.collect{|f| 
      timestamp = File.mtime(File.join(File.dirname(__FILE__), '..', 'public', 'css', f)).to_i
      "<link rel=\"stylesheet\" type=\"text/css\" href=\"/css/#{f}?#{timestamp}\"#{options.keys.empty? ? '' : ' ' + options.each_pair.collect{|k, v| k.to_s+'="'+v+'"'}.join(' ')}>"
    }.join("\n")
  end

  def include_js(*files)
    files.collect{|f|
      timestamp = File.mtime(File.join(File.dirname(__FILE__), '..', 'public', 'js', f)).to_i
      "<script src=\"/js/#{f}?#{timestamp}\"></script>"
    }.join("\n")
  end
  
  def partial(template, *args)
    options = args.extract_options!
    options.merge!(:layout => false)
    if collection = options.delete(:collection) then
      collection.inject([]) do |buffer, member|
        buffer << erb(path_to_partial_path(template), options.merge(
                                  :layout => false, 
                                  :locals => {path_to_partial_path(template) => member}
                                )
                     )
      end.join("\n")
    else
      erb path_to_partial_path(template), options
    end
  end
    
  def path_to_partial_path(path)
    #converts string of /partial/path to /partial/_path symbol
    broken_path = path.split("/")
    partial_file = "_"+broken_path.last
    return (broken_path[0..-2]|[partial_file]).join("/").to_sym
  end

  def strip_quote(str)
    str.to_s.gsub("'","\\\\'")
  end

  def no_lines(str)
    str.to_s.gsub("\n","").gsub("\r","")
  end

  def rb2js(obj)
    translation = obj.to_json.gsub('\\','\\\\\\\\').gsub('"', '\\"').gsub("'","\\\\'")
    "JSON.parse('#{translation}')"
  end

  def format_date(date, format)
    return '' if date.nil?
    tz = ActiveSupport::TimeZone.new("Pacific Time (US & Canada)")
    date = DateTime.parse(date).to_time if date.is_a? String
    date.in_time_zone(tz).strftime(format)
  end

end
