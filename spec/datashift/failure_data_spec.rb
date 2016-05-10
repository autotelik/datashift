# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# License::   MIT
#
require File.join(File.dirname(__FILE__), '/../spec_helper')

module DataShift

  describe FailureData do

    include_context 'ClearThenManageProject'

    let(:load_object)     { create(:project, title: 'my title') }

    let(:model_method)    { project_collection.search('value_as_string') }

    let(:method_binding)  { MethodBinding.new('value_as_string', 1, model_method) }

    let(:node_context) { DataShift::NodeContext.new(self, method_binding, 1, "1,2,3") }

    it 'should store details of load object and inbound context' do
      failed = FailureData.new(load_object, node_context)
      expect(failed).to be
    end

  end
end
