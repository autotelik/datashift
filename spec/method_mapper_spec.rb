# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for MethodMapper aspect of Active Record Loader
#             MethodMapper provides the bridge between 'strings' e.g column headings
#             and a classes different types of assignment operators
#
require File.dirname(__FILE__) + '/spec_helper'

describe 'Method Mapping' do

  before(:all) do
    db_connect( 'test_file' )    # , test_memory, test_mysql
    migrate_up
    @klazz = Project
    @assoc_klazz = Milestone
  end
  
  before(:each) do
    MethodMapper.clear
    MethodMapper.find_operators( @klazz )
    MethodMapper.find_operators( @assoc_klazz )
  end
  
  it "should populate method map for a given AR model" do

    MethodMapper.has_many.should_not be_empty
    MethodMapper.has_many[Project].should include('milestones')

    MethodMapper.assignments.should_not be_empty
    MethodMapper.assignments[Project].should include('id')
    MethodMapper.assignments[Project].should include('value_as_string')
    MethodMapper.assignments[Project].should include('value_as_text')

    MethodMapper.belongs_to.should_not be_empty
    MethodMapper.belongs_to[Project].should be_empty


    MethodMapper.column_types.should be_is_a(Hash)
    MethodMapper.column_types.should_not be_empty
    MethodMapper.column_types[Project].size.should == Project.columns.size


  end

  it "should populate assigment members without the equivalent association names" do

    # we should remove has-many & belongs_to from basic assignment set as they require a DB lookup
    # or a Model.create call, not a simple assignment

    MethodMapper.assignments_for(@klazz).should_not include( MethodMapper.belongs_to_for(@klazz) )
    MethodMapper.assignments_for(@klazz).should_not include( MethodMapper.has_many_for(@klazz) )
  end


  it "should populate assignment operators for method details for different forms of a column name" do

    [:value_as_string, 'value_as_string', "VALUE as_STRING", "value as string"].each do |format|

      method_details = MethodMapper.find_method_detail( @klazz, format )

      method_details.class.should == MethodDetail

      method_details.name.should eq( format.to_s )

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

    [:value_as_string, 'value_as_string', "VALUE as_STRING", "value as string"].each do |format|

      method_details = MethodMapper.find_method_detail( @klazz, format )

      method_details.class.should == MethodDetail

      method_details.col_type.should_not be_nil
      method_details.col_type.name.should == 'value_as_string'
      method_details.col_type.default.should == nil
      method_details.col_type.sql_type.should include 'varchar(255)'   # db specific, sqlite
      method_details.col_type.type.should == :string
    end
  end

  it "should populate required Class for assignment operators based on column type" do

    [:value_as_string, 'value_as_string', "VALUE as_STRING", "value as string"].each do |format|

      method_details = MethodMapper.find_method_detail( Project, format )

      method_details.operator_class_name.should == 'String'
      method_details.operator_class.should be_is_a(Class)
      method_details.operator_class.should == String
    end

  end

  it "should populate belongs_to operator for method details for different forms of a column name" do

    # milestone.project = project.id
    [:project, 'project', "PROJECT", "prOJECt"].each do |format|

      method_details = MethodMapper.find_method_detail( Milestone, format )

      method_details.should_not be_nil

      method_details.operator.should == 'project'
      method_details.operator_for(:belongs_to).should == 'project'

      method_details.operator_for(:assignment).should be_nil
      method_details.operator_for(:has_many).should be_nil
    end

  end

  it "should populate required Class for belongs_to operator method details" do

    MethodMapper.find_operators( LoaderRelease )
    MethodMapper.find_operators( LongAndComplexTableLinkedToVersion )

    # release.project = project.id
    [:project, 'project', "PROJECT", "prOJECt"].each do |format|

      method_details = MethodMapper.find_method_detail( LoaderRelease, format )

      method_details.operator_class_name.should == 'Project'
      method_details.operator_class.should == Project
    end


    #LongAndComplexTableLinkedToVersion.version = version.id

    [:version, "Version", "verSION"].each do |format|
      method_details = MethodMapper.find_method_detail( LongAndComplexTableLinkedToVersion, format )

      method_details.operator_type.should == :belongs_to

      method_details.operator_class_name.should == 'Version'
      method_details.operator_class.should == Version
    end
  end

   it "should populate required Class for has_one operator method details" do

    MethodMapper.find_operators( Version )

    # version.long_and_complex_table_linked_to_version = LongAndComplexTableLinkedToVersion.create()

    [:long_and_complex_table_linked_to_version, 'LongAndComplexTableLinkedToVersion', "Long And Complex_Table_Linked To  Version", "Long_And_Complex_Table_Linked_To_Version"].each do |format|
      method_details = MethodMapper.find_method_detail( Version, format )

      method_details.should_not be_nil

      method_details.operator.should == 'long_and_complex_table_linked_to_version'
      
      method_details.operator_type.should == :has_one

      method_details.operator_class_name.should == 'LongAndComplexTableLinkedToVersion'
      method_details.operator_class.should == LongAndComplexTableLinkedToVersion
    end
  end


  it "should find has_many operator for method details" do

    [:milestones, "Mile Stones", 'mileSTONES', 'MileStones'].each do |format|

      method_details = MethodMapper.find_method_detail( Project, format )

      method_details.class.should == MethodDetail
      
      result = 'milestones'
      method_details.operator.should == result
      method_details.operator_for(:has_many).should == result

      method_details.operator_for(:belongs_to).should be_nil
      method_details.operator_for(:assignments).should be_nil
    end

  end

 
  it "should return nil when non existent column name" do
    ["On sale", 'on_sale'].each do |format|
      detail = MethodMapper.find_method_detail( @klazz, format )

      detail.should be_nil
    end
  end


  it "should find a set of methods based on a list of column names" do

    mapper = MethodMapper.new

    [:value_as_string, 'value_as_string', "VALUE as_STRING", "value as string"].each do |column_name_format|

      method_details = MethodMapper.find_method_detail( @klazz, column_name_format )

      method_details.class.should == MethodDetail

      method_details.col_type.should_not be_nil
      method_details.col_type.name.should == 'value_as_string'
      method_details.col_type.default.should == nil
      method_details.col_type.sql_type.should include 'varchar(255)'   # db specific, sqlite
      method_details.col_type.type.should == :string
    end
  end

  it "should not by default map setter methods", :fail => true do
    MethodMapper.assignments[Milestone].should_not include('title')
  end
  
  it "should support reload and  inclusion of setter methods", :fail => true do

    MethodMapper.assignments[Milestone].should_not include('title')
        
    MethodMapper.find_operators( Milestone, :reload => true, :instance_methods => true )
     
    # Milestone delegates :title to Project
    MethodMapper.assignments[Milestone].should include('title')
  end

end