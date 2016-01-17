# A module to parse Config Files. 
#
# Usage:
# CONFIG = ConfigParser::Parser.load_config("server.conf", overrides=["ubuntu",:production])
# Throws a SyntaxError (with line number) if parsing barfs. 
# begin 
#  CONFIG = ConfigParser::Parser.load_config("./conf/temp.conf")
# rescue SyntaxError => msg
#  puts "Unable to read file: #{msg}"
#  exit
# end
# 
# Returns an object that queried with configurations keys as method names
# CONFIG.ftp.path => /var/www/html

require 'ostruct'
require 'set'

module ConfigParser 

  # a bunch of regex patterns used for parsing entities in the script
  # assumptions about lexical rules are provided as comments
  PATTERNS = {
    :group   => /\[(\w+)\]/,             # group name: any valid word
    :setting => /([a-zA-Z_><]+) = .*/,   # setting configration: key = <anything>
    :comment => /^;/,                    # any line that starts with a ;
    :number  => /^[0-9]+$/,              # 0-9s
    :float   => /^[0-9]+\.[0-9]+$/,      # 0-9 . 0-9
    :string  => /^"(.*)"$/,                # any set of chars enclosed b/w quotes
    :array   => /,/,                     # has a comma?
    :yes     => ["yes","true","1"].to_set,
    :no      => ["no","false","0"].to_set
  }

  # inheriting the OpenStruct class and overriding the inspect method
  # for hash output. (safer than monkey-patching IMHO)
  class BetterStruct < OpenStruct
    def inspect
      return self.to_h().to_s
    end
  end

  class Parser
    # open up self's singleton so as to provide
    # static methods on the class. This is to done to keep 
    # as close to the expected API as per the spec.
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

      # takes a configuration value and returns the value in correct type
      # eg. parseValue("123") -> 123 etc.
      def parseValue(value)
        if PATTERNS[:no].include? value
          return false
        elsif PATTERNS[:yes].include? value
          return true
        elsif  value =~ PATTERNS[:number]
          return value.to_i
        elsif value =~ PATTERNS[:float]
          return value.to_f
        elsif value =~ PATTERNS[:string]
          match = PATTERNS[:string].match(value)
          return match[1]
        elsif value =~ PATTERNS[:array]
          return value.split(',').map { |x| x.strip }
        else
          return value
        end
      end

      # takes an configuration setting and returns a hash map
      # with key, value and override settings parsed
      def parseSetting(line, number)
        startOverride, startValue, startString = false
        key, value, override = [], [], []

        # behaves as a state-machine that inspects each character
        # and adds it to key, value or override depending on the 
        # state it is currently in
        line.split("").each do |c|
          if c == ";"                         # found a comment       
            if startString                    # if we are inside a string
              value.push(c)                   # add the whitespace
            else                              # else stop parsing
              break
            end
          elsif c == "\""                     # start parsing string
            startString = !startString
            value.push "\""
          elsif c.strip.empty?                # found a whitespace 
            if startString                    # if we are inside a string
              value.push(c)                   # add the whitespace
            else                              # else ignore
              next
            end
          elsif c == "<"                      # start override block
            startOverride = true
          elsif c == ">"
            startOverride = false             # stop override block
          elsif c == "="
            startValue = true                 # start parsing value
          else                                # push char depending on state                 
            if startOverride
              override.push(c)
            elsif startValue
              value.push(c)
            else
              key.push(c)
            end
          end
        end

        # none of these should be empty
        if (key.empty? || value.empty? || startString)
          raise SyntaxError.new(true), "Parse error in line #{number + 1}"
        end

        # obtained the `typed` value from the parseValue function
        value = parseValue(value.join())

        return {
          :type     => :setting,
          :key      => key.join(),
          :value    => value,
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

      # takes a map of (groups -> settings) and overrides 
      # Returns an object of type BetterStruct
      def buildStruct(map, overrides)
        # recursion base case
        if map.has_key? :default
          overrides = ([:default] + overrides).map { |c| c.to_sym }
          value = nil
          overrides.each do |o| # pick the last override
            if !map[o].nil?
              value = map[o]
            end
          end
          return value

        # recursively transform nested hashmaps
        else
          struct = BetterStruct.new(map)
          map.each do |k, v|
            if v.instance_of? Hash
              struct[k] = buildStruct(v, overrides)
            end
          end
          return struct
        end
      end

      # the main method with which the user interacts
      def load_config(file_path, overrides=[])
        rules = parseFile(file_path)
        map = buildMap(rules)
        return buildStruct(map, overrides)
      end

    end
  end
end
