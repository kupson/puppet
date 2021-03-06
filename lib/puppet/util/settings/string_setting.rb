# The base element type.
class Puppet::Util::Settings::StringSetting
  attr_accessor :name, :section, :default, :call_on_define
  attr_reader :desc, :short

  def desc=(value)
    @desc = value.gsub(/^\s*/, '')
  end
  
  #added as a proper method, only to generate a deprecation warning
  #and return value from 
  def setbycli
    Puppet.deprecation_warning "Puppet.settings.setting(#{name}).setbycli is deprecated. Use Puppet.settings.set_by_cli?(#{name}) instead."
    @settings.set_by_cli?(name)
  end
  
  def setbycli=(value)
    Puppet.deprecation_warning "Puppet.settings.setting(#{name}).setbycli= is deprecated. You should not manually set that values were specified on the command line."
    @settings.set_value(name, @settings[name], :cli) if value
    raise ArgumentError, "Cannot unset setbycli" unless value
  end

  # get the arguments in getopt format
  def getopt_args
    if short
      [["--#{name}", "-#{short}", GetoptLong::REQUIRED_ARGUMENT]]
    else
      [["--#{name}", GetoptLong::REQUIRED_ARGUMENT]]
    end
  end

  # get the arguments in OptionParser format
  def optparse_args
    if short
      ["--#{name}", "-#{short}", desc, :REQUIRED]
    else
      ["--#{name}", desc, :REQUIRED]
    end
  end

  def hook=(block)
    meta_def :handle, &block
  end

  # Create the new element.  Pretty much just sets the name.
  def initialize(args = {})
    unless @settings = args.delete(:settings)
      raise ArgumentError.new("You must refer to a settings object")
    end

    args.each do |param, value|
      method = param.to_s + "="
      raise ArgumentError, "#{self.class} (setting '#{args[:name]}') does not accept #{param}" unless self.respond_to? method

      self.send(method, value)
    end

    raise ArgumentError, "You must provide a description for the #{self.name} config option" unless self.desc
  end

  def iscreated
    @iscreated = true
  end

  def iscreated?
    @iscreated
  end

  def set?
    !!(!@value.nil?)
  end

  # short name for the celement
  def short=(value)
    raise ArgumentError, "Short names can only be one character." if value.to_s.length != 1
    @short = value.to_s
  end
  
  def default(check_application_defaults_first = false)
    return @default unless check_application_defaults_first
    return @settings.value(name, :application_defaults, true) || @default
  end

  # Convert the object to a config statement.
  def to_config
    str = @desc.gsub(/^/, "# ") + "\n"

    # Add in a statement about the default.
    str += "# The default value is '#{default(true)}'.\n" if default(true)

    # If the value has not been overridden, then print it out commented
    # and unconverted, so it's clear that that's the default and how it
    # works.
    value = @settings.value(self.name)

    if value != @default
      line = "#{@name} = #{value}"
    else
      line = "# #{@name} = #{@default}"
    end

    str += line + "\n"

    str.gsub(/^/, "    ")
  end

  # Retrieves the value, or if it's not set, retrieves the default.
  def value
    @settings.value(self.name)
  end
end

