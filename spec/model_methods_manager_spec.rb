# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2015
# License::   MIT
#
# Details::   Specs for ModelMapperManager and associated DataShift::ModelMethodsMgrs::Dictionary
#
require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'Model Methods' do

  it "should map multiple domain models to model methods" do
    DataShift::ModelMethods::Catalogue.clear

    expect(DataShift::ModelMethods::Catalogue.methods_for?(Project)).to eq false
  end

  context 'Find Project' do

    before(:each) do
      DataShift::ModelMethods::Catalogue.clear
      DataShift::ModelMethods::Catalogue.find_methods( Project )
    end

    it "should map multiple domain models to model methods" do

      DataShift::ModelMethods::Catalogue.find_methods( Milestone )

      expect(DataShift::ModelMethods::Catalogue.assignments[Project]).to be_a Array
      expect(DataShift::ModelMethods::Catalogue.assignments[Project].empty?).to eq false

      expect(DataShift::ModelMethods::Catalogue.assignments[Project]).to_not eq DataShift::ModelMethods::Catalogue.assignments[Milestone]
    end

    it "should interrogate a domain model to build has_many associations" do
      expect(DataShift::ModelMethods::Catalogue.has_many).to_not be_empty
      expect(DataShift::ModelMethods::Catalogue.has_many[Project]).to include('milestones')
    end

    it "should interrogate a domain model to build set of model methods" do

      DataShift::ModelMethods::Catalogue.find_methods( Milestone )

      expect(DataShift::ModelMethods::Catalogue.assignments).to_not be_empty
      expect(DataShift::ModelMethods::Catalogue.assignments[Project]).to include('id')
      expect( DataShift::ModelMethods::Catalogue.assignments[Project]).to include('value_as_string')
      expect(DataShift::ModelMethods::Catalogue.assignments[Project]).to include('value_as_text')

      expect( DataShift::ModelMethods::Catalogue.belongs_to).to_not be_empty
      expect(DataShift::ModelMethods::Catalogue.belongs_to[Project]).to include 'user'

      expect(DataShift::ModelMethods::Catalogue.column_types).to be_is_a(Hash)
      expect(DataShift::ModelMethods::Catalogue.column_types).to_not be_empty
      expect(DataShift::ModelMethods::Catalogue.column_types[Project].size).to eq Project.columns.size

    end

    it "should populate assignment members without the equivalent association names" do
      # we should remove has-many & belongs_to from basic assignment set as they require a DB lookup
      # or a Model.create call, not a simple assignment
      expect(DataShift::ModelMethods::Catalogue.assignments_for(Project)).to_not include DataShift::ModelMethods::Catalogue.belongs_to_for(Project)
      expect(DataShift::ModelMethods::Catalogue.assignments_for(Project)).to_not include DataShift::ModelMethods::Catalogue.has_many_for(Project)
    end

    context 'Manager' do

      it "should provide a manager to manage method collection at class level" do
        expect(DataShift::ModelMethods::Manager.new( Project )).to be
      end

      it "should collate all methods in easy to interrogate collections" do

        mgr = DataShift::ModelMethods::Manager.new(Project)

        expect(mgr.managed_class).to eq Project
        expect(mgr.model_methods).to be_a Hash
        expect(mgr.model_methods_list).to be_a Hash
      end

      it "should enable adding model methods to create manager" do
        name = DataShift::ModelMethods::Catalogue.assignments_for(Project).first

        expect(name).to be_a String
        expect(name.size).to be > 0

        # we should remove has-many & belongs_to from basic assignment set as they require a DB lookup
        # or a Model.create call, not a simple assignment
        model_method = DataShift::ModelMethod.new(Project, name, :assignment)

        mgr = DataShift::ModelMethods::Manager.new(Project)

        mgr.add( model_method )

        expect(mgr.model_methods.size).to be 1
        expect(mgr.model_methods_list.size).to be 1
      end

      it "should enable extraction of details from manager" do
        name = DataShift::ModelMethods::Catalogue.assignments_for(Project).first

        # we should remove has-many & belongs_to from basic assignment set as they require a DB lookup
        # or a Model.create call, not a simple assignment
        model_method = DataShift::ModelMethod.new(Project, name, :assignment)

        mgr = DataShift::ModelMethods::Manager.new(Project)
        mgr.add( model_method )

        expect(mgr.model_methods[:assignment].values.size).to be 1
        expect(mgr.model_methods[:assignment][name]).to be_a DataShift::ModelMethod

        expect(mgr.model_methods_list[:assignment]).to be_a Array
        expect(mgr.model_methods_list[:assignment].size).to be 1

        expect(mgr.model_methods_list[:assignment].include?(model_method)).to eq true
        expect(mgr.model_methods_list[:assignment].first.operator).to eq name
      end

      it "should enable finding specific operators" do
        name = DataShift::ModelMethods::Catalogue.assignments_for(Project).first

        model_method = DataShift::ModelMethod.new(Project, name, :assignment)

        mgr = DataShift::ModelMethods::Manager.new(Project)
        mgr.add( model_method )

        expect( mgr.find(name, :assignment ) ).to eq model_method
      end

    end
  end

end