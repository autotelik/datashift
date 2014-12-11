# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for base class Loader
#
require File.dirname(__FILE__) + '/spec_helper'

require 'erb'

describe 'LoaderBase' do


  before(:each) do    
    @loader = DataShift::LoaderBase.new(Project)
  end
  
  it "should be able to create a new loader and load object" do
    @loader.load_object.should_not be_nil
    @loader.load_object.should be_is_a(Project)
    expect(@loader.load_object.new_record?).to eq true
  end


  it "should process a string field against an assigment method detail" do

    column = 'Value As String'
    row = 'Another Lazy fox '

    @loader.find_and_process(column, row)

    expect(@loader.load_object.errors.size).to eq 0
  end
  
  it "should process a string field against an assigment method detail" do

    column = 'Value As String'
    row = 'Another Lazy fox '

    @loader.find_and_process(column, row)

    @loader.load_object.value_as_string.should == row
  end

  it "should process a text field against an assigment method detail" do

    column = :value_as_text
    row = "Another Lazy fox\nJumped over something and bumped,\nHis head"

    @loader.find_and_process(column, row)

    @loader.load_object.value_as_text.should == row

  end

  it "should process a boolean field against an assigment method detail" do

    column = :value_as_boolean
    row = true

    @loader.find_and_process(column, row)

    @loader.load_object.value_as_boolean.should == row

    row = 'false'

    @loader.find_and_process(column, row)

    @loader.load_object.value_as_boolean.should == false


  end

  it "should process a double field against an assigment operator" do
  end

  it "should process various date formats against a date assigment operator" do
    column = :value_as_datetime

    @loader.find_and_process(column, Time.now)
    @loader.load_object.value_as_datetime.should_not be_nil

    @loader.find_and_process(column, "2011-07-23")
    @loader.load_object.value_as_datetime.should_not be_nil

    @loader.find_and_process(column, "Sat Jul 23 09:01:56 +0100 2011")
    @loader.load_object.value_as_datetime.should_not be_nil

    @loader.find_and_process(column,  Time.now.to_s(:db))
    @loader.load_object.value_as_datetime.should_not be_nil

    @loader.find_and_process(column,  "Jul 23 2011 23:02:59")
    @loader.load_object.value_as_datetime.should_not be_nil

    if(DataShift::Guards.jruby?)
      @loader.find_and_process(column,  "07/23/2011")    # dd/mm/YYYY
      @loader.load_object.value_as_datetime.should_not be_nil
    end
    
    # bad casts - TODO - is this really an error needs raising ?
    @loader.find_and_process(column, "2011 07 23")
    @loader.load_object.value_as_datetime.should be_nil


    @loader.find_and_process(column,  "2011-23-07")
    @loader.load_object.value_as_datetime.should be_nil

  end

  it "should be able to mark a load attempt as a failure" do
    
    failed_count = @loader.failed_count
    expect(@loader.load_object.new_record?).to eq true
     
    @loader.load_object.save!
     
    @loader.failure 
    
    @loader.failed_count.should == failed_count + 1
  end
  
end