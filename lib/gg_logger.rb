#
# Support for logging in scripts
# recognizes and supports the @verbose and @debug variables
# (see also gg_optparse verbose_switch and debug_switch)
#

def set_logfile(logfilename)
  @gg_logger_file = File.open(logfilename)
end

def close_logfile
  if @gg_logger_file and @gg_logger_file != STDERR
    @gg_logger_file.close
  end
  @gg_logger_file = STDERR
end

def set_logpfx(symbol)
  @gg_logger_pfx = symbol
end

def show_date_in_logs
  @gg_logger_show_date = true
end

def log_with_options(msg, logger_file, logger_pfx, show_date)
  logger_file ||= STDERR
  logger_pfx ||="#"
  date = show_date ? " [#{`date`.chomp}]" : ""
  msg.to_s.split("\n").each do |line|
    logger_file.puts "#{logger_pfx}#{date} #{line}"
  end
end

def log(msg)
  log_with_options(msg, @gg_logger_file, @gg_logger_pfx, @gg_logger_show_date)
end

# verbose log

def vlog(msg)
  log(msg) if @verbose
end

def freemem_str
  "free memory: #{%x(free -h).split(" ")[9]}"
end

def vlog_freemem
  log(freemem_str) if @verbose
end

# debug log

def dlog_setpfx(symbol)
  @gg_logger_dlog_pfx = symbol
end

def dlog_setfile(logfilename)
  @gg_logger_dlog_file = File.open(logfilename)
end

def dlog_show_date
  @gg_logger_dlog_show_date = true
end

def dlog(msg)
  log_with_options(msg,
                   @gg_logger_dlog_file,
                   @gg_logger_dlog_pfx,
                   @gg_logger_dlog_show_date) if @debug
end

def dlog_freemem
  dlog(freemem_str)
end
