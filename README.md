# README

## About

AreWeThereYet is a gem that provides alternative profiling for RSpec 1.3.x for those who are not blessed enough to be using all the
crunchy goodness that is RSpec 2.x.  Metrics are tracked per file and per example in a SQLite3 database. The URI of the 
database is passed through as a parameter when running the specs

AreWeThereYet does not produce any output to STDOUT during the spec run. Howeevr, it does provide some rudimentary reporting that can
be run against the data in the selected database.

V1.0 provides no backwards compatibility for data recorded by earlier versions.

## Usage

### Logging of spec execution time

1. Add `require 'are_we_there_yet'` to your `spec_helper.rb` file.
2. When running the specs pass the name of the class together with a database uri, e.g:
  `spec -fAreWeThereYet::Recorder:sqlite:///path/to/db.sqlite3 spec`

Only passing tests are profiled.

### Displaying results

AWTY currently offers two methods of listing execution times:

- By file, ordered by descending average execution time.
- By example, listing all the examples for a given file, ordered by descending average execution time. When listing by example, the 
file path in question must also be supplied.

The results can either be displayed by using the executable provided by the AWTY gem or by including the gem in code of your choice, 
and making use of the `AreWeThereYet::Profiler#list_files` or `AreWeThereYet::Profiler#list_examples` methods.

An example of using the executable:

`bundle exec are_we_there_yet --database_uri sqlite:///path/to/results.sqlite3 --list examples --file_path /path/to/spec`

`are_we_there_yet -h` will provide a list of available options.

Currently, the only output supported is csv. The generator of this is very rudimentary. If there are sufficient use cases where 
example descriptions contain characters that will break the output (e.g. examples that contain double quotes within their
description) then it would make sense to use something like FasterCSV.

An example of including AreWeThereYet::Profiler in other Ruby code:

    require 'rubygems'
    require 'are_we_there_yet'

    # Instantiate the Profiler class with a string containing the path to the location of the database
    profiler = AreWeThereYet::Profiler.new(@db_name)

    examples_for_file = profiler.list_examples("/path/to/spec")

Details of the output format as well as usage of `AreWeThereYet::Profiler#list_files` method can be found in
`spec/lib/profiler_spec.rb`.
    
## Database

AWTY should support any database that Sequel (the current underlying ORM library) supports - simply specify the URI accordingly.

## Acknowledgements

My employer, Hetzner (Pty) Ltd, generously allows me to work on Open Source projects during work hours - which accounted for most 
of the tim espent on this gem.

Thanks also to Sheldon Hearn for guidance/code review.

## License

Copyright (c) 2012 Rory McKinley

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
