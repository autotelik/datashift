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

  let(:raw_column)  { 'value_as_string' }

  let(:manager)      { DataShift::ModelMethods::ManagerDictionary.for(Project) }

  it "should bind details of inbound header to domain model" do

    model_method = manager.search(raw_column)

    binding =  DataShift::MethodBinding.new(raw_column, 1, model_method)
    expect(binding).to be
  end

  it "should be valid when inbound name maps to an operator" do

    model_method = manager.search(raw_column)

    binding =  DataShift::MethodBinding.new(raw_column, 2, model_method)
    expect(binding.valid?).to eq true
  end

  it "should be invalid when inbound name fails to maps to an operator" do

    model_method = manager.search('what_a_load_of_rubbish')

    binding =  DataShift::MethodBinding.new(raw_column, 3, model_method)
    expect(binding.valid?).to eq false
  end
  
end