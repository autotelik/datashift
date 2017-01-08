# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# License::   MIT
#
#
require_relative '../../spec_helper'

module  DataShift

  describe 'Excel Loader directed by a DataFlowSchema' do

    include_context 'ClearAllCatalogues'

    let(:loader) { ExcelLoader.new }

    context 'external configuration of loader' do

      let(:expected)  { ifixture_file('ProjectsSingleCategories.xls') }

      before(:all) do
        Project.class_eval do

        end
      end

      before(:each) do

        DataShift::Transformation.factory.clear

        loader.configure_from( ifixture_file('config/ProjectConfiguration.yml'), Project)

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

          expect(p.value_as_text).to include "postfix for value_as_text"
        }
      end

      it 'should provide facility to OVER RIDE values via YAML configuration' do
        expected = DataShift::Transformation.factory.overrides_for(Project)[:value_as_double]

        Project.all.each { |p|
          # TOFIX - the scale of the DB column from migration is 4 -- can we get that dynamically ?
          expect(p.value_as_double).to be_within(0.0001).of(expected)
        }
      end

      it 'should provide facility to SUBSTITUTE values via YAML configuration' do
        expect(Project.first.value_as_text).to_not include "i only gone and got myself changed by datashift"
        expect(Project.last.value_as_text).to_not include "change me"
        expect(Project.last.value_as_text).to include "i only gone and got myself changed by datashift"
      end

      it 'should provide facility to call custom methods on nodes via YAML configuration' do
        expected = Project.first.a_custom_user_id_setter

        Project.all.each { |p| expect(p.user_id).to eq 123456789 }
      end

    end
  end
end
