# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# License::   MIT
#
#
require File.dirname(__FILE__) + '/../spec_helper'

module  DataShift

  describe 'Excel Loader directed by a DataFlowSchema' do

    include_context 'ClearAllCatalogues'

    let(:loader) { ExcelLoader.new }

    context 'external configuration of loader' do
      let(:expected)  { ifixture_file('ProjectsSingleCategories.xls') }

      before(:each) do

        DataShift::Transformation.factory.clear

        loader.configure_from( ifixture_file('ProjectConfiguration.yml'), Project)

        expect(Project.where(title: '099').first).to be_nil

        loader.run(expected, Project)
      end

      it 'should provide facility to set DEFAULT string value via YAML configuration'  do
        p = Project.find_by_title( '099' )
        expect(p).to_not be_nil

        expect(p.value_as_string).to include "Default Project Value"
      end

      it 'should provide facility to set DEFAULT date time values via YAML configuration' do
        p = Project.find_by_title( '099' )

        # yaml has snippet to set Time to 'now' .. at least match the date part
        expect(p.value_as_datetime.to_s).to include(Date.today.to_s)
      end

      it 'should combine PREFIX and POSTFIX transformations set via YAML configuration' do
        p = Project.find_by_title( '099' )

        expect(p.value_as_string).to eq 'prefix me every-time Default Project Value postfix me every-time'

        Project.all.each { |p|
          expect(p.value_as_string).to include 'prefix me every-time '
          expect(p.value_as_string).to include 'postfix me every-time'
        }
      end

      it 'should provide facility to OVER RIDE values via YAML configuration' do
        expected = DataShift::Transformation.factory.overrides_for(Project)[:value_as_double]

        Project.all.each { |p|
          # TOFIX - the scale of the DB column from migration is 4 -- can we get that dynamically ?
          expect(p.value_as_double).to be_within(0.0001).of(expected)
        }
      end

      it 'should provide facility to call custom methods on nodes via YAML configuration', duff: true  do
        Project.all.each { |p| expect(p.user_id).to eq 123456789 }
      end

    end
  end
end
