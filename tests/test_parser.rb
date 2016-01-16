require "test/unit"
require File.expand_path(File.dirname(__FILE__) + "/../lib/configparser")

class TestConfigParser < Test::Unit::TestCase
  def test_more() 
    assert_equal(4+2, 6)
  end
end
