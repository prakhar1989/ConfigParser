require "test/unit"
require File.expand_path(File.dirname(__FILE__) + "/../lib/configparser")

class TestConfigParser < Test::Unit::TestCase
  def test_generate_rule()
    assert_equal({:type=>:group, :value=>"http"},
                  ConfigParser::Parser.generateRule("[http]", 1))
    assert_equal({:type=>:group, :value=>"AlPhA"},
                  ConfigParser::Parser.generateRule("[AlPhA]", 1))
  end

  def test_generate_rule_should_raise_exception()
    exception = assert_raise(SyntaxError) do
      ConfigParser::Parser.generateRule("[name-with-dash]", 10)
    end
    assert_equal(exception.message, "Parse error in line 11")
    exception = assert_raise(SyntaxError) do
      ConfigParser::Parser.generateRule("some random line", 1)
    end
    assert_equal(exception.message, "Parse error in line 2")
  end

  def test_parse_value() 
    assert_equal(ConfigParser::Parser.parseValue("123"), 123)
    assert_equal(ConfigParser::Parser.parseValue("1.23"), 1.23)
    assert_equal(ConfigParser::Parser.parseValue("yes"), true)
    assert_equal(ConfigParser::Parser.parseValue("1"), true)
    assert_equal(ConfigParser::Parser.parseValue("0"), false)
    assert_equal(ConfigParser::Parser.parseValue("no"), false)
    assert_equal(ConfigParser::Parser.parseValue("val1,val2"), ["val1", "val2"])
    assert_equal(ConfigParser::Parser.parseValue("\"hello world\""), "\"hello world\"")
    assert_equal(ConfigParser::Parser.parseValue("\"hello,world\""), "\"hello,world\"")
    assert_equal(ConfigParser::Parser.parseValue("some_value"), "some_value")
  end
end
