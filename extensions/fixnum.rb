class Fixnum
  def delimited(delimiter=",")
    self.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
  end
end

class Float
  def delimited(delimiter=",")
    self.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
  end
end