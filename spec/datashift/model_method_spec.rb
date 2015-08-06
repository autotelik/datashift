# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::   Specs for ModelMethod aspect of
#
require File.join(File.dirname(__FILE__), '/../spec_helper')

require 'model_method'

describe 'Model Method' do
  include_context 'ClearAllCatalogues'

  it 'should hold details of assignment method on a class' do
    model_method = DataShift::ModelMethod.new(Project, :value_as_string, :assignment )

    expect(model_method).to be
  end

  it 'should hold details of belongs_to method on a class' do
    model_method = DataShift::ModelMethod.new(Project, 'user', :belongs_to )

    expect(model_method).to be
  end

  it 'should hold details of has_one method on a class' do
    model_method = DataShift::ModelMethod.new(Project, 'owner', :has_one )

    expect(model_method).to be
  end

  it 'should hold details of has_many method on a class' do
    model_method = DataShift::ModelMethod.new(Project, 'milestones', :has_many )

    expect(model_method).to be
  end

  it 'should hold details of a callable method on a class' do
    model_method = DataShift::ModelMethod.new(Project, 'my_funky_method', :method )

    expect(model_method).to be

    expect(model_method.operator).to eq 'my_funky_method'
    expect(model_method.operator_type).to eq :method
  end

  it 'should hold details of operator type as a symbol' do
    model_method = DataShift::ModelMethod.new(Project, 'my_funky_method', 'method' )
    expect(model_method.operator_type).to eq :method

    model_method = DataShift::ModelMethod.new(Owner, 'milestones', 'has_many' )
    expect(model_method.operator_type).to eq :has_many
  end

  it 'should raise when unknown type' do
    expect { DataShift::ModelMethod.new(Project, 'milestones', :junk ) }.to raise_error
  end
end
