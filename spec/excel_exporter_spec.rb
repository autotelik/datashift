# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for Excel aspect of Active Record Loader
#
require File.dirname(__FILE__) + '/spec_helper'


require 'erb'
require 'excel_exporter'

include DataShift

describe 'Excel Exporter' do

  before(:all) do

    results_clear( "exp_*.xls" )

    @klazz = Project
    @assoc_klazz = Category
  end

  before(:each) do
    MethodDictionary.clear
    MethodDictionary.find_operators( @klazz )
    MethodDictionary.find_operators( @assoc_klazz )

    db_clear()    # todo read up about proper transactional fixtures

  end

  context 'simple project' do

    before(:each) do
      create( :project )
    end

    it "should be able to create a new excel exporter" do
      generator = ExcelExporter.new( 'exp_dummy.xls' )

      generator.should_not be_nil
    end

    it "should handle bad params to export" do

      expect = result_file('project_first_export_spec.csv')

      exporter = DataShift::ExcelExporter.new( expect )

      expect{ exporter.export(nil) }.not_to raise_error

      expect{ exporter.export([]) }.not_to raise_error

      puts "Can manually check file @ #{expect}"
    end

    it "should export model object to .xls file" do

      expected = result_file('exp_project_first_export_spec.xls')

      gen = ExcelExporter.new( expected )

      gen.export(Project.all.first)

      expect(File.exists?(expected)).to eq true

      puts "Can manually check file @ #{expected}"
    end

  end

  it "should export collection of model objects to .xls file" do

    create_list(:project, 7)

    expected = result_file('exp_project_export_spec.xls')

    gen = ExcelExporter.new( expected )

    gen.export(Project.all)

    expect( File.exists?(expected)).to eq true

    excel = Excel.new
    excel.open(expected)

    expect(excel.num_rows).to eq 8

  end


  it "should export a model and associations to .xls file" do

    create( :project_user )
    create_list(:project, 7)

    expected = result_file('exp_project_plus_assoc.xls')

    gen = ExcelExporter.new(expected)

    items = Project.all

    gen.export_with_associations(Project, items)

    expect(File.exists?(expected)).to eq true

    excel = Excel.new
    excel.open(expected)

    expect(excel.row(0)).to include 'owner'
    expect(excel.row(0)).to include 'user'

    expect(excel.num_rows).to eq Project.count + 1

    user_inx = excel.row(0).index 'user'

    expect(user_inx).to be > -1

    expect( excel[1, user_inx] ).to include 'mr'

    inx = excel.row(0).index 'owner'

    expect(inx).to be > -1

    expect( excel[1, inx] ).to include '10000.23'
  end

  it "should export a model and has_many assocs to .xls file" do

    create( :project_user )
    create( :project_with_milestones )
    #create( :project_with_milestones, milestones_count: 4 )
    create_list(:project, 7)

    expected = result_file('exp_project_plus_has_many_assoc.xls')

    gen = ExcelExporter.new(expected)

    items = Project.all

    gen.export_with_associations(Project, items)

    expect(File.exists?(expected)).to eq true

    excel = Excel.new
    excel.open(expected)

    expect(excel.row(0)).to include 'owner'
    expect(excel.row(0)).to include 'user'

    expect(excel.num_rows).to eq Project.count + 1

    milestone_inx = excel.row(0).index 'milestones'

    expect(milestone_inx).to be > -1

    puts excel[2, milestone_inx].inspect

    expect( excel[2, milestone_inx].to_s ).to include Delimiters::multi_assoc_delim
    expect( excel[2, milestone_inx].to_s ).to include 'milestone 1'

  end


  it "should export a model and  assocs in json to .xls file" do

    create( :project_user )
    create( :project_with_milestones )
    #create( :project_with_milestones, milestones_count: 4 )
    create_list(:project, 7)

    expected = result_file('exp_project_plus_has_many_assoc.xls')

    gen = ExcelExporter.new(expected)

    items = Project.all

    gen.export_with_associations(Project, items, json: true)

    expect(File.exists?(expected)).to eq true

    excel = Excel.new
    excel.open(expected)

    expect(excel.num_rows).to eq Project.count + 1

    milestone_inx = excel.row(0).index 'milestones'

    puts excel[2, milestone_inx].inspect

    expect( excel[2, milestone_inx].to_s ).to include '['
    expect( excel[2, milestone_inx].to_s ).to include '"name":"milestone 1"'

  end

end
