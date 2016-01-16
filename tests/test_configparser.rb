require "test/unit"
require File.expand_path(File.dirname(__FILE__) + "/../lib/configparser")

class TestConfigParser < Test::Unit::TestCase

  def test_serverconf() 
    filename = File.expand_path(File.dirname(__FILE__) + "/../conf/server.conf")
    config = ConfigParser::Parser.load_config(filename)

    ## common
    assert_equal(config.common.basic_size_limit, 26214400)
    assert_equal(config.common.student_size_limit, 52428800)
    assert_equal(config.common.paid_users_size_limit, 2147483648)
    assert_equal(config.common.path, "/srv/var/tmp/")

    ## ftp 
    assert_equal(config.ftp.path, "/tmp/")
    assert_equal(config.ftp.enabled, false)
    assert_equal(config.ftp.name, "\"hello there, ftp uploading\"")

    # http
    assert_equal(config.http.name, "\"http uploading\"")
    assert_equal(config.http.path, "/tmp/")
    assert_equal(config.http.params, ["array", "of", "values"])
  end

  def test_serverconf_with_single_override()
    filename = File.expand_path(File.dirname(__FILE__) + "/../conf/server.conf")
    config = ConfigParser::Parser.load_config(filename, overrides=[:staging])

    ## common
    assert_equal(config.common.basic_size_limit, 26214400)
    assert_equal(config.common.student_size_limit, 52428800)
    assert_equal(config.common.paid_users_size_limit, 2147483648)
    assert_equal(config.common.path, "/srv/var/tmp/")

    ## ftp 
    assert_equal(config.ftp.path, "/srv/uploads/")
    assert_equal(config.ftp.enabled, false)
    assert_equal(config.ftp.name, "\"hello there, ftp uploading\"")

    # http
    assert_equal(config.http.name, "\"http uploading\"")
    assert_equal(config.http.path, "/srv/uploads/")
    assert_equal(config.http.params, ["array", "of", "values"])
  end

  def test_serverconf_with_multiple_overrides()
    filename = File.expand_path(File.dirname(__FILE__) + "/../conf/server.conf")
    config = ConfigParser::Parser.load_config(filename, overrides=[:staging, "ubuntu"])

    ## common
    assert_equal(config.common.basic_size_limit, 26214400)
    assert_equal(config.common.student_size_limit, 52428800)
    assert_equal(config.common.paid_users_size_limit, 2147483648)
    assert_equal(config.common.path, "/srv/var/tmp/")

    ## ftp 
    assert_equal(config.ftp.path, "/etc/var/uploads/")
    assert_equal(config.ftp.enabled, false)
    assert_equal(config.ftp.name, "\"hello there, ftp uploading\"")

    # http
    assert_equal(config.http.name, "\"http uploading\"")
    assert_equal(config.http.path, "/srv/uploads/")
    assert_equal(config.http.params, ["array", "of", "values"])
  end

end
