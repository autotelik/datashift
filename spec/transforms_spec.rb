# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for Excel aspect of Active Record Loader
#
require File.dirname(__FILE__) + '/spec_helper'


module  DataShift

  describe 'Transforms' do

    include_context "ClearAllCatalogues"

    context 'external configuration of loader' do

      it "should provide facility to set default values", :focus => true do

        populator.set_default_value('value_as_string', 'some default text' )
        populator.set_default_value('value_as_double', 45.467 )
        populator.set_default_value('value_as_boolean', true )

        texpected = Time.now.to_s(:db)

        populator.set_default_value('value_as_datetime', texpected )
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