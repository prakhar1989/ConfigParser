require 'ostruct'

module ConfigParser 

  PATTERNS = {
    :group => /\[\w+\]/,
    :setting => /([a-zA-Z_><]+) = .*/,
    :comment => /^;/
  }

  class BetterStruct < OpenStruct
    def inspect
      return self.to_h().to_s
    end
  end

  class Parser

    class << self

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
          return parseGroup(line)
        elsif ( line =~ PATTERNS[:setting] )
          return parseSetting(line)
        elsif (line =~ PATTERNS[:comment] )
          return nil
        else
          raise SyntaxError.new(true), "parse error"
        end
      end

      def parseFile filename
        rules = []
        File.open(filename, "r") do |f|
          f.each_line do |line|
            line = line.chomp
            if line.length > 0 
              rule = lineType line
              if !rule.nil?
                rules.push rule
              end
            end
          end
        end
        return rules
      end

      def buildMap rules
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

      def isHash v
        return v.instance_of?(Hash)
      end

      def buildStruct(map, overrides)
        if map.has_key? :default # reached the bottom of the rec
          overrides = ([:default] + overrides).map { |c| c.to_sym }
          value = nil
          overrides.each do |o|
            if !map[o].nil?
              value = map[o]
            end
          end
          return value
        else
          struct = BetterStruct.new(map)
          map.each do |k, v|
            if isHash(v)
              struct[k] = buildStruct(v, overrides)
            end
          end
          return struct
        end
      end

      def load_config(file_path, overrides=[])
        rules = parseFile file_path
        map = buildMap rules
        return buildStruct(map, overrides)
      end

    end

  end

end
