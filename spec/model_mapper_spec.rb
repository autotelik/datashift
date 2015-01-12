# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Aug 2015
# License::   MIT
#
# Details::   Specs for Mapping aspects
#             Provides automatic mapping between different system's column headings
#
require File.join(File.dirname(__FILE__), 'spec_helper')

require 'mapping_generator'

describe 'ModelMapper' do

  before(:all) do
  end

  before(:each) do
  end

  it "should identify the class from a string" do
    # Similar to const_get_from_string except this version
    # returns nil if no such class found
    # Support modules e.g "Spree::Property"
    #
    expect(DataShift::ModelMapper.class_from_string( Project)).to be_a Class

  end

  it "should identify the class from a string contianing modules" do
    # Similar to const_get_from_string except this version
    # returns nil if no such class found
    # Support modules e.g "Spree::Property"
    #
    expect(DataShift::ModelMapper.class_from_string( DataShift::AClassInAModule )).to be_a Class

  end



end