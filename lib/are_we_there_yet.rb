require "spec/runner/formatter/base_formatter" unless defined? AWTY_SPEC_RUN
require 'sequel'

require File.join(File.dirname(__FILE__), 'are_we_there_yet', 'profiler')
require File.join(File.dirname(__FILE__), 'are_we_there_yet', 'recorder')

