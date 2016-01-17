require './lib/configparser.rb'

begin 
  CONFIG = ConfigParser::Parser.load_config("./conf/temp.conf")
rescue SyntaxError => msg
  puts "Unable to read file: #{msg}"
  puts "Change the filename to server.conf to see this in action"
  exit
end

puts CONFIG
