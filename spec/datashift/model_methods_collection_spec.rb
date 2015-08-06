# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Mar 2015
# License::   MIT
#
# Details::   Specs for ModelMapperManager and associated DataShift::ModelMethodsMgrs::Dictionary
#
require File.join(File.dirname(__FILE__), '/../spec_helper')

module DataShift

  module ModelMethods

    describe 'Collection' do
      include_context 'ClearAllCatalogues'

      context 'Collection' do
        it 'should manage method collection at class level' do
          expect(Collection.new( Project )).to be
        end
      end

      context 'Empty' do
        let(:collection) { Collection.new(Project) }

        before(:each) do
        end

        it 'should report name of collected class' do
          c = Collection.new( Project )
          expect(c.managed_class).to eq Project
        end

        it 'should provide access to a set of model methods by type' do
          expect(collection.by_optype).to be_a Hash
        end

        it 'should provide access to a particular model methods by type & operator' do
          expect(collection.by_optype_and_operator).to be_a Hash
        end

        it 'should return nil when no such optype and_operator' do
          expect(collection.find(:no_such_op, :belongs_to)).to be_nil
        end
      end

      context 'Collected' do
        include_context 'ClearThenManageProject'

        let(:collection) { Collection.new(Project) }

        let(:name) { Catalogue.assignments_for(Project).first }

        let(:model_method) { DataShift::ModelMethod.new(Project, name, :assignment) }

        before(:each) do
          collection.add( model_method )
        end

        it 'should enable adding model methods to create manager' do
          expect(collection.by_optype_and_operator.size).to be 1
          expect(collection.by_optype.size).to be 1
        end

        it 'should enable extraction of details from manager' do
          # we should remove has-many & belongs_to from basic assignment set as they require a DB lookup
          # or a Model.create call, not a simple assignment

          expect(collection.by_optype_and_operator[:assignment].values.size).to be 1
          expect(collection.by_optype_and_operator[:assignment][name]).to be_a ModelMethod

          expect(collection.by_optype[:assignment]).to be_a Array
          expect(collection.by_optype[:assignment].size).to be 1

          expect(collection.by_optype[:assignment].include?(model_method)).to eq true
          expect(collection.by_optype[:assignment].first.operator).to eq name
        end

        it 'should enable finding specific operators' do
          expect( collection.find(name, :assignment ) ).to eq model_method
        end
      end
    end

  end

end
