### testing the parser
require './lib/configparser.rb'

CONFIG = ConfigParser::Parser.load_config("./conf/server.conf")

puts CONFIG
