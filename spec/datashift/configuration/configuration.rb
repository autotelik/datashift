# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for base class Loader
#
require_relative '../../spec_helper'

module DataShift

  describe Configuration do

    let(:defaults) do
      { project:
          { value_as_string: 'Default Project Value',
            category: 'reference:category_002',
            value_as_datetime: Time.now.to_s(:db)
          }
      }
    end

    before do
    end

    let(:call) { DataShift::Exporters::Configuration.call }

    context "with" do

      it 'defaults to basic attribute data' do
        expect(call.op_types_in_scope).to eq [:assignment, :enum]
      end

      it 'returns complete list of op types when [:all] specified' do
        DataShift::Exporters::Configuration.configure do |config|
          config.with = [:all]
        end
        expect(call.op_types_in_scope).to eq ModelMethod.supported_types_enum
      end

      it 'returns complete list of op types when :all specified' do
        DataShift::Exporters::Configuration.configure do |config|
          config.with = :all
        end
        expect(call.op_types_in_scope).to eq ModelMethod.supported_types_enum
      end

      it 'can be configuresd  complete list of op types when :all specified' do
        DataShift::Exporters::Configuration.configure do |config|
          config.with = :all
        end
        expect(call.op_types_in_scope).to eq ModelMethod.supported_types_enum
      end

      it 'can be configured  with custom list of op types to process' do
        DataShift::Exporters::Configuration.configure do |config|
          config.with = [:assignment, :enum, :belongs_to]
        end
        expect(call.op_types_in_scope).to eq [:assignment, :enum, :belongs_to]
      end


    end
  end

end
