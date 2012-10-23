# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for MethodMapper aspect of Active Record Loader
#             MethodMapper provides the bridge between 'strings' e.g column headings
#             and a classes different types of assignment operators
#
require File.join(File.dirname(__FILE__), 'spec_helper')
  
require 'method_dictionary'

describe 'Method Dictionary' do


  include_context "ActiveRecordTestModelsConnected"
  
  include DataShift
  
  before(:each) do
    MethodDictionary.clear
  end
  
  it "should store dictionary for multiple AR models" do
    
    MethodDictionary.find_operators( Project )
    MethodDictionary.find_operators( Milestone )
    
    MethodDictionary.assignments.size.should == 2 
    MethodDictionary.has_many.size.should == 2
  end
  
  it "should populate method dictionary for a given AR model" do

    MethodDictionary.find_operators( Project )
    MethodDictionary.find_operators( Milestone )
    
    MethodDictionary.has_many.should_not be_empty
    MethodDictionary.has_many[Project].should include('milestones')

    MethodDictionary.assignments.should_not be_empty
    MethodDictionary.assignments[Project].should include('id')
    MethodDictionary.assignments[Project].should include('value_as_string')
    MethodDictionary.assignments[Project].should include('value_as_text')

    MethodDictionary.belongs_to.should_not be_empty
    MethodDictionary.belongs_to[Project].should be_empty


    MethodDictionary.column_types.should be_is_a(Hash)
    MethodDictionary.column_types.should_not be_empty
    MethodDictionary.column_types[Project].size.should == Project.columns.size


  end

  it "should populate assigment members without the equivalent association names" do

    MethodDictionary.find_operators( Project )
    
    # we should remove has-many & belongs_to from basic assignment set as they require a DB lookup
    # or a Model.create call, not a simple assignment

    MethodDictionary.assignments_for(Project).should_not include( MethodDictionary.belongs_to_for(Project) )
    MethodDictionary.assignments_for(Project).should_not include( MethodDictionary.has_many_for(Project) )
  end


  it "should populate assignment operators for method details for different forms of a column name" do

    MethodDictionary.find_operators( Project )
    MethodDictionary.find_operators( Milestone )
    
    MethodDictionary.build_method_details( Project )
    
    [:value_as_string, 'value_as_string', "VALUE as_STRING", "value as string"].each do |format|

      method_details = MethodDictionary.find_method_detail( Project, format )

      method_details.class.should == MethodDetail

      method_details.operator.should == 'value_as_string'
      method_details.operator_for(:assignment).should == 'value_as_string'
      
      method_details.operator?('value_as_string').should be_true
      method_details.operator?('blah_as_string').should be_false

      method_details.operator_for(:belongs_to).should be_nil
      method_details.operator_for(:has_many).should be_nil
    end
  end


  # Note : Not all assignments will currently have a column type, for example
  # those that are derived from a delegate_belongs_to

  it "should populate column types for assignment operators in method details" do

    MethodDictionary.find_operators( Project )
    
    MethodDictionary.build_method_details( Project )
        
    [:value_as_string, 'value_as_string', "VALUE as_STRING", "value as string"].each do |format|

      method_details = MethodDictionary.find_method_detail( Project, format )

      method_details.class.should == MethodDetail

      method_details.col_type.should_not be_nil
      method_details.col_type.name.should == 'value_as_string'
      method_details.col_type.default.should == nil
      method_details.col_type.sql_type.should include 'varchar(255)'   # db specific, sqlite
      method_details.col_type.type.should == :string
    end
  end

  it "should populate required Class for assignment operators based on column type" do

    MethodDictionary.find_operators( Project )
    
    MethodDictionary.build_method_details( Project )
        
    [:value_as_string, 'value_as_string', "VALUE as_STRING", "value as string"].each do |format|

      method_details = MethodDictionary.find_method_detail( Project, format )

      method_details.operator_class_name.should == 'String'
      method_details.operator_class.should be_is_a(Class)
      method_details.operator_class.should == String
    end

  end

  it "should populate belongs_to operator for method details for different forms of a column name" do

    MethodDictionary.find_operators( Project )
    MethodDictionary.find_operators( Milestone )
    
    MethodDictionary.build_method_details( Project )
    MethodDictionary.build_method_details( Milestone )
            
    # milestone.project = project.id
    [:project, 'project', "PROJECT", "prOJECt"].each do |format|

      method_details = MethodDictionary.find_method_detail( Milestone, format )

      method_details.should_not be_nil

      method_details.operator.should == 'project'
      method_details.operator_for(:belongs_to).should == 'project'

      method_details.operator_for(:assignment).should be_nil
      method_details.operator_for(:has_many).should be_nil
    end

  end

  it "should populate required Class for belongs_to operator method details" do

    MethodDictionary.find_operators( LoaderRelease )
    MethodDictionary.find_operators( LongAndComplexTableLinkedToVersion )

    MethodDictionary.build_method_details( LoaderRelease )
    MethodDictionary.build_method_details( LongAndComplexTableLinkedToVersion )
          
    
    # release.project = project.id
    [:project, 'project', "PROJECT", "prOJECt"].each do |format|

      method_details = MethodDictionary.find_method_detail( LoaderRelease, format )

      method_details.operator_class_name.should == 'Project'
      method_details.operator_class.should == Project
    end


    [:version, "Version", "verSION"].each do |format|
      method_details = MethodDictionary.find_method_detail( LongAndComplexTableLinkedToVersion, format )

      method_details.operator_type.should == :belongs_to

      method_details.operator_class_name.should == 'Version'
      method_details.operator_class.should == Version
    end
  end

  it "should populate required Class for has_one operator method details" do

    MethodDictionary.find_operators( Version )
    MethodDictionary.build_method_details( Version )
       
    # version.long_and_complex_table_linked_to_version = LongAndComplexTableLinkedToVersion.create()

    [:long_and_complex_table_linked_to_version, 'LongAndComplexTableLinkedToVersion', "Long And Complex_Table_Linked To  Version", "Long_And_Complex_Table_Linked_To_Version"].each do |format|
      method_details = MethodDictionary.find_method_detail( Version, format )

      method_details.should_not be_nil

      method_details.operator.should == 'long_and_complex_table_linked_to_version'
      
      method_details.operator_type.should == :has_one

      method_details.operator_class_name.should == 'LongAndComplexTableLinkedToVersion'
      method_details.operator_class.should == LongAndComplexTableLinkedToVersion
    end
  end
  
  it "should return false on for?(klass) if find_operators hasn't been called for klass" do
    MethodDictionary.clear
    MethodDictionary::for?(Project).should == false
    MethodDictionary::find_operators(Project)
    MethodDictionary::for?(Project).should == true
     
  end

  it "should return false on for?(klass) if find_operators hasn't been called for klass" do
    MethodDictionary.clear
    MethodDictionary::for?(Project).should == false
  end
  
  it "should find has_many operator for method details" do
    
    MethodDictionary.find_operators( Project )
    
    MethodDictionary.build_method_details( Project )
     
    [:milestones, "Mile Stones", 'mileSTONES', 'MileStones'].each do |format|

      method_details = MethodDictionary.find_method_detail( Project, format )

      method_details.class.should == MethodDetail
      
      result = 'milestones'
      method_details.operator.should == result
      method_details.operator_for(:has_many).should == result

      method_details.operator_for(:belongs_to).should be_nil
      method_details.operator_for(:assignments).should be_nil
    end

  end

 
  it "should return nil when non existent column name" do
    
    MethodDictionary.find_operators( Project )
    
    ["On sale", 'on_sale'].each do |format|
      detail = MethodDictionary.find_method_detail( Project, format )

      detail.should be_nil
    end
  end


  it "should find a set of methods based on a list of column names" do
    pending("key API - map column headers to set of methods")
  end

  it "should not by default map setter methods" do
    MethodDictionary.find_operators( Milestone )
    
    MethodDictionary.assignments[Milestone].should_not include('title')
  end
  
  it "should support reload and  inclusion of setter methods" do

    MethodDictionary.find_operators( Project )
    MethodDictionary.find_operators( Milestone )
    
    MethodDictionary.assignments[Milestone].should_not include('title')
        
    MethodDictionary.find_operators( Milestone, :reload => true, :instance_methods => true )
     
    # Milestone delegates :title to Project
    MethodDictionary.assignments[Milestone].should include('title')
  end

end