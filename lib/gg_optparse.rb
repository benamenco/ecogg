require 'optparse'

#
# %-PURPOSE-%
# Giorgio's compact option parser based on optparse
#

#
# # An example:
#
# purpose "Count chars in DNA sequences"
# note    "The input file shall be in Fasta format."
# version "1.0"
# positional :fasta, :type => :infile
# verbose_switch
# switch :count_n, :help => "count ambiguities?"
# optparse!
#
# @fasta.each do |line|
#   if @count_n ...
# ...

#
# Advantages: compact and easy to use, extra-functionality
# Disadvantages: pollutes main namespace
#
# The values of the options are saved in class variables
# e.g. option :hallo --> @hallo. This can be also seen as
# advantage or not.
#

#
# Example Usage:
#
# # SCRIPT DOCUMENTATION #
#
# purpose "Test gg_optparse"
# purpose "another purpose line"
# purpose "purpose is not mandatory, but it's nice to have one"
#
# note "this is a note"
# note "and this is the second note line"
# note "of course notes are not mandatory"
#
# usage "Usage is computed automatically if not specified"
# usage "this would be a second usage line, if any specified"
#
# version 1.0 # this enables the switch -V/--version
#
# # POSITIONAL ARGUMENTS #
# positional :filename1
# optional_positional :filename3
# allothers :filenames # catch-all, alternative to optional_positional
# allothers :filenames, :required => true # requires at least one
#
# # SWITCHES/OPTIONS #
#
# # Boolean:
# switch :unsafe # default: false
#
# # String:
# option :inputfilename # => String, as no default is specified
# option :outputfilename, "my.txt" # => default value
#
# # Symbol:
# option :mysymbol, :default
#
# # Numeric:
# option :error, 1.0 # => Float with default
# option :number, Float # => Float without default
#
# # Option with optional option argument
# option :x, :optarg => true
#
# # List: (comma-separated)
# option :list, [1,2,3] # => list (array of strings)
# option :list2, [] # => list, default empty
# option :anotherlist, Array #=> list without default
#
# # SPECIAL SWITCHES #
# verbose_switch # create a -v --verbose switch (see also gg_logger)
# debug_switch # create a -D --debug switch (see also gg_logger)
# force_switch # create a -f --force switch (see :outfile below)
# # the -h, --help switch is automatically created
# # the -V, --version switch if version is used, see above
#
# # HELP TEXT FOR OPTIONS #
#
# switch :switch1, :help => "Be nice"
# # multiline:
# switch :switch2, :help => ["Be very nice","much nicer than -switch1"]
# # to hide the default value:
# switch :switch3, :help => "Be careful (default: be bold)", :defstr => false
#
# # MANUALLY SELECT SHORT OPTION #
#
# option :filename, :short => "i"
#
# # AUTOMATIC TYPE CHECKS AND CASTING #
# (not available for boolean switches and allothers array)
# option :number1, :type => :integer # automatically cast to Integer
# positional :number2, :type => :natural # Integer >= 0
# positional :number3, :type => :positive # Integer > 0
# option :number4, :type => :percent # Float 0.0 <= f <= 100.0
# positional :number5, :type => :portion # Float 0.0 <= f <= 1.0
# positional :number6, :type => :float # automatically cast to Float
# # other: percent_float, positive_float
# positional :string, :type => :list, :allowed => ["a", "b", "c"]
#
# # AUTOMATIC FILE OPENING #
# # @<optname> is the file
# # the original value is still available as @_<optname>
# # input file:
# option :filename1, :type => :infile
# # use custom File class replacement:
# # File class must support FileClass.new(filename)
# option :filename2, :type => :infile, :fileclass => FastaFile
# # output file: (respects --force switch)
# optional_positional :filename3, :type => :outfile
# # output files based on input filename:
# option :filename4, :type => :infile,
#   :outfiles => [:out1 => ".1", :out2 => ".2"]
# # @out1 and @out2 are output files,
# # with filename = @_<filename4>.1 and @_<filename4>.2
#
# # PARSE #
# optparse!
# # parsing results are saved in the class variable @<optname>
#

def switch(optname, options={})
  option optname, options[:default], :bool, options
end

def option(optname, default=nil, klass=nil, options={})
  @arguments ||= []
  if default.kind_of?(Hash)
    options=default
    default=nil
    klass=nil
  else
    if default.kind_of?(Class)
      options = klass
      klass = default
      default = nil
    end
    if klass.kind_of?(Hash)
      options = klass
      klass = nil
    end
  end
  optname = optname.to_s
  _check_optname(optname)
  klass ||= default.nil? ? String : default.class
  klass = Integer if klass == Fixnum
  options ||= {}
  options[:optname] = optname
  options[:default] = default
  options[:klass] = klass
  @arguments << options
end

def purpose(string)
  if @purpose
    @purpose+="\n"+string
  else
    @purpose=string
  end
end

def usage(string)
  if @usage
    usage_indent=" "*"Usage: ".size
    @usage+="\n#{usage_indent}#{string}"
  else
    @usage=string
  end
end

def version(string)
  @version=string
end

def note(string)
  if @notes
    @notes+="\n"+string
  else
    @notes=string
  end
end

def positional(optname, options={})
  optname = optname.to_s
  _check_optname(optname)
  options[:optname]=optname
  @positionals << options
end

def optional_positional(optname, options={})
  raise "allothers incompatible with optional_positional" if @allothers
  optname = optname.to_s
  _check_optname(optname)
  options[:optname]=optname
  options[:optional]=true
  @optional_positionals << options
end

def allothers(optname, options={})
  raise "allothers can be used only once" if @allothers
  if @optional_positionals and !@optional_positionals.empty?
    raise "allothers incompatible with optional_positional"
  end
  optname = optname.to_s
  _check_optname(optname)
  options[:optname]=optname
  @allothers_first_required = options[:required]
  @optional_positionals = [options]
  @allothers = true
end

def verbose_switch
  switch :verbose, :short => "v",
    :help => "Be verbose (default: false)",
    :tail => true,
    :defstr => false
end

def debug_switch
  switch :debug, :short => "D", :tail => true,
    :help => "Debug mode (default: false)",
    :defstr => false
end

def force_switch
  switch :force, :short => "f", :help => "Overwrite output file(s)"
end

def require_infile(filename)
  optparse_die "File #{filename} does not exist" unless File.exists?(filename)
end

def require_outfile(filename)
  unless !File.exists?(filename) or @force
    optparse_die "File #{filename} already exists"
  end
end

def optparse_die(msg = nil)
  STDERR.puts "Error: #{msg}\n\n" if msg
  STDERR.puts @optparse
  exit 1
end

def optparse!
  @arguments ||= []
  @positionals ||= []
  @optional_positionals ||= []
  options = {}
  _assign_shorts!
  @optparse = OptionParser.new do |opts|
    opts.program_name = $0
    opts.separator ""
    _add_positionals_to_option_parser(opts)
    _add_options_to_option_parser(options, opts)
  end
  _add_usage_line
  _add_additional_texts
  begin
    @optparse.parse!
  rescue => err
    optparse_die err
  end
  @arguments.each do |a|
    instance_variable_set("@#{a[:optname]}", options[a[:optname].to_sym])
  end
  _enforce_type!(@arguments)
  _enforce_min_max_npositionals!
  @positionals.each do |positional|
    instance_variable_set("@#{positional[:optname]}", ARGV.shift)
  end
  _enforce_type!(@positionals)
  if !ARGV.empty?
    if @allothers
      instance_variable_set("@#{@optional_positionals[0][:optname]}", ARGV)
    else
      @optional_positionals.each do |positional|
        instance_variable_set("@#{positional[:optname]}", ARGV.shift)
        break if ARGV.empty?
      end
      _enforce_type!(@optional_positionals)
    end
  end
end

def _add_positionals_to_option_parser(opts)
  first_positional = true
  first_optional_handled = false
  if (@positionals + @optional_positionals).any?{|x|x[:help]}
    (@positionals + @optional_positionals).each do |positional|
      if first_positional
        if !@positionals.empty?
          if @optional_positionals.empty?
            opts.separator "Positional arguments:"
          else
            opts.separator "Mandatory positional arguments:"
          end
        end
        first_positional = false
      end
      if !first_optional_handled and positional[:optional]
        opts.separator "" unless @positionals.empty?
        opts.separator "Optional positional arguments:"
        first_optional_handled = true
      end
      help = *positional[:help]
      opts.separator opts.summary_indent+
        positional[:optname]+
        (" "*(33-positional[:optname].size))+
        help[0].to_s
      if help.size > 1
        help[1..-1].each do |helpline|
          opts.separator opts.summary_indent+" "*33+helpline
        end
      end
    end
    opts.separator ""
  end
end

def _compute_option_long(a)
  long="--#{a[:optname]}"
  if a[:klass] != :bool
    if a[:optarg]
      long+=" [#{a[:optname][0].upcase}]"
    else
      long+=" #{a[:optname][0].upcase}"
    end
  end
  if a[:klass] == Array
    if a[:optarg]
      long=long[0..-2]
      long+=",#{a[:optname][1].upcase}]"
    else
      long+=",#{a[:optname][1].upcase}"
    end
  end
  return long
end

def _compute_option_defstr(a)
  if a[:klass] == :bool
    defstr="(default: #{a[:default] ? "true" : "false"})"
  else
    defstr="(default: #{a[:default]})"
  end
  if a[:klass] == Array
    if a[:default] and !a[:default].empty?
      defstr="(comma-separated list, default: #{a[:default].join(",")})"
    else
      defstr="(comma-separated list, default: none)"
    end
  end
  if defstr =~ /(.*default:) \)/
    defstr="#$1 none)"
  end
  return defstr
end

def _compute_option_help(a)
  if a[:help]
    if a[:help].kind_of?(Array)
      help = a[:help]
    else
      help = [a[:help].to_s]
    end
  else
    help=["#{a[:optname][0].upcase+a[:optname][1..-1]}"+
          "#{a[:klass] == :bool ? "?" : ""}"]
  end
  unless a[:defstr] == false
    help.last << " " unless help.last.empty?
    help.last << _compute_option_defstr(a)
  end
  return help
end

def _add_options_to_option_parser(options, opts)
  first_option = true
  @arguments.each do |a|
    if first_option
      opts.separator "Options:"
      first_option = false
    end
    short="-#{a[:short]}"
    long = _compute_option_long(a)
    help = _compute_option_help(a)
    unless a[:optarg]
      options[a[:optname].to_sym] = a[:default]
    end
    if a[:klass] == :bool
      opts.send(a[:tail] ? :on_tail : :on,short,long,*help) do
        options[a[:optname].to_sym] = !a[:default]
      end
    elsif a[:klass] == Symbol
      opts.on(short,long,String,*help) do |value|
        if a[:optarg] and value.nil?
          value = a[:default].to_sym
        end
        options[a[:optname].to_sym] = value.to_sym
      end
    else
      opts.on(short,long,a[:klass],*help) do |value|
        if a[:optarg] and value.nil?
          value = a[:default]
        end
        options[a[:optname].to_sym] = value
      end
    end
  end
  opts.on_tail("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
  if defined?(@version)
    opts.on_tail("-V", "--version", "Show version") do
      puts @version
      exit
    end
  end
end

def _add_usage_line
  if @usage
    @optparse.banner = "Usage: " + @usage
  else
    if !@positionals.empty?
      @positionals.each do |positional|
        @optparse.banner += " <#{positional[:optname]}>"
      end
    end
    if !@optional_positionals.empty?
      if @allothers and @allothers_first_required
        optname = @optional_positionals[0][:optname]
        @optparse.banner += " <#{optname}(1st)> [#{optname}(+)]"
      else
        @optional_positionals.each do |positional|
          @optparse.banner += " [<#{positional[:optname]}>]"
        end
      end
    end
  end
end

def _add_additional_texts
  if @purpose
    @optparse.banner = @purpose+"\n\n"+@optparse.banner
  end
  if @notes
    @notes = @notes.split("\n").map{|x|@optparse.summary_indent+x}.join("\n")
    @optparse.banner += "\n\nNotes:\n"+@notes+"\n"
  end
end

def _enforce_min_max_npositionals!
  min_size = @positionals.size
  if @allothers and not @allothers_first_required
    max_size = ARGV.size
  else
    max_size = min_size + @optional_positionals.size
  end
  if ARGV.size < min_size or ARGV.size > max_size
    optparse_die ARGV.size == 0 ? nil : "Wrong number of positional arguments"
  end
end

def _enforce_filename_type(a, before, outfiles)
  if a[:type] == :infile or a[:type] == :infilename
    if !File.exists?(before)
      raise "#{before}: file not found"
    end
    if a[:outfiles]
      a[:outfiles].each_pair do |varname, suffix|
        instance_variable_set("@#{varname}", before + suffix)
        outfiles << {:optname => varname.to_s,
                     :type => :outfile}
      end
    end
    a[:fileclass] ||= File
    after = a[:type] == :infile ? a[:fileclass].open(before) : before
  else
    if defined?(@force) and !@force and File.exists?(before)
      raise "#{before} already exists, use -f to overwrite"
    end
    after = a[:type] == :outfile ? File.open(before, "w") : before
  end
  return after
end

def _enforce_numeric_type(a, before)
  is_float =
    ["float", "positive_float", "percent", "portion"].include?(a[:type])
  err = "<#{a[:optname]}> shall be "
  err += case a[:type]
         when :float   then "a float"
         when :positive_float  then "a positive float"
         when :percent then "a float between 0 and 100"
         when :portion then "a float between 0 and 1"
         when :integer  then "an integer"
         when :positive then "a positive integer"
         when :natural  then "a non-negative integer"
         end
  begin
    after = is_float ? Float(before) : Integer(before)
  rescue
    raise err
  end
  raise err if a[:type] == :positive_float and (after <= 0)
  raise err if a[:type] == :percent and (after < 0 or after > 100)
  raise err if a[:type] == :portion and (after < 0 or after > 1)
  raise err if a[:type] == :positive and after <= 0
  raise err if a[:type] == :natural and after < 0
  return after
end

def _enforce_list_type(a, before)
  raise "Programming error, :allowed required for #{a[:optname]}" \
    unless a[:allowed]
  a[:allowed] = [a[:allowed]] unless a[:allowed].respond_to?(:include?)
  err = "<#{a[:optname]}> shall be one of: "
  err += a[:allowed].join(", ")
  raise err unless a[:allowed].include?(before)
  return before
end

def _enforce_type!(arguments)
  begin
    outfiles = []
    arguments.each do |a|
      next unless a[:type]
      before=instance_variable_get("@#{a[:optname]}")
      next unless before
      if [:infile, :outfile, :infilename, :outfilename].include?(a[:type])
        after = _enforce_filename_type(a, before, outfiles)
      elsif [:integer, :positive, :natural, :float, :percent, :portion,
             :positive_float].include?(a[:type])
        after = _enforce_numeric_type(a, before)
      elsif a[:type] == :list
        after = _enforce_list_type(a, before)
      else
        STDERR.puts "Warning: type #{a[:type]} ignored (option #{a[:optname]})"
        after = before
      end
      instance_variable_set("@#{a[:optname]}", after)
      instance_variable_set("@_#{a[:optname]}", before)
    end
    if !outfiles.empty?
      _enforce_type!(outfiles)
    end
  rescue => err
    optparse_die err
  end
end

def _check_optname(optname)
  @arguments ||= []
  @positionals ||= []
  @optional_positionals ||= []
  raise "optname must be downcase (#{optname})" if optname != optname.downcase
  raise "optname must be multiletter (#{optname})" if optname.size == 1
  if (@positionals + @optional_positionals + @arguments).map{|x|x[:optname]}.
      include?(optname)
    raise "optname must be unique (#{optname})"
  end
  begin
    Object.new.instance_variable_set ("@"+optname).intern, nil
  rescue NameError
    raise "@<optname> must be a valid variable name (#{optname})"
  end
end

def _assign_default_shorts(arguments, used_shorts)
  used_shorts << ["h", "V"] # help and version
  # note: verbose, debug and force are added as user_defined
  return used_shorts
end

def _assign_user_defined_shorts(arguments, used_shorts)
  arguments.each do |a|
    if !a[:short].nil?
      if used_shorts.include?(a[:short])
        raise ":short => #{a[:short]} may be used only once"
      end
      used_shorts << a[:short]
    end
  end
  return used_shorts
end

def _assign_first_letter_shorts(arguments, used_shorts)
  arguments.each do |a|
    next if a[:short]
    short = a[:optname][0]
    if !used_shorts.include?(short)
      used_shorts << short
      a[:short] = short
    end
  end
  return used_shorts
end

def _assign_further_letters_shorts(arguments, used_shorts)
  arguments.each do |a|
    next if a[:short]
    a[:optname][1..-1].chars do |char|
      short = char
      if !used_shorts.include?(short)
        used_shorts << short
        a[:short] = short
        break
      end
    end
  end
  return used_shorts
end

def _assign_next_alphabet_letter_of_first_letter_shorts(arguments, used_shorts)
  arguments.each do |a|
    short = a[:optname][0]
    while !a[:short] and short.size == 1
      short = short.next
      if !used_shorts.include?(short)
        used_shorts << short
        a[:short] = short
      end
    end
  end
  return used_shorts
end

def _assign_remaining_available_letters_shorts(arguments, used_shorts)
  arguments.each do |a|
    short = "A"
    while !a[:short] and short.size == 1
      short = short.next
      if !used_shorts.include?(short)
        used_shorts << short
        a[:short] = short
      end
    end
  end
  return used_shorts
end

def _check_all_shorts_assigned(arguments)
  arguments.each do |a|
    if a[:short].nil?
      raise "No viable short name found for option #{a[:optname]}"
    end
  end
end

def _assign_shorts!
  used_shorts = _assign_default_shorts(@arguments, [])
  used_shorts = _assign_user_defined_shorts(@arguments, used_shorts)
  used_shorts = _assign_first_letter_shorts(@arguments, used_shorts)
  used_shorts = _assign_further_letters_shorts(@arguments, used_shorts)
  used_shorts = _assign_next_alphabet_letter_of_first_letter_shorts(@arguments,
                                                                    used_shorts)
  used_shorts = _assign_remaining_available_letters_shorts(@arguments,
                                                            used_shorts)
  _check_all_shorts_assigned(@arguments)
end

