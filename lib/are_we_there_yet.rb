require "spec/runner/formatter/base_formatter" unless defined? AWTY_SPEC_RUN
require 'sequel'

Dir["#{File.dirname(__FILE__)}/are_we_there_yet/**/*.rb"].each {|f| require f}
