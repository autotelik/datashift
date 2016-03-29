# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
#
require File.dirname(__FILE__) + '/../spec_helper'

module  DataShift

  describe 'Excel Loader' do
    include_context 'ClearAllCatalogues'

    let(:loader) { ExcelLoader.new }

    let(:expected) { ifixture_file('SimpleProjects.xls') }

    context 'prepare to load' do

      it 'should be able to create a new excel loader' do
        expect(loader).to be
      end

      it 'should provide access to a context for the whole document' do
        expect(loader.doc_context).to be_a DocContext
      end

      it 'should have access to open an Excel file' do
        expect( loader.respond_to?(:start_excel)).to eq true
        expect( loader.open_excel(expected, sheet_number: 0) ).to be_a Excel
      end
    end

    context 'basic load operations' do

      before(:each) do
        create_list(:category, 5)
      end

      it 'should provide access to the file_name', duff: true do
        loader.run(expected, Project)
        expect(loader.file_name).to eq expected
      end

      it 'should parse the headers' do

        loader.run(expected, Project)
        expect(loader.headers.class).to eq Headers
        # TOFIX flakey - is it possible to read from 'SimpleProjects.xls'
        expect(loader.headers).to eq ['value_as_string',	'Value as Text', 'value as datetime', 'value_as_boolean',	'value_as_double']
        expect(loader.headers.idx).to eq 0
      end

      it 'should bind headers to real class methods' do
        loader.run(expected, Project)

        expect(loader.binder).to be

        binding = loader.binder.bindings[1]

        expect(binding.valid?).to eq true
        expect(binding.inbound_index).to eq 1
        expect(binding.inbound_name).to eq 'Value as Text'
        expect(binding.operator).to eq 'value_as_text'

        expect(Project.new.respond_to?(binding.operator)).to eq true
      end
    end

    context 'creates new records' do

      it 'should process a simple .xls spreedsheet', fail: true do
        count = Project.count

        loader.run(expected, Project)

        expect(loader.loaded_count).to eq 3
        expect(Project.count).to eq count + 3
      end

      #         it "should provide access to main subject class of the load" do
      #           expect(loader.load_object_class).to eq Project
      #         end
      #
      #         it "should provide access to main subject of the load" do
      #           expect(loader.load_object).to be_a Project
      #           expect(loader.load_object.new_record?).to eq true
      #         end

      it 'should populate database objects from a simple .xls spreedsheet' do
        loader.run(expected, Project)

        loaded = Project.last

        expect(loaded.value_as_string).to eq '003 Can handle different column naming styles'
        expect(loaded.value_as_text).to eq ''
        expect(loaded.value_as_datetime).to eq '2011-05-19'
        expect(loaded.value_as_boolean).to eq true
        expect(loaded.value_as_double).to eq 520.00
      end

      it 'should process multiple associations from single column' do
        expect(Project.find_by_title('001')).to be_nil

        count = Project.count

        expected = ifixture_file('ProjectsSingleCategories.xls')

        loader.run(expected, Project)

        expect(loader.loaded_count).to eq 4

        expect(loader.loaded_count).to eq (Project.count - count)

        { '001' => 2, '002' => 1, '003' => 3, '099' => 0 }.each do |title, expected|
          project = Project.find_by_title(title)

          expect(project).to_not be_nil

          expect(project.categories.size).to eq expected
        end
      end

      it 'should process multiple associations in excel spreadsheet' do
        count = Project.count

        expected = ifixture_file('ProjectsMultiCategories.xls')

        loader.run(expected, Project)

        expect(loader.loaded_count).to eq (Project.count - count)

        { '004' => 3, '005' => 1, '006' => 0, '007' => 1 }.each do |title, expected|
          project = Project.find_by_title(title)

          expect(project).to_not be_nil

          expect(project.categories.size).to eq expected
        end
      end

      it 'should process multiple associations with lookup specified in column from excel spreadsheet' do
        count = Project.count

        expected = ifixture_file('ProjectsMultiCategoriesHeaderLookup.xls')

        loader.run(expected, Project)

        expect(loader.loaded_count).to eq 4
        expect(Project.count).to eq count + 4

        { '004' => 4, '005' => 1, '006' => 0, '007' => 1 }.each do |title, expected|
          project = Project.find_by_title(title)

          expect(project).to_not be_nil

          expect(project.categories.size).to eq expected
        end
      end

      it 'should process excel spreedsheet with extra undefined columns' do
        expected = ifixture_file('BadAssociationName.xls')

        expect { loader.run(expected, Project) }.to_not raise_error
      end

      it 'should NOT process excel spreedsheet with extra undefined columns when strict mode' do
        expected = ifixture_file('BadAssociationName.xls')

        loader.configuration.strict = true

        expect { loader.run(expected, Project) }.to raise_error(MappingDefinitionError)
      end

      it 'should raise an error when mandatory columns missing' do
        expected = ifixture_file('ProjectsMultiCategories.xls')

        expect {

          loader.configuration.mandatory = %w(not_an_option must_be_there)

          loader.run(expected, Project)
        }.to raise_error(DataShift::MissingMandatoryError)
      end
    end

    context 'update existing records' do
    end

    context 'external configuration of loader' do
      let(:expected)  { ifixture_file('ProjectsSingleCategories.xls') }

      before(:each) do
        DataShift::Transformer.factory.clear
      end

      it 'should use global transforms to set default values', duff: true do
        texpected = Time.now.to_s(:db)

        DataShift::Transformer.factory do |factory|
          factory.set_default_on(Project, 'value_as_string', 'some default text' )
          factory.set_default_on(Project, 'value_as_double', 45.467 )
          factory.set_default_on(Project, 'value_as_boolean', true )
          factory.set_default_on(Project, 'value_as_datetime', texpected )
        end

        # value_as_string	Value as Text	value as datetime	value_as_boolean	value_as_double	category

        loader.run(expected, Project)

        p = Project.find_by_title( '099' )

        expect(p).to_not be_nil

        expect(p.value_as_string).to eq 'some default text'
        expect(p.value_as_double).to eq 45.467
        expect(p.value_as_boolean).to eq true
        expect(p.value_as_datetime.to_s(:db)).to eq texpected

        # expected: "2012-09-17 10:00:52"
        # got: Mon Sep 17 10:00:52 +0100 2012 (using ==)

        p_no_defs = Project.first

        expect(p_no_defs.value_as_string).to_not eq 'some default text'
        expect(p_no_defs.value_as_double).to_not eq 45.467
        expect(p_no_defs.value_as_datetime).to_not eq texpected
      end

      it 'should use global transforms to set pre and post fix values' do
        DataShift::Transformer.factory do |factory|
          factory.set_prefix_on(Project, 'value_as_string', 'myprefix' )
          factory.set_postfix_on(Project, 'value_as_string', 'my post fix' )
        end

        loader.run(expected, Project)

        p = Project.find_by_title( '001' )

        expect(p).to_not be_nil

        expect(p.value_as_string).to eq 'myprefixDemo stringmy post fix'
      end

      it 'should provide facility to set default values via YAML configuration', excel: true do
        pending 'fix configure_from '
        loader.configure_from( ifixture_file('ProjectsDefaults.yml') )

        loader.run(Project)

        p = Project.find_by_title( '099' )

        expect(p).to_not be_nil

        expect(p.value_as_string).to eq 'Default Project Value'
      end

      it 'should provide facility to over ride values via YAML configuration', excel: true do
        pending 'pending fix over rides - configure_from YAML '
        loader.configure_from( ifixture_file('ProjectsDefaults.yml') )

        loader.run(Project)

        Project.all.each { |p| expect(p.value_as_double).to eq 99.23546 }
      end

      it 'should provide facility to over ride values via YAML configuration', yaml: true do
        pending 'pending fix over rides - configure_from YAML '

        expect(Project.count).to eq 0

        loader.configure_from( ifixture_file('ProjectsDefaults.yml') )

        loader.run(Project)

        Project.all.each do |p|
          expect(p.value_as_double).to be_a BigDecimal
          expect(p.value_as_double).to eq 99.23546
        end
      end
    end
  end

end
