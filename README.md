# README

## About

AreWeThereYet is a gem that provides alternative profiling for RSpec 1.3.x for those who are not blessed enough to be using all the
crunchy goodness that is RSpec 2.x.  Metrics are tracked per file and per example in a SQLite3 database. The location of the 
database is passed through as a parameter when running the specs

AWTY only logs data, so you are currently required to handroll any reporting functionality. There is also, currently no data output
to STDOUT when spec runs with this formatter.

## Usage

Usage is fairly simple:

1. Add `require 'are_we_there_yet'` to your `spec_helper.rb` file.
2. When running the specs pass the name of the class together with the location of your SQLite3 database, e.g:
  `spec -fAreWeThereYet:/path/to/db.sqlite3 spec`

Only passing tests are profiled.

## Data Structure

The following data is stored in the database:

- runs (from v0.2.0 onwards) - this is to allow conclusive tracking of metrics against a specific run. Multiple runs close to one 
may result in guesswork when determining which metrics belong to which run. v0.1.0 does not track this data, but v0.2.0 is backwards 
compatible and can handle the reduced fidelity when dealing with a database created by v0.1.0.
- files - this represents the individual files containing the examples that are being run.
- examples - the individual examples themselves (one file has many examples)
- metrics - the run time per example (per run from v0.2.0 onwards) - one example has many metrics, one run has many metrics

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
