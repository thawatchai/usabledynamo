require 'spec_helper'

describe UsableDynamo::Validation, "unit test" do
  describe "presence" do
    let(:column) { double("UsableDynamo::Column") }
    let(:validation) { UsableDynamo::Validation.new(column, :presence, :if => "foo") }

    it "should have 'presence' type" do
      expect(validation.type).to eq("presence")
    end

    it "should have Presence object" do
      expect(validation.validator).to be_a_kind_of(UsableDynamo::Validation::Presence)
    end
  end
end

describe UsableDynamo::Validation, "document test" do
  before(:all) do
    ValidationTester.create_table unless ValidationTester.table_exists?
  end

  let(:record) { ValidationTester.new(first_name: "foo", last_name: "bar", age: 9, date_of_birth: Date.parse("1990-01-20")) }

  after(:all) do
    ValidationTester.drop_table
  end

  specify { expect(record).to be_valid }

  describe "when the first_name is blank" do
    before(:each) do
      record.first_name = nil
    end

    specify { expect(record).not_to be_valid }

    
  end

end