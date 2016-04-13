# %-PURPOSE-%
# Functions which output errors, warning or exit a program

def raise!(msg,*data)
  raise msg_with_data(msg,*data)
end

def fatal!(msg,*data)
  err!(msg,*data)
  exit 1
end

def err(msg,*data)
  STDERR.puts msg_with_data("Error: " + msg,*data)
end

def warn(msg,*data)
  STDERR.puts msg_with_data("Warning: "+ msg,*data)
end

def msg_with_data(msg,*data)
  out = [msg]
  label = nil
  data.each do |content|
    if label.nil?
      label = content
    else
      out << "#{label}: #{content}"
      label = nil
    end
  end
  return out.join("\n")
end
