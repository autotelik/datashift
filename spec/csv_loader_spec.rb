# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for CSV aspect of Active Record Loader
#
require File.dirname(__FILE__) + '/spec_helper'

module  DataShift

  describe 'Csv Loader' do

    include_context "ClearAllCatalogues"

    context 'prepare to load' do

      let(:simple_csv) { ifixture_file('csv/SimpleProjects.csv') }

      it "should be able to create a new excel loader" do
        expect(CsvLoader.new( simple_csv)).to be
      end

      let(:loader)  { CsvLoader.new( simple_csv) }

      it "should provide access to a context for the whole document" do
        expect(loader.doc_context).to be_a DocContext
      end

      it "should provide access to the filename" do
        expect(loader.file_name).to eq simple_csv
      end
    end

    context 'basic load operations' do

      before(:each) do
        create_list(:category, 5)
      end

      let(:simple_csv) { ifixture_file('csv/SimpleProjects.csv') }

      let(:loader) { CsvLoader.new(simple_csv) }

      it "should process a simple .csv spreedsheet" do

        loader.run(Project)

        expect(loader.headers.class).to eq Headers
        # TOFIX flakey - use CSV to read from SimpleProjects.csv
        expect(loader.headers).to eq ['value_as_string',	'Value as Text','value as datetime','value_as_boolean',	'value_as_double']
        expect(loader.headers.idx).to eq 0
      end


      it "should process multiple associations from single column", :fail => true do

        expect(Project.find_by_title('001')).to be_nil
        count = Project.count

        loader = CsvLoader.new( ifixture_file('csv/ProjectsSingleCategories.csv'))

        loader.run(Project)

        expect(loader.loaded_count).to eq  3
        expect(loader.loaded_count).to eq (Project.count - count)

        {'001' => 2, '002' => 1, '003' => 3, '099' => 0 }.each do|title, expected|
          project = Project.where(title: title).first

          expect(project).to_not be_nil
          expect(project.categories.size).to eq expected
        end
      end

      it "should process multiple associations in csv file" do

        loader = CsvLoader.new(ifixture_file('csv/ProjectsMultiCategories.csv' ))

        count = Project.count
        loader.run(Project)

        loader.loaded_count.should == (Project.count - count)

        {'004' => 3, '005' => 1, '006' => 0, '007' => 1 }.each do|title, expected|
          project = Project.where(title: title)

          project.should_not be_nil

          expect(project.categories.size).to eq expected
        end

      end

      it "should process multiple associations with lookup specified in column from excel spreedsheet" do

        loader = CsvLoader.new(ifixture_file('csv/ProjectsMultiCategoriesHeaderLookup.csv'))

        count = Project.count
        loader.run(Project)

        expect(loader.loaded_count).to eq (Project.count - count)
        loader.loaded_count.should > 3

        {'004' => 4, '005' => 1, '006' => 0, '007' => 1 }.each do|title, expected|
          project = Project.where(title: title)

          project.should_not be_nil

          expect(project.categories.size).to eq expected
        end

      end

      it "should process excel spreedsheet with extra undefined columns" do
        loader = CsvLoader.new(ifixture_file('csv/BadAssociationName.csv') )
        lambda { loader.loader.run(Project) }.should_not raise_error
      end

      it "should NOT process excel spreedsheet with extra undefined columns when strict mode" do
        loader = CsvLoader.new( ifixture_file('csv/BadAssociationName.csv'), :strict => true)
        expect {loader.loader.run(Project) }.to raise_error(MappingDefinitionError)
      end

      it "should raise an error when mandatory columns missing" do
        loader = CsvLoader.new(ifixture_file('csv/ProjectsMultiCategories.csv'), :mandatory => ['not_an_option', 'must_be_there'])
        expect {loader.loader.run(Project)}.to raise_error(DataShift::MissingMandatoryError)
      end

      it "should provide facility to set default values", :focus => true do
        loader = CsvLoader.new(ifixture_file('csv/ProjectsSingleCategories.csv'))

        populator = loader.populator

        populator.set_default_value('value_as_string', 'some default text' )
        populator.set_default_value('value_as_double', 45.467 )
        populator.set_default_value('value_as_boolean', true )

        texpected = Time.now.to_s(:db)

        populator.set_default_value('value_as_datetime', texpected )

        #value_as_string	Value as Text	value as datetime	value_as_boolean	value_as_double	category

        loader.run(Project)

        p = Project.where(title: '099' )

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
        loader = CsvLoader.new(ifixture_file('csv/ProjectsSingleCategories.csv'))

        loader.populator.set_prefix('value_as_string', 'myprefix' )
        loader.populator.set_postfix('value_as_string', 'my post fix' )

        #value_as_string	Value as Text	value as datetime	value_as_boolean	value_as_double	category

        loader.run(Project)

        p = Project.where(title: '001' )

        p.should_not be_nil

        p.value_as_string.should == 'myprefixDemo stringmy post fix'
      end

      it "should provide facility to set default values via YAML configuration" do
        loader = CsvLoader.new(ifixture_file('csv/ProjectsSingleCategories.csv'))

        loader.configure_from( ifixture_file('ProjectsDefaults.yml') )

        loader.run(Project)

        p = Project.where(title: '099' )

        p.should_not be_nil

        p.value_as_string.should == "Default Project Value"
      end


      it "should provide facility to over ride values via YAML configuration" do
        loader = CsvLoader.new(ifixture_file('csv/ProjectsSingleCategories.csv'))

        loader.configure_from( ifixture_file('ProjectsDefaults.yml') )

        loader.run(Project)

        Project.all.each {|p| expect(p.value_as_double).to eq 99.23546 }
      end

    end
  end
end
