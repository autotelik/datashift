# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Mar 2015
# License::   MIT
#
require File.join(File.dirname(__FILE__), '/../spec_helper')

module DataShift

  module ModelMethods

    describe 'Model Methods' do
      include_context 'ClearAllCatalogues'

      context 'Catalogue a Class' do
        it 'should enable checking a model catalogued' do
          expect(Catalogue.catalogued?(Milestone) ).to eq false
        end

        it 'should report how many classes catalogued' do
          expect(Catalogue.size ).to eq 0
        end

        it 'should catalogue model methods on a domain model' do
          Catalogue.populate( Milestone )

          expect(Catalogue.size ).to eq 1
          expect(Catalogue.catalogued?(Milestone) ).to eq true
        end

        it 'should catalogue model methods on a domain model once' do
          Catalogue.populate( Milestone )
          Catalogue.populate( Milestone )

          expect(Catalogue.size ).to eq 1
          expect(Catalogue.catalogued?(Milestone) ).to eq true
        end

        it 'should catalogue multiple domain models' do
          Catalogue.populate( Milestone )
          Catalogue.populate( Project )
          expect(Catalogue.size ).to eq 2

          expect(Catalogue.catalogued?(Project)).to eq true
          expect(Catalogue.catalogued?(Owner)).to eq false
        end
      end

      context 'interrogate a Class' do
        before(:each) do
          Catalogue.populate( Project )
          Catalogue.populate( Milestone )
        end

        it 'should interrogate a domain model to build has_many associations' do
          expect(Catalogue.has_many).to_not be_empty

          expect(Catalogue.has_many[Project]).to include('milestones')
        end

        it 'should interrogate a domain model to build set of model methods' do
          expect(Catalogue.assignments).to_not be_empty
          expect(Catalogue.assignments[Project]).to include('id')
          expect( Catalogue.assignments[Project]).to include('value_as_string')
          expect(Catalogue.assignments[Project]).to include('value_as_text')

          expect( Catalogue.belongs_to).to_not be_empty
          expect(Catalogue.belongs_to[Project]).to include 'user'

          expect(Catalogue.column_types).to be_is_a(Hash)
          expect(Catalogue.column_types).to_not be_empty
          expect(Catalogue.column_types[Project].size).to eq Project.columns.size
        end

        it 'should return a list of assignment members' do
          expect(Catalogue.assignments_for(Project)).to be_a Array
        end

        it 'should populate assignment members without the equivalent association names' do
          # we should remove has-many & belongs_to from basic assignment set as they require a DB lookup
          # or a Model.create call, not a simple assignment
          expect(Catalogue.assignments_for(Project)).to_not include Catalogue.belongs_to_for(Project)
          expect(Catalogue.assignments_for(Project)).to_not include Catalogue.has_many_for(Project)
        end

        it 'has the operator names in the array' do
          name = Catalogue.assignments_for(Project).first

          expect(name).to be_a String
          expect(name.size).to be > 0
        end

        it 'can include instance methods' do
          Catalogue.populate( Owner, instance_methods: true )

          expect( Catalogue.assignments_for(Owner)).to include 'after_add_for_digitals'
        end

        it 'can force a reload' do
          Catalogue.populate( Owner )

          count = Catalogue.assignments_for(Owner).size

          Catalogue.populate( Owner, reload: true, instance_methods: true )

          expect(Catalogue.assignments_for(Owner).size).to be > count
        end
      end
    end
  end
end
