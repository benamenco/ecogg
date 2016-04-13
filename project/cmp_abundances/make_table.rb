#!/usr/bin/env ruby
require "yaml"
unless File.exists?("out.yml")
  `./classify.rb genera.ouronly.dat -o -s > out.yml`
  `./classify.rb rbotus.ouronly.dat -o -s | tail -n +2 >> out.yml`
  `./classify.rb dnotus.ouronly.dat -o -s | tail -n +2 >> out.yml`
end

data = YAML.load_file("out.yml")
def putsline(line)
  line = line.map do|x|
    if x.kind_of?(Float)
      x = ("%.1f" % (x*100))
      if x == "0.0"
        x = "< 0.1"
      end
    end
    x
  end
  puts line.join("\t")
end
label = {
  :xGGy => "v/o > 10",
  :xGy => "1 < v/o <= 10",
  :yGx => "0.1 <= v/o <= 1",
  :yGGx => "v/o < 0.1",
}
# to be exact one should also count xEy but it's always 0

putsline(["", "Vent counts", "", "", "Open Ocean counts", "", ""])
putsline(["","Genera","rbOTUs","dnOTUs", "Genera", "rbOTUs", "dnOTUs"])

[:xGGy, :xGy, :yGx, :yGGx].each do |bin|
  line = [label[bin]]
  [:xsums, :ysums].each do |environ|
    ["genera.ouronly.dat","rbotus.ouronly.dat","dnotus.ouronly.dat"].each do |level|
      line << data[level][environ][bin]
    end
  end
  putsline(line)
end

