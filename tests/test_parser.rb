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
    assert_equal(ConfigParser::Parser.parseValue("\"hello world\""), "hello world")
    assert_equal(ConfigParser::Parser.parseValue("\"hello,world\""), "hello,world")
    assert_equal(ConfigParser::Parser.parseValue("some_value"), "some_value")
  end

  def test_parseSetting()
    assert_equal(ConfigParser::Parser.parseSetting("name = alice", 1),
                 {:type => :setting, :key => "name", 
                  :value => "alice", :override => ""})

    # no whitespace test
    assert_equal(ConfigParser::Parser.parseSetting("name=alice", 1),
                 {:type => :setting, :key => "name", 
                  :value => "alice", :override => ""})

    # extra white space test
    assert_equal(ConfigParser::Parser.parseSetting("name     =  alice", 1),
                 {:type => :setting, :key => "name", 
                  :value => "alice", :override => ""})

    # test comment
    assert_equal(ConfigParser::Parser.parseSetting("name = alice; hello", 1),
                 {:type => :setting, :key => "name", 
                  :value => "alice", :override => ""})

    # test string
    assert_equal(ConfigParser::Parser.parseSetting("msg = \"hey hi\"", 1),
                 {:type => :setting, :key => "msg", 
                  :value => "hey hi", :override => ""})

    # test space inside string
    assert_equal(ConfigParser::Parser.parseSetting("msg = \"hey     hi\"", 1),
                 {:type => :setting, :key => "msg", 
                  :value => "hey     hi", :override => ""})

    # test comment inside string
    assert_equal(ConfigParser::Parser.parseSetting("msg = \"hey;hi\"", 1),
                 {:type => :setting, :key => "msg", 
                  :value => "hey;hi", :override => ""})

    # test override
    assert_equal(ConfigParser::Parser.parseSetting("name<first> = alice; hello", 1),
                 {:type => :setting, :key => "name", 
                  :value => "alice", :override => "first"})
  end

  def test_parseSetting_should_raise_exception()
    # no =
    exception = assert_raise(SyntaxError) do
      ConfigParser::Parser.parseSetting("some random string", 0)
    end
    assert_equal(exception.message, "Parse error in line 1")

    # wrong placement of ;
    exception = assert_raise(SyntaxError) do
      ConfigParser::Parser.parseSetting("name ;= value", 0)
    end
    assert_equal(exception.message, "Parse error in line 1")

    # missing " in string
    exception = assert_raise(SyntaxError) do
      ConfigParser::Parser.parseSetting("name = \"hello", 0)
    end
    assert_equal(exception.message, "Parse error in line 1")
  end
end
