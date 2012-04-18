require 'spec_helper'

RSpec::Matchers.define :have_field do |expected|
  def find_field_entry(actual,expected)
    field_entries = actual.select { |f| f.first == expected[:field] }
    field_entries.any? ? field_entries.first : nil
  end

  def attributes_match?(actual_attributes, expected_attributes)
    expected_attributes.each do |attr,value|
      return false if actual_attributes[attr] != value
    end

    true
  end

  match do |actual|
    (actual_field = find_field_entry(actual,expected)) && attributes_match?(actual_field.last, expected[:attributes])
  end

  failure_message_for_should do |actual|
    "expected that #{actual.inspect} would have a field conforming to #{expected.inspect}"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual.inspect} would not have a field conforming to #{expected.inspect}"
  end

  description do
    "has a field conforming to #{expected}"
  end
end

describe AreWeThereYet::Persistence::Schema do
  before(:each) do
    @db_name = "/tmp/arewethereyet.sqlite"
    @db = "sqlite://#{@db_name}"

    File.unlink(@db_name) if File.exists? @db_name

    @connection = Sequel.connect(@db)
  end

  it "should create a table for storing spec files" do
    AreWeThereYet::Persistence::Schema.create(@connection)

    @connection.tables.should include :spec_files
    @connection.schema(:spec_files).should have_field :field => :id, :attributes => {:type => :integer, :primary_key => true}
    @connection.schema(:spec_files).should have_field :field => :started_at, :attributes => { :type => :datetime}
  end
end
