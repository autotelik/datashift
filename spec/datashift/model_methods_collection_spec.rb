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

      before(:all) do
        DataShift::ModelMethods::Catalogue.clear
        DataShift::ModelMethods::Manager.clear
      end

      context 'Creation' do
        it 'should be' do
          expect(Collection.new( Project )).to be
        end

        it 'should manage method collection at class level' do
          expect(Collection.new( Project ).managed_class).to eq Project
        end

      end

      context 'Empty' do
        let(:collection) { Collection.new(Project) }

        it 'should report name of collected class' do
          c = Collection.new( Project )
          expect(c.managed_class).to eq Project
        end

        it 'should provide access to a set of model methods by type' do
          expect(collection.by_optype).to be_a Hash
        end

        it 'should return nil when no such optype and_operator' do
          expect(collection.find_by_name_and_type(:no_such_op, :belongs_to)).to be_nil
        end
      end

      context 'Build a Collection' do

        before(:all) do
          Catalogue.clear
          Manager.clear

          Manager.catalog_class( Project )
        end

        let(:assignments) { Catalogue.assignments_for(Project) }

        let(:name) { assignments.first }

        let(:model_method) { DataShift::ModelMethod.new(Project, name, :assignment) }

        let(:collection) { Collection.new(Project) }

        before(:each) do
          collection.add( model_method )
        end

        it 'should provide access to complete set of model methods for a class' do
          expect(collection.model_method_list).to be_a Array
        end

        it 'should provide access to iterate through the complete set of model methods' do
          expect(collection.respond_to? :each).to  eq true
        end

        it 'should enable adding model methods to create manager' do
          expect(collection.model_method_list.size).to be 1
          expect(collection.by_optype.size).to be 1
        end

        it 'should enable extraction of details from manager' do

          collection.add(  DataShift::ModelMethod.new(Project, assignments[1], :assignment) )

          expect(collection.for_type(:assignment).size).to eq 2
          expect(collection.for_type(:assignment).first).to be_a ModelMethod

          expect(collection.by_optype[:assignment]).to be_a Array
          expect(collection.by_optype[:assignment].size).to eq 2

          expect(collection.by_optype[:assignment].include?(model_method)).to eq true
          expect(collection.by_optype[:assignment].first.operator).to eq name
        end

        it 'should enable finding specific operators' do
          expect( collection.find_by_name_and_type(name, :assignment ) ).to eq model_method
        end
      end

      context 'Full Collection from Class and operations' do

        let(:collection) { ModelMethods::Manager.catalog_class(Project) }

        it 'should be sortable based on operator and op type' do

          expect(collection).to be_a  DataShift::ModelMethods::Collection

          collection.unshift( DataShift::ModelMethod.new(Project, 'aaa', :has_many) )
          collection.add( DataShift::ModelMethod.new(Project, 'aaa', :assignment) )
          collection.unshift( DataShift::ModelMethod.new(Project, 'zzz', :assignment) )

          expect(collection.first.operator).to eq 'zzz'
          expect(collection.last.operator_type? :assignment).to eq true

          collection.sort!

          expect(collection.first.operator).to eq 'aaa'
          expect(collection.last.operator_type? :has_many).to eq true
        end


        it 'should be Searchable across op types' do
          names = Project.reflect_on_all_associations(:belongs_to).map { |i| i.name.to_s }

          mm = collection.search( names.last )

          expect(mm.operator).to eq names.last
          expect(mm.operator_type? :belongs_to).to eq true
        end

      end
    end

  end

end
