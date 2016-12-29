# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Aug 2015
# License::   MIT
#
# Details::   Specs for Mapping aspects
#             Provides automatic mapping between different system's column headings
#
require File.join(File.dirname(__FILE__), '/../spec_helper')

describe 'MapperUtils' do

  it 'should identify the class from a string' do
    # Similar to const_get_from_string except this version
    # returns nil if no such class found
    # Support modules e.g "Spree::Property"
    #
    expect(DataShift::MapperUtils.class_from_string( Project)).to be_a Class
  end

  it 'should identify the class from a string containing modules' do
    # Similar to const_get_from_string except this version
    # returns nil if no such class found
    # Support modules e.g "Spree::Property"
    #
    expect(DataShift::MapperUtils.class_from_string( DataShift::AClassInAModule )).to be_a Class
  end

  it 'should ensure a valid class is returned whether a class or string passed in' do
    expect(DataShift::MapperUtils.ensure_class("Project")).to be_a Class
    expect(DataShift::MapperUtils.ensure_class(Project)).to be_a Class
  end

  it 'should throw when invalid class supplied' do
    expect { DataShift::MapperUtils.ensure_class("Proj") }.to raise_error DataShift::NoSuchClassError
  end

end
