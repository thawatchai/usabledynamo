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
  let(:record) { ValidationTester.new(first_name: "foo", last_name: "bar", email: "foo@bar.com", age: 9, date_of_birth: DateTime.parse("1990-01-20")) }

  before(:all) do
    ValidationTester.create_table unless ValidationTester.table_exists?
  end

  before(:each) do
    ValidationTester.all.each(&:destroy)
  end

  after(:all) do
    ValidationTester.drop_table
  end

  specify { expect(record).to be_valid }

  describe "when the first_name is blank" do
    before(:each) do
      record.first_name = nil
    end

    specify { expect(record).not_to be_valid }

    it "should have the blank error for first_name" do
      record.valid?
      expect(record.errors[:first_name]).to include(I18n.t("errors.messages.blank"))
    end
  end

  describe "when the last_name is blank" do
    before(:each) do
      record.last_name = nil
    end

    specify { expect(record).not_to be_valid }

    it "should have the blank error for last_name" do
      record.valid?
      expect(record.errors[:last_name]).to include(I18n.t("errors.messages.blank"))
    end
  end

  describe "when the date_of_birth is blank" do
    before(:each) do
      record.date_of_birth = nil
    end

    specify { expect(record).not_to be_valid }

    it "should have the blank error for date_of_birth" do
      record.valid?
      expect(record.errors[:date_of_birth]).to include(I18n.t("errors.messages.blank"))
    end
  end

  describe "when the weight is blank" do
    before(:each) do
      record.weight = nil
    end

    specify { expect(record).to be_valid }

    describe "when the age is more than 10" do
      before(:each) do
        record.age = 11
      end
      
      it "should have the blank error for weight" do
        record.valid?
        expect(record.errors[:weight]).to include(I18n.t("errors.messages.blank"))
      end
    end
  end

  describe "when the height is blank" do
    before(:each) do
      record.height = nil
    end

    specify { expect(record).to be_valid }

    describe "when the age is more than or equal to 20" do
      before(:each) do
        record.age = 20
      end
      
      it "should have the blank error for height" do
        record.valid?
        expect(record.errors[:height]).to include(I18n.t("errors.messages.blank"))
      end
    end
  end

  describe "when weight is more than 300" do
    before(:each) do
      record.weight = 301
    end

    specify { expect(record).not_to be_valid }

    it "should have the error for weight" do
      record.valid?
      expect(record.errors[:weight]).to include("weight should be less than 300 kg")
    end
  end

  describe "when height is more than 300" do
    before(:each) do
      record.height = 301
    end

    specify { expect(record).to be_valid }

    describe "when in update mode" do
      before(:each) do
        record.height = 200
        record.save!
        record.height = 301
      end

      it "should have the error for height" do
        record.valid?
        expect(record.errors[:height]).to include("height should be less than 300 cm")
      end
    end
  end

  describe "when age is more than 200" do
    before(:each) do
      record.age = 201
    end

    specify { expect(record).not_to be_valid }

    it "should have the error for age" do
      record.valid?
      expect(record.errors[:age]).to include("age should be less than 200")
    end
  end

  describe "when there's another record with same email" do
    let!(:another_record) { ValidationTester.create!(first_name: "food", last_name: "bars", email: "foo@bar.com", age: 9, date_of_birth: DateTime.parse("1990-01-20")) }

    specify { expect(record).not_to be_valid }

    it "should have the uniqueness error for email" do
      record.valid?
      expect(record.errors[:email]).to include(I18n.t("errors.messages.taken"))
    end

    describe "when email is blank" do
      before(:each) do
        record.email = nil
      end

      specify { expect(record).to be_valid }
    end
  end

  describe "when there's another record with same first_name and last_name" do
    let!(:another_record) { ValidationTester.create!(first_name: "foo", last_name: "bar", email: "food@bars.com", age: 9, date_of_birth: DateTime.parse("1990-01-20")) }

    specify { expect(record).not_to be_valid }

    it "should have the uniqueness error for last_name" do
      record.valid?
      expect(record.errors[:last_name]).to include(I18n.t("errors.messages.taken"))
    end

    describe "when last_name is blank" do
      before(:each) do
        record.last_name = nil
      end

      it "should not have the uniqueness error for last_name" do
        record.valid?
        expect(record.errors[:last_name]).not_to include(I18n.t("errors.messages.taken"))
      end
    end

    describe "when first_name is blank" do
      before(:each) do
        record.first_name = nil
      end

      it "should not have the uniqueness error for last_name" do
        record.valid?
        expect(record.errors[:last_name]).not_to include(I18n.t("errors.messages.taken"))
      end
    end
  end
end