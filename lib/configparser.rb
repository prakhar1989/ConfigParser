require 'ostruct'

module ConfigParser 

  # a bunch of regex patterns for parsing entities
  # assumptions about lexical rules are provided as comments
  PATTERNS = {
    :group   => /\[(\w+)\]/,             # group name: any valid word
    :setting => /([a-zA-Z_><]+) = .*/,   # setting configration: key = <anything>
    :comment => /^;/,                    # any line that starts with a ;
    :number  => /^[0-9]+$/,              # 0-9s
    :float   => /^[0-9]+\.[0-9]+$/,      # 0-9 . 0-9
    :string  => /^".*"$/,                # any set of chars enclosed b/w quotes
    :array   => /,/                      # has a comma?
  }

  class BetterStruct < OpenStruct
    def inspect
      return self.to_h().to_s
    end
  end

  class Parser

    class << self

      # takes a line and returns a rule of the form 
      # {:type => :group, :value => group_name }
      # raises exception otherwise
      def parseGroup(line, number)
        match = PATTERNS[:group].match(line)
        if match
          return {:type => :group, :value => match[1] }
        else
          raise SyntaxError.new(true), "Parse error in line #{number + 1}"
        end
      end

      # takes a configration value and returns the value in correct type
      # eg. parseValue("123") -> 123 etc.
      def parseValue(value)
        if ["no", "false", "0"].include? value
          return false
        elsif ["yes", "true", "1"].include? value
          return true
        elsif  value =~ PATTERNS[:number]
          return value.to_i
        elsif value =~ PATTERNS[:float]
          return value.to_f
        elsif value =~ PATTERNS[:string]
          return value
        elsif value =~ PATTERNS[:array]
          return value.split(',').map { |x| x.strip }
        else
          return value
        end
      end

      def parseSetting(line, number)
        startOverride, startValue, startString = false
        key = []
        value = []
        override = []
        line.split("").each do |c|
          if c == ";"
            break
          elsif c == "\""
            startString = !startString
            value.push "\""
          elsif c.strip.length == 0  # whitespace
            if startString 
              value.push c
            else
              next
            end
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

        value = parseValue(value.join())

        return {
          :type => :setting, 
          :key => key.join(), 
          :value => value,
          :override => override.join() 
        }
      end

      # generates a rule for a line, takes an additional line number 
      # to generate better exceptions
      def generateRule(line, number)
        if line =~ PATTERNS[:group]
          return parseGroup(line, number)
        elsif line =~ PATTERNS[:setting]
          return parseSetting(line, number)
        elsif line =~ PATTERNS[:comment]
          return nil
        else
          raise SyntaxError.new(true), "Parse error in line #{number + 1}"
        end
      end

      # reads in file and generates rules 
      def parseFile(filename)
        rules = []
        File.open(filename, "r") do |f|
          f.each_line.with_index do |line, idx|
            line = line.chomp
            if !line.empty?
              rule = generateRule(line, idx)
              if !rule.nil?
                rules.push(rule)
              end
            end
          end
        end
        return rules
      end

      # takes a set of rules and returns a hashmap
      # where headers are keys and settings are values
      def buildMap(rules)
        map = {}
        group = nil
        rules.each do |rule|
          if rule[:type] == :group
            map[rule[:value]] = {}
            group = rule[:value]
          elsif rule[:type] == :setting
            if rule[:override].empty?
              map[group][rule[:key]] = { :default => rule[:value] }
            else
              map[group][rule[:key]][rule[:override].to_sym] = rule[:value] 
            end
          end
        end
        return map
      end

      def buildStruct(map, overrides)
        # reached the bottom of the recursion
        if map.has_key? :default
          overrides = ([:default] + overrides).map { |c| c.to_sym }
          value = nil
          overrides.each do |o|
            if !map[o].nil?
              value = map[o]
            end
          end
          return value
        # recursively transform nested hashmaps
        else
          struct = BetterStruct.new(map)
          map.each do |k, v|
            if v.instance_of?(Hash)
              struct[k] = buildStruct(v, overrides)
            end
          end
          return struct
        end
      end

      def load_config(file_path, overrides=[])
        rules = parseFile(file_path)
        map = buildMap(rules)
        return buildStruct(map, overrides)
      end

    end

  end

end
