require "spec/runner/formatter/base_formatter" unless defined? AWTY_SPEC_RUN
require 'sequel'
require 'data_mapper'

require File.join(File.dirname(__FILE__), 'are_we_there_yet', 'profiler')
require File.join(File.dirname(__FILE__), 'are_we_there_yet', 'profiler_ui')
require File.join(File.dirname(__FILE__), 'are_we_there_yet', 'formatter')
require File.join(File.dirname(__FILE__), 'are_we_there_yet', 'recorder')
require File.join(File.dirname(__FILE__), 'are_we_there_yet', 'example')
require File.join(File.dirname(__FILE__), 'are_we_there_yet', 'spec_file')
require File.join(File.dirname(__FILE__), 'are_we_there_yet', 'metric')

