require File.dirname(__FILE__) + '/../spec_helper'

module DataShift

  RSpec.describe DataFlowSchema, type: :model do

    let(:data_flow_schema) { subject }

    let(:yaml_text) {
      x=<<-EOS
      data_flow_schema:
        nodes:
          - project_title:
              heading:
                source: "title"
                destination: "Title"
              operator: title
          - project_owner_budget:
              heading:
                destination: "Budget"
              operator: owner.budget
      EOS
      x
    }
=begin
  context "Helper ReviewDataSection" do
    let(:review_data_section) {  DataShift::ReviewDataSection.new("heading") }


    it "supports adding multiple rows and returns row created" do
      expect(review_data_section.add("title", "data", "state_to_link_to", "dummy"))
        .to be_instance_of Struct::ReviewDataRow

      expect(review_data_section.rows).to be_instance_of Array
    end

    it "link target supports :none for empty target columns" do
      row = review_data_section.add("title", "data", :none, "dummy")

      expect(row.target(enrollment)).to be_nil
    end

    it "view helper for target handles :none for empty target columns" do
      class Blah
        include WasteExemptionsShared::EnrollmentsHelper
      end

      expect(
        Blah.new.link_to_reviewing_change_this(enrollment, review_data_section.add("title", "data", :none, "dummy")
                                              )).to be_nil
    end
  end
=end
    context "DataFlowSchema" do

      context("YAML (LOCALE) DSL") do

        it "build node collection from a locale based DSL" do

          collection = data_flow_schema.prepare_from_string(yaml_text)

          expect(collection).to be_instance_of NodeCollection
          expect(collection.size).to eq 2
        end

        it "each section is an instance of Node" do
          collection = data_flow_schema.prepare_from_string(yaml_text)
          expect(collection.first).to be_instance_of DataShift::Node
        end
=begin
      it "each section can contain multiple investigatable rows" do
        section = review_data_sections.first

        expect(section.rows).to be_instance_of Array

        # delegators
        expect(section.rows.size).to eq section.size
        expect(section.rows.empty?).to eq section.empty?
      end

      it "each row contains columns required to build view" do
        review_data_column = review_data_sections.first.rows.first

        expect(review_data_column).to be_instance_of Struct::ReviewDataRow

        expect(review_data_column.title).to be_instance_of String
        expect(review_data_column.link_state).to be_instance_of String
      end

      context("Specific YAML") do
        include_examples "clear_and_after_reload_yaml"

        it "can access methods directly on the model" do
          I18n.backend.store_translations(:en, YAML.load(simple_review_farming_yaml))

          expect(I18n.exists?("enrollment_review")).to eq true

          review_data_list = enrollment_review.prepare_from_locale(enrollment)

          expect(review_data_list.size).to eq 1

          review_data_section = review_data_list.first

          expect(review_data_section.heading).to eq "Farming data"
          expect(review_data_section.rows.size).to eq 2

          row = review_data_section.rows.first

          expect(row).to be_instance_of Struct::ReviewDataRow
          expect(row.data).to eq enrollment.on_a_farm?
        end

        it "can access methods on an association of the model", fail: true do
          I18n.backend.store_translations(:en, YAML.load(direct_and_association_review_yaml))

          expect(I18n.exists?("enrollment_review")).to eq true

          review_data_list = enrollment_review.prepare_review_data_list

          expect(review_data_list.size).to eq 2 # 2 sections
          review_data_section = review_data_list.last

          expect(review_data_section.heading).to eq "Waste Exemption Codes"
          expect(review_data_section.rows.size).to eq enrollment.exemptions.count

          row = review_data_section.rows.first

          expect(row).to be_instance_of Struct::ReviewDataRow

          expect(row.data).to eq enrollment.exemptions.first.code
          expect(row.link_state).to eq "bad_link"

          expect(row.target(enrollment)).to include "/reviews/"
          expect(row.target(enrollment)).to include "/bad_link/"
          expect(row.target(enrollment)).to include enrollment.id.to_s
        end

        context("association and method chaining") do
          before(:each) do
            I18n.backend.store_translations(:en, YAML.load(chained_review_yaml))
          end

          let(:review_data_list) { enrollment_review.prepare_review_data_list }

          it "can access associated object down the whole association chain on model" do
            expect(review_data_list.size).to eq 2
            organisation_address_section = review_data_list.first

            row = organisation_address_section.rows.first

            expect(row.data).to eq enrollment.organisation.contact.email_address
          end

          it "can access methods down the whole association chain on model" do
            expect(review_data_list.size).to eq 2
            applicant_contact_section = review_data_list.last

            row = applicant_contact_section.rows.first

            expect(row.data).to eq enrollment.applicant_contact.business_number.tel_number
          end
        end
      end
    end
=end
      end
    end
  end
end
