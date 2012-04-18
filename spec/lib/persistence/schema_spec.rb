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

  it "creates a table for storing spec files" do
    AreWeThereYet::Persistence::Schema.create(@connection)

    schema = @connection.schema(:spec_files)

    schema.should have_field :field => :id, :attributes => {:type => :integer, :primary_key => true}
    schema.should have_field :field => :path, :attributes => {:type => :string}

    @connection.indexes(:spec_files).should == { :spec_files_path_index => {:unique=>false, :columns=>[:path]}}
  end

  it "creates a table for tracking spec runs" do
    AreWeThereYet::Persistence::Schema.create(@connection)

    schema = @connection.schema(:runs)
    schema.should have_field :field => :id, :attributes => {:type => :integer, :primary_key => true}
    schema.should have_field :field => :started_at, :attributes => {:type => :datetime}
    schema.should have_field :field => :ended_at, :attributes => {:type => :datetime}
  end

  it "creates a table for tracking examples" do
    AreWeThereYet::Persistence::Schema.create(@connection)

    schema = @connection.schema(:examples)
    schema.should have_field :field => :id, :attributes => {:type => :integer, :primary_key => true}
    schema.should have_field :field => :spec_file_id, :attributes => {:type => :integer}
    schema.should have_field :field => :description, :attributes => {:type => :string}

    @connection.indexes(:examples).should == {
      :examples_spec_file_id_description_index => {:unique=>false, :columns=>[:spec_file_id, :description]}
    }
  end

  it "creates a table for tracking metrics" do
    AreWeThereYet::Persistence::Schema.create(@connection)

    schema = @connection.schema(:metrics)
    schema.should have_field :field => :id, :attributes => {:type => :integer, :primary_key => true}
    schema.should have_field :field => :example_id, :attributes => {:type => :integer}
    schema.should have_field :field => :execution_time, :attributes => {:type => :float}
    schema.should have_field :field => :created_at, :attributes => {:type => :datetime}
    schema.should have_field :field => :run_id, :attributes => {:type => :integer}
  end

  it "rolls back table creation if there is a problem creating any one of the tables" do
    broken_connection = mock(Sequel::SQLite::Database, :tables => [])
    broken_connection.stub(:create_table) do |arg, bl|
      if arg == :metrics
        raise RuntimeError
      else
        @connection.create_table(arg, &bl)
      end
    end

    expect { AreWeThereYet::Persistence::Schema.create(broken_connection) }.should raise_error

    @connection.tables.should be_empty
  end

  it "does not create tables if there already tables present in the database" do
    @connection.create_table(:dummy) do
      primary_key :id
    end

    AreWeThereYet::Persistence::Schema.create(@connection)

    @connection.tables.should == [:dummy]
  end
end
