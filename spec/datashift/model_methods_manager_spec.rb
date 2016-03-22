# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Aug 2015
# License::   MIT
#
#
require File.join(File.dirname(__FILE__), '/../spec_helper')

module DataShift

  module ModelMethods

    describe ':ModelMethods ManagerDictionary' do
      include_context 'ClearAllCatalogues'

      it 'should provide a dictionary of class => manager' do
        expect(Manager.collections).to be_a Hash
        expect(Manager.collections.empty?).to eq true
      end

      it 'should provide a dictionary of class => manager' do
        expect(Manager.collections[Milestone]).to be_nil
      end

      it 'should provide facilities to check a class been collected' do
        expect(Manager.for?(Milestone)).to eq false
      end

      it 'should return nil as an empty collection' do
        expect(Manager.for(Milestone)).to be nil
      end

      it 'should enable a class to be collected and return new collection' do
        expect(Manager.catalog_class(Milestone)).to be_a Collection
      end

      context 'Cataloged' do
        before(:each) do
          Manager.catalog_class(Milestone)
        end

        it 'should report when a class has been collected' do
          expect(Manager.for?(Milestone)).to eq true
        end

        it 'should provide facilities to return a populated collection' do
          expect(Manager.for(Milestone)).to be_a Collection
        end

        it 'should provide access to a collection' do
          expect(Manager.collections[Milestone]).to be_a Collection

          expect(Manager.collections[Milestone]).to eq Manager.for(Milestone)
        end

        it 'should populate assignment operators for method details for different forms of a column name' do
          Manager.catalog_class(Project)
          Manager.catalog_class(Milestone)

          collection = Manager.for(Project)

          expect(collection.managed_class).to eq Project

          model_method = collection.find_by_name_and_type('value_as_string', :assignment)

          expect(model_method).to be_a DataShift::ModelMethod

          expect(model_method.operator).to eq 'value_as_string'
          expect(model_method.operator_for(:assignment)).to eq 'value_as_string'

          expect(model_method.operator?('value_as_string')).to eq true
          expect(model_method.operator?('blah_as_string')).to eq false

          expect(model_method.operator_for(:belongs_to)).to eq nil
          expect(model_method.operator_for(:has_many)).to eq nil
        end

        #   it "should populate method dictionary for a given AR model" do
        #
        #     DataShift::ModelMethodsManager.find_methods( Project )
        #     DataShift::ModelMethodsManager.find_methods( Milestone )
        #
        #     DataShift::MethodDictionary.has_many.should_not be_empty
        #     DataShift::MethodDictionary.has_many[Project].should include('milestones')
        #
        #     DataShift::MethodDictionary.assignments.should_not be_empty
        #     DataShift::MethodDictionary.assignments[Project].should include('id')
        #     DataShift::MethodDictionary.assignments[Project].should include('value_as_string')
        #     DataShift::MethodDictionary.assignments[Project].should include('value_as_text')
        #
        #     DataShift::MethodDictionary.belongs_to.should_not be_empty
        #     expect(DataShift::MethodDictionary.belongs_to[Project]).to include 'user'
        #
        #
        #     DataShift::MethodDictionary.column_types.should be_is_a(Hash)
        #     DataShift::MethodDictionary.column_types.should_not be_empty
        #     DataShift::MethodDictionary.column_types[Project].size.should == Project.columns.size
        #
        #
        #   end
        #
        #   it "should populate assigment members without the equivalent association names" do
        #
        #     DataShift::ModelMethodsManager.find_methods( Project )
        #
        #     # we should remove has-many & belongs_to from basic assignment set as they require a DB lookup
        #     # or a Model.create call, not a simple assignment
        #
        #     DataShift::MethodDictionary.assignments_for(Project).should_not include( DataShift::MethodDictionary.belongs_to_for(Project) )
        #     DataShift::MethodDictionary.assignments_for(Project).should_not include( DataShift::MethodDictionary.has_many_for(Project) )
        #   end
        #
        #
        #
        #
        #
        #   # Note : Not all assignments will currently have a column type, for example
        #   # those that are derived from a delegate_belongs_to
        #
        #   it "should populate column types for assignment operators in method details" do
        #
        #     DataShift::ModelMethodsManager.find_methods( Project )
        #
        #     DataShift::MethodDictionary.build_method_details( Project )
        #
        #     [:value_as_string, 'value_as_string', "VALUE as_STRING", "value as string"].each do |format|
        #
        #       method_details = DataShift::MethodDictionary.find_method_detail( Project, format )
        #
        #       method_details.class.should == DataShift::ModelMethod
        #
        #       method_details.col_type.should_not be_nil
        #       method_details.col_type.name.should == 'value_as_string'
        #       method_details.col_type.default.should == nil
        #       method_details.col_type.sql_type.should include 'varchar(255)'   # db specific, sqlite
        #       method_details.col_type.type.should == :string
        #     end
        #   end
        #
        #   it "should populate required Class for assignment operators based on column type" do
        #
        #     DataShift::ModelMethodsManager.find_methods( Project )
        #
        #     DataShift::MethodDictionary.build_method_details( Project )
        #
        #     [:value_as_string, 'value_as_string', "VALUE as_STRING", "value as string"].each do |format|
        #
        #       method_details = DataShift::MethodDictionary.find_method_detail( Project, format )
        #
        #       method_details.operator_class_name.should == 'String'
        #       method_details.operator_class.should be_is_a(Class)
        #       method_details.operator_class.should == String
        #     end
        #
        #   end
        #
        #
        #   it "should populate method_details on Class for belongs_to" do
        #
        #     DataShift::ModelMethodsManager.find_methods( Owner )
        #
        #     DataShift::MethodDictionary.build_method_details( Owner )
        #
        #     [:project, 'PROJECT'].each do |format|
        #
        #       method_details = DataShift::MethodDictionary.find_method_detail( Owner, format )
        #
        #       expect(method_details.operator_class_name).to eq 'Project'
        #       expect(method_details.operator_class).to be_a(Class)
        #       expect(method_details.operator_class).to eq Project
        #     end
        #
        #   end
        #
        #
        #   it "should populate belongs_to operator for method details for different forms of a column name" do
        #
        #     DataShift::ModelMethodsManager.find_methods( Project )
        #     DataShift::ModelMethodsManager.find_methods( Milestone )
        #
        #     DataShift::MethodDictionary.build_method_details( Project )
        #     DataShift::MethodDictionary.build_method_details( Milestone )
        #
        #     # milestone.project = project.id
        #     [:project, 'project', "PROJECT", "prOJECt"].each do |format|
        #
        #       method_details = DataShift::MethodDictionary.find_method_detail( Milestone, format )
        #
        #       method_details.should_not be_nil
        #
        #       method_details.operator.should == 'project'
        #       method_details.operator_for(:belongs_to).should == 'project'
        #
        #       method_details.operator_for(:assignment).should be_nil
        #       method_details.operator_for(:has_many).should be_nil
        #     end
        #
        #   end
        #
        #   it "should populate required Class for belongs_to operator method details" do
        #
        #     DataShift::ModelMethodsManager.find_methods( LoaderRelease )
        #     DataShift::ModelMethodsManager.find_methods( LongAndComplexTableLinkedToVersion )
        #
        #     DataShift::MethodDictionary.build_method_details( LoaderRelease )
        #     DataShift::MethodDictionary.build_method_details( LongAndComplexTableLinkedToVersion )
        #
        #
        #     # release.project = project.id
        #     [:project, 'project', "PROJECT", "prOJECt"].each do |format|
        #
        #       method_details = DataShift::MethodDictionary.find_method_detail( LoaderRelease, format )
        #
        #       method_details.operator_class_name.should == 'Project'
        #       method_details.operator_class.should == Project
        #     end
        #
        #
        #     [:version, "Version", "verSION"].each do |format|
        #       method_details = DataShift::MethodDictionary.find_method_detail( LongAndComplexTableLinkedToVersion, format )
        #
        #       method_details.operator_type.should == :belongs_to
        #
        #       method_details.operator_class_name.should == 'Version'
        #       method_details.operator_class.should == Version
        #     end
        #   end
        #
        #   it "should populate required Class for has_one operator method details" do
        #
        #     DataShift::ModelMethodsManager.find_methods( Version )
        #     DataShift::MethodDictionary.build_method_details( Version )
        #
        #     # version.long_and_complex_table_linked_to_version = LongAndComplexTableLinkedToVersion.create()
        #
        #     [:long_and_complex_table_linked_to_version, 'LongAndComplexTableLinkedToVersion', "Long And Complex_Table_Linked To  Version", "Long_And_Complex_Table_Linked_To_Version"].each do |format|
        #       method_details = DataShift::MethodDictionary.find_method_detail( Version, format )
        #
        #       method_details.should_not be_nil
        #
        #       method_details.operator.should == 'long_and_complex_table_linked_to_version'
        #
        #       method_details.operator_type.should == :has_one
        #
        #       method_details.operator_class_name.should == 'LongAndComplexTableLinkedToVersion'
        #       method_details.operator_class.should == LongAndComplexTableLinkedToVersion
        #     end
        #   end
        #
        #   it "should return false on for?(klass) if find_operators hasn't been called for klass" do
        #     DataShift::MethodDictionary.clear
        #     DataShift::MethodDictionary::for?(Project).should == false
        #     DataShift::MethodDictionary::find_operators(Project)
        #     DataShift::MethodDictionary::for?(Project).should == true
        #
        #   end
        #
        #   it "should return false on for?(klass) if find_operators hasn't been called for klass" do
        #     DataShift::MethodDictionary.clear
        #     DataShift::MethodDictionary::for?(Project).should == false
        #   end
        #
        #   it "should find has_many operator for method details" do
        #
        #     DataShift::ModelMethodsManager.find_methods( Project )
        #
        #     DataShift::MethodDictionary.build_method_details( Project )
        #
        #     [:milestones, "Mile Stones", 'mileSTONES', 'MileStones'].each do |format|
        #
        #       method_details = DataShift::MethodDictionary.find_method_detail( Project, format )
        #
        #       method_details.class.should == DataShift::ModelMethod
        #
        #       result = 'milestones'
        #       method_details.operator.should == result
        #       method_details.operator_for(:has_many).should == result
        #
        #       method_details.operator_for(:belongs_to).should be_nil
        #       method_details.operator_for(:assignments).should be_nil
        #     end
        #
        #   end
        #
        #
        #   it "should return nil when non existent column name" do
        #
        #     DataShift::ModelMethodsManager.find_methods( Project )
        #
        #     ["On sale", 'on_sale'].each do |format|
        #       detail = DataShift::MethodDictionary.find_method_detail( Project, format )
        #
        #       detail.should be_nil
        #     end
        #   end
        #
        #
        #   it "should not by default map setter methods" do
        #     DataShift::ModelMethodsManager.find_methods( Milestone )
        #
        #     DataShift::MethodDictionary.assignments[Milestone].should_not include('title')
        #   end
        #
        #   it "should support inclusion of setter methods" do
        #
        #     Milestone.new.respond_to?('title=').should == true
        #     Milestone.new.respond_to?('milestone_setter=').should == true
        #
        #     DataShift::MethodDictionary.setters( Milestone ).should include('title=')               # delegate
        #     DataShift::MethodDictionary.setters( Milestone ).should include('milestone_setter=')    # normal method
        #   end
        #
        #   it "should support reload and  inclusion of setter methods" do
        #
        #     DataShift::ModelMethodsManager.find_methods( Project )
        #     DataShift::ModelMethodsManager.find_methods( Milestone )
        #
        #     DataShift::MethodDictionary.assignments[Milestone].should_not include('title')
        #
        #     DataShift::ModelMethodsManager.find_methods( Milestone, :reload => true, :instance_methods => true )
        #
        #     # Milestone delegates :title to Project
        #     DataShift::MethodDictionary.assignments[Milestone].should include('title')
        #     DataShift::MethodDictionary.assignments[Milestone].should include('milestone_setter')
        #   end
      end
    end
  end
end
