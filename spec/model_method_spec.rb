# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::   Specs for ModelMethod aspect of
#
require File.join(File.dirname(__FILE__), 'spec_helper')
    
require 'model_method'

describe 'Model Method' do

  it "should hold details of assignment method on a class" do

    method_details = DataShift::ModelMethod.new(Project, :value_as_string, :assignment )
    
    expect(method_details).to be
  end


  it "should hold details of belongs_to method on a class" do

    method_details = DataShift::ModelMethod.new(Project, 'user', :belongs_to )

    expect(method_details).to be
  end

  it "should hold details of has_one method on a class" do

    method_details = DataShift::ModelMethod.new(Project, 'owner', :has_one )

    expect(method_details).to be
  end


  it "should hold details of has_many method on a class" do

    method_details = DataShift::ModelMethod.new(Project, 'milestones', :has_many )

    expect(method_details).to be
  end

  it "should raise when unknown type" do
    expect { DataShift::ModelMethod.new(Project, 'milestones', :junk )}.to raise_error
  end

end