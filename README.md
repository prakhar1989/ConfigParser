ConfigParser
===

A Ruby module to parse config files.

### Supports 
- Overrides (via `<override>`)
- Line number reporting on syntax errors
- Method-like querying on the returned object

### Usage

```ruby
require('configparser.rb')

begin 
  CONFIG = ConfigParser::Parser.load_config("./conf/temp.conf")
rescue SyntaxError => msg
  puts "Unable to read file: #{msg}"
  exit
end
```

### Tests
```
$ rake test

# Running tests:

Finished tests in 0.007693s, 1039.9064 tests/s, 7799.2981 assertions/s.
8 tests, 60 assertions, 0 failures, 0 errors, 0 skips

ruby -v: ruby 2.1.4p265 (2014-10-27 revision 48166) [x86_64-darwin15.0]
```


##### Sample Output

```
$ pry
[1] pry(main)> require './lib/configparser.rb'
=> true

[2] pry(main)> CONFIG = ConfigParser::Parser.load_config("./conf/server.conf", 
["ubuntu", :production])

[3] pry(main)> CONFIG.common.paid_users_size_limit
=> 2147483648

[4] pry(main)> CONFIG.ftp.name
=> "\"hello there, ftp uploading\""

[5] pry(main)> CONFIG.http.params
=> ["array", "of", "values"]

[6] pry(main)> CONFIG.ftp.lastname
=> nil

[7] pry(main)> CONFIG.ftp.enabled
=> false

[8] pry(main)> CONFIG.ftp[:path]
=> "/srv/var/tmp/"

[9] pry(main)> CONFIG.ftp
=> {:name=>"\"hello there, ftp uploading\"", :path=>"/srv/var/tmp/", :enabled=>false}
```

