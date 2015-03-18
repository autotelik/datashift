# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for Excel aspect of Active Record Loader
#
require File.dirname(__FILE__) + '/spec_helper'


module  DataShift

  describe 'Excel Loader' do

    include_context "ClearAllCatalogues"

    before(:each) do
      create_list(:category, 5)
    end

    it "should be able to create a new excel loader" do
      expect(ExcelLoader.new( Project)).to be
    end

    let(:loader)  { ExcelLoader.new( Project) }

    it "should provide access to a context for the whole document" do
      expect(loader.doc_context).to be_a DocContext
    end

    it "should provide access to main subject class of the load" do
      expect(loader.load_object_class).to eq Project
    end

    it "should provide access to main subject of the load" do
      expect(loader.load_object).to be_a Project
      expect(loader.load_object.new_record?).to eq true
    end

    context 'prepare to load' do

      let(:simple_xls) { ifixture_file('SimpleProjects.xls') }

      let(:loader) { ExcelLoader.new(Project) }

      it "should open an Excel file" do
        expect(loader.start(simple_xls)).to be_a Excel
      end


      it "should parse the headers", :fail => true do

        excel = loader.start(simple_xls)

        expect(loader.headers.class).to eq Headers
                                      # TOFIX flakey - is it possible to read from 'SimpleProjects.xls'
        expect(loader.headers).to eq ['value_as_string',	'Value as Text','value as datetime','value_as_boolean',	'value_as_double']
        expect(loader.headers.idx).to eq 0
      end

      it "should bind headers to real class methods" do

        loader.start(simple_xls)

        expect(loader.binder).to be

        binding = loader.binder.bindings[1]

        expect(binding.valid?).to eq true
        expect(binding.inbound_index).to eq  1
        expect(binding.inbound_name).to eq  'Value as Text'
        expect(binding.operator).to eq 'value_as_text'

        expect(Project.new.respond_to?(binding.operator)).to eq true

      end

    end

    context 'creates new records' do

      let(:simple_xls) { ifixture_file('SimpleProjects.xls') }

      let(:loader)  { ExcelLoader.new( Project) }

      it "should process a simple .xls spreedsheet"  do
        count = Project.count

        loader.perform_load(simple_xls)

        expect(loader.loaded_count).to eq 3
        expect(Project.count).to eq count + 3
      end


      it "should populate database objects from a simple .xls spreedsheet", :fail => true  do

        loader.perform_load(simple_xls)

        loaded = Project.last

        puts Project.last.inspect

        expect(loaded.value_as_string).to eq '003 Can handle different column naming styles'
        expect(loaded.value_as_text).to eq ""
        expect(loaded.value_as_datetime).to eq '2011-05-19'
        expect(loaded.value_as_boolean).to eq true
        expect(loaded.value_as_double).to eq 520.00
      end


      it "should process multiple associations from single column" do

        expect(Project.find_by_title('001')).to be_nil

        count = Project.count

        loader.perform_load( ifixture_file('ProjectsSingleCategories.xls') )

        expect(loader.loaded_count).to eq 4

        loader.loaded_count.should == (Project.count - count)

        {'001' => 2, '002' => 1, '003' => 3, '099' => 0 }.each do|title, expected|
          project = Project.find_by_title(title)

          expect(project).to_not be_nil

          expect(project.categories.size).to eq expected
        end
      end

      it "should process multiple associations in excel spreadsheet" do

        count = Project.count
        loader.perform_load( ifixture_file('ProjectsMultiCategories.xls' ))

        expect(loader.loaded_count).to eq (Project.count - count)

        {'004' => 3, '005' => 1, '006' => 0, '007' => 1 }.each do|title, expected|
          project = Project.find_by_title(title)

          project.should_not be_nil

          expect(project.categories.size).to eq expected
        end

      end

      it "should process multiple associations with lookup specified in column from excel spreadsheet" do

        count = Project.count
        loader.perform_load( ifixture_file('ProjectsMultiCategoriesHeaderLookup.xls'))

        expect(loader.loaded_count).to eq 4
        expect(Project.count).to eq count + 4

        {'004' => 4, '005' => 1, '006' => 0, '007' => 1 }.each do|title, expected|
          project = Project.find_by_title(title)

          expect(project).to_not be_nil

          expect(project.categories.size).to eq expected
        end

      end

      it "should process excel spreedsheet with extra undefined columns" do
        lambda {loader.perform_load( ifixture_file('BadAssociationName.xls') ) }.should_not raise_error
      end

      it "should NOT process excel spreedsheet with extra undefined columns when strict mode" do
        expect {loader.perform_load( ifixture_file('BadAssociationName.xls'), :strict => true)}.to raise_error(MappingDefinitionError)
      end

      it "should raise an error when mandatory columns missing" do
        expect {loader.perform_load(ifixture_file('ProjectsMultiCategories.xls'), :mandatory => ['not_an_option', 'must_be_there'])}.to raise_error(DataShift::MissingMandatoryError)
      end

    end

    context 'update existing records' do
    end

    context 'external configuration of loader' do

      it "should provide facility to set default values", :focus => true do

        DataShift::Transformer.factory do |factory|
          factory.set_default_on(Project, 'value_as_string', 'some default text' )
          factory.set_default_value('value_as_double', 45.467 )
          factory.set_default_value('value_as_boolean', true )

          texpected = Time.now.to_s(:db)

          factory.set_default_value('value_as_datetime', texpected )
        end

        #value_as_string	Value as Text	value as datetime	value_as_boolean	value_as_double	category

        loader.perform_load(ifixture_file('ProjectsSingleCategories.xls'))

        p = Project.find_by_title( '099' )

        p.should_not be_nil

        p.value_as_string.should == 'some default text'
        p.value_as_double.should == 45.467
        p.value_as_boolean.should == true
        p.value_as_datetime.to_s(:db).should == texpected

        # expected: "2012-09-17 10:00:52"
        # got: Mon Sep 17 10:00:52 +0100 2012 (using ==)

        p_no_defs = Project.first

        p_no_defs.value_as_string.should_not == 'some default text'
        p_no_defs.value_as_double.should_not == 45.467
        p_no_defs.value_as_datetime.should_not == texpected

      end

      it "should provide facility to set pre and post fix values" do
        loader = ExcelLoader.new(Project)

        loader.populator.set_prefix('value_as_string', 'myprefix' )
        loader.populator.set_postfix('value_as_string', 'my post fix' )

        #value_as_string	Value as Text	value as datetime	value_as_boolean	value_as_double	category

        loader.perform_load( ifixture_file('ProjectsSingleCategories.xls'))

        p = Project.find_by_title( '001' )

        p.should_not be_nil

        p.value_as_string.should == 'myprefixDemo stringmy post fix'
      end

      it "should provide facility to set default values via YAML configuration", :excel => true do
        loader = ExcelLoader.new(Project)

        loader.configure_from( ifixture_file('ProjectsDefaults.yml') )


        loader.perform_load( ifixture_file('ProjectsSingleCategories.xls') )

        p = Project.find_by_title( '099' )

        p.should_not be_nil

        p.value_as_string.should == "Default Project Value"
      end


      it "should provide facility to over ride values via YAML configuration", :excel => true do
        loader = ExcelLoader.new(Project)

        loader.configure_from( ifixture_file('ProjectsDefaults.yml') )

        loader.perform_load( ifixture_file('ProjectsSingleCategories.xls') )

        Project.all.each {|p| p.value_as_double.should == 99.23546 }
      end


      it "should provide facility to over ride values via YAML configuration", :yaml => true do
        loader = ExcelLoader.new(Project)

        expect(Project.count).to eq 0

        loader.configure_from( ifixture_file('ProjectsDefaults.yml') )


        loader.perform_load( ifixture_file('ProjectsSingleCategories.xls') )

        Project.all.each do |p|
          expect(p.value_as_double).to be_a BigDecimal
          expect(p.value_as_double).to eq 99.23546
        end
      end


    end

  end

end