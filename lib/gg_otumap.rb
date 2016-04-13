class OtuMap < Hash
  def new(fname)
    f = File.open(fname)
    f.each do |line|
      elems=line.chomp.split("\t")
      self[elems[0].to_sym] = elems[1..-1]
    end
    f.close
    self
  end
  def self.scan(fname, otuname)
    f = File.open(fname)
    retval = []
    f.each do |line|
      elems=line.chomp.split("\t")
      if elems[0] == otuname.to_s
        retval = elems[1..-1]
        break
      end
    end
    f.close
    retval
  end
end
