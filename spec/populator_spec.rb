# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for base class Loader
#
require File.dirname(__FILE__) + '/spec_helper'

require 'erb'

describe 'Populator' do

  include_context "ActiveRecordTestModelsConnected"
  
  include_context "ClearAndPopulateProject"
  
  before(:each) do    
    @loader = DataShift::LoaderBase.new(Project)
    
    @populator = DataShift::Populator.new
    
  end
  
  it "should be able to create a new populator" do
    local_populator = DataShift::Populator.new
    local_populator.should_not be_nil
  end

  
  it "should be able to create and assign  populator as string to loader" do
    
    class AnotherPopulator
    end
    
    options = {:populator => 'AnotherPopulator' }
    
    local_loader = DataShift::LoaderBase.new(Project, true, nil, options)
    
    local_loader.populator.should_not be_nil
    local_loader.populator.should be_a AnotherPopulator
  end

  it "should be able to create and assign populator as class to loader" do
    
    class AnotherPopulator
    end
    
    options = {:populator => AnotherPopulator }
    
    local_loader = DataShift::LoaderBase.new(Project, true, nil, options)
    
    local_loader.populator.should_not be_nil
    local_loader.populator.should be_a AnotherPopulator
  end
  
  it "should process a string value against an assigment column" do

    column_heading = 'Value As String'
    value = 'Another Lazy fox '

    method_detail = DataShift::MethodDictionary.find_method_detail( Project, column_heading )
    
    method_detail.should_not be_nil
    
    x, attributes = @populator.prepare_data(method_detail, value)
    
    x.should == value
    attributes.should be_a Hash
    attributes.should be_empty
    
  end

  it "should process a string value against an assigment instance method" do

    value = 'Get up Lazy fox '

    DataShift::MethodDictionary.find_operators( Milestone, :instance_methods => true  )
    
    DataShift::MethodDictionary.build_method_details( Milestone  )
      
    method_detail = DataShift::MethodDictionary.find_method_detail( Milestone, :title )
    
    method_detail.should_not be_nil
    
    x, attributes = @populator.prepare_data(method_detail, value)
    
    x.should == value
    attributes.should be_a Hash
    attributes.should be_empty
    
  end
  
end