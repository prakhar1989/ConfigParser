PATTERNS = {
  :group => /\[\w+\]/,
  :setting => /([a-zA-Z_><]+) = .*/,
  :comment => /^;/
}

def parseGroup line
  match = /\[(\w+)\]/.match(line)
  if match
    return {:type => :group, :value => match[1] }
  else
    raise SyntaxError.new(true), "error reading group"
  end
end

def parseValue value
  if value == "no" or value == "false" or value == "0"
    return false
  elsif value == "yes" or value == "true" or value == "1"
    return true
  elsif  value =~ /^[0-9]+$/
    return value.to_i
  elsif value =~ /^[0-9]+\.[0-9]+$/
    return value.to_f
  elsif value =~ /^".*"$/
    return value
  elsif value =~ /,/
    return value.split(',').map { |x| x.strip }
  else
    return value
  end
end

def parseSetting line
  startOverride, startValue = false
  key = []
  value = []
  override = []
  line.split("").each do |c|
    if c == ";"
      break
    elsif c.strip.length == 0  # whitespace
      next
    elsif c == "<"
      startOverride = true
    elsif c == ">"
      startOverride = false
    elsif c == "="
      startValue = true
    else
      if startOverride 
        override.push c
      elsif startValue
        value.push c
      else
        key.push c
      end
    end
  end

  value = parseValue value.join()

  return {
    :type => :setting, 
    :key => key.join(), 
    :value => value,
    :override => override.join() 
  }
end

 
def lineType line
  if ( line =~ PATTERNS[:group])
    puts parseGroup(line)
  elsif ( line =~ PATTERNS[:setting] )
    puts parseSetting(line)
  elsif (line =~ PATTERNS[:comment] )
    return nil
  else
    raise SyntaxError.new(true), "parse error"
  end
end


def parseFile filename
  File.open(filename, "r") do |f|
    f.each_line do |line|
      line = line.chomp
      if line.length > 0 
        lineType line
      end
    end
  end
end


parseFile "server.conf"
#puts parseSetting "path<staging> = /srv/uploads/; This is another comment"
