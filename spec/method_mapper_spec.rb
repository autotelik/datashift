# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for MethodMapper aspect of Active Record Loader
#             MethodMapper provides the bridge between 'strings' e.g column headings
#             and a classes different types of assignment operators
#
require File.join(File.dirname(__FILE__), 'spec_helper')
    
require 'method_mapper'

describe 'Method Mapper' do
   
  before(:each) do
    DataShift::MethodDictionary.clear   
    
    @method_mapper = DataShift::MethodMapper.new
  end
 
  it "should find a set of methods based on a list of column symbols" do
     
    headers = [:value_as_string, :owner, :value_as_boolean, :value_as_double]
    
    method_details = @method_mapper.map_inbound_headers_to_methods( Project, headers )
    
    expect(method_details.size).to eq 4
  end

  it "should leave nil in set of methods when no such operator" do
     
    headers = [:value_as_string, :owner, :bad_no_such_column, :value_as_boolean, :value_as_double, :more_rubbish_as_nil]
    
    method_details = @method_mapper.map_inbound_headers_to_methods( Project, headers )
    
    expect(method_details.size).to eq 6
    
    method_details[2].should be_nil
    method_details[5].should be_nil
    
    method_details[0].should be_a DataShift::MethodDetail
    
  end
  
  it "should map a list of column names to a set of method details" do
   
    headers = %w{ value_as_double value_as_string bad_no_such_column value_as_boolean  }
    
    @method_mapper.map_inbound_headers_to_methods( Project, headers )
    
    method_details = @method_mapper.map_inbound_headers_to_methods( Project, headers )
    
    expect(method_details.size).to eq 4
    
    method_details[2].should be_nil
   
    method_details[0].should be_a DataShift::MethodDetail 
    method_details.last.should be_a DataShift::MethodDetail
  end
  
  it "should populate a method detail instance based on column and database info" do
     
    headers = [:value_as_string, :owner, :value_as_boolean, :value_as_double]
    
    method_details = @method_mapper.map_inbound_headers_to_methods( Project, headers )
    
    expect(method_details.size).to eq 4
    
    method_details[0].should be_a DataShift::MethodDetail
    
    headers.each_with_index do |c, i|
      method_details[i].column_index.should == i
    end
      
  end
  
  it "should map between user name and real class operator and store in method detail instance" do
     
    headers = [ "Value as string", 'owner', "value_as boolean", 'Value_As_Double']
    
    operators = %w{ value_as_string owner value_as_boolean value_as_double }
    
    method_details = @method_mapper.map_inbound_headers_to_methods( Project, headers )
    
    expect(method_details.size).to eq 4
    
    method_details.should_not include nil
    
    headers.each_with_index do |c, i|
      method_details[i].column_index.should == i
      method_details[i].name.should == c
      method_details[i].operator.should == operators[i]  
    end
    
  end
  
  
  
end