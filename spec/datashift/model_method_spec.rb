# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::   Specs for ModelMethod aspect of
#
require File.join(File.dirname(__FILE__), '/../spec_helper')


module DataShift

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
      expect { DataShift::ModelMethod.new(Project, 'milestones', :junk ) }.to raise_error BadOperatorType
    end

    it 'should be comparable based on class' do

      a = DataShift::ModelMethod.new(Owner, 'owner', :has_one)
      b = DataShift::ModelMethod.new(Project, 'owner', :has_one)

      expect(a == b).to eq false

      expect(a).to be < b
      expect(b).to be > a
    end

    it 'should be comparable based on operator_type and operator' do

      a = DataShift::ModelMethod.new(Project, 'value_as_text', :assignment )
      b = DataShift::ModelMethod.new(Project, 'title', :assignment )
      a_again = DataShift::ModelMethod.new(Project, 'value_as_text', :assignment )
      a_diff_type = DataShift::ModelMethod.new(Project, 'value_as_text', :has_one )

      c = DataShift::ModelMethod.new(Project, 'owner', :has_one )

      d = DataShift::ModelMethod.new(Project, 'owner', :has_many )
      d_again = DataShift::ModelMethod.new(Project, 'owner', :has_many )

      expect(a == b).to eq false
      expect(a == a).to eq true
      expect(a == a_again).to eq true
      expect(a == a_diff_type).to eq false
      expect(c == d).to eq false
      expect(d == d_again).to eq true

      expect(a).to be > b

      # i.e assignment comes before has_one
      expect(a).to be < a_diff_type

      expect(c).to be < a_diff_type
      expect(c).to be < d
      expect(d).to be > c
      expect(d).to be >= d_again

      clist = [a, d_again, b, d, c]

      clist.sort!

      expect(clist).to eq [b, a,c ,d, d_again]
    end
  end

end
