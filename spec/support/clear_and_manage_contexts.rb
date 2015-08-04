# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#

RSpec.configure do |_config|
  shared_context 'ClearAllCatalogues' do
    before(:each) do
      DataShift::ModelMethods::Catalogue.clear
      DataShift::ModelMethods::Manager.clear
    end
  end

  shared_context 'ClearThenManageProject' do
    before(:each) do
      DataShift::ModelMethods::Catalogue.clear
      DataShift::ModelMethods::Manager.clear
    end

    # A ModelMethods::Collection for Project
    let(:project_collection)  { DataShift::ModelMethods::Manager.catalog_class( Project ) }

    let(:project_headers)     { [:value_as_string, :owner, :value_as_boolean, :value_as_double] }
  end
end
