# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::   Specs for MethodDetail aspect of Active Record Loader
#             MethodDetail holds details of a method call on an AR object
#             linked to the incoming column header/index
#
require File.join(File.dirname(__FILE__), 'spec_helper')
    
require 'method_binding'

describe 'Method Binding' do

  include_context "ClearAndPopulateProject"


  it "should bind details of inbound header to domain model" do

    model_method =
    method_details = MethodBinding.new( 'value_as_string', Project, :value_as_string, :attribute )
    
    expect(method_details).to be
  end

  it "should be valid when inbound name maps to an operator" do

    method_details = MethodDetail.new( 'value_as_string', Project, :value_as_string, :attribute )

    expect(method_details.valid?).to eq true
    
  end

  it "should be invalid when inbound name maps to an operator" do

    method_details = MethodDetail.new( 'value_as_string', Project, :value_as_string, :attribute )

    expect(method_details.valid?).to eq true

  end
  
end