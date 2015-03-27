require 'spec_helper'

describe UsableDynamo::Callback, "document test" do
  let(:record) { CallbackTester.new(date_of_birth: DateTime.parse("2000-1-1")) }

  before(:all) do
    CallbackTester.create_table unless CallbackTester.table_exists?
  end

  before(:each) do
    CallbackTester.all.each(&:destroy)
  end

  after(:all) do
    CallbackTester.drop_table
  end

  describe "after find callback" do
    before(:each) do
      record.save!
    end

    specify { expect(record.avatar).to be_nil }
    specify { expect(record).to be_persisted }

    it "should assign the id and created_at after saved" do
      expect(record.id).not_to be_blank
      expect(record.created_at).not_to be_blank
    end

    it "assign the avatar after record is found" do
      new_record = CallbackTester.find_by(id: record.id, created_at: record.created_at)
      expect(new_record).not_to be_nil
      expect(new_record.avatar).to eq("sorry")
    end
  end

  describe "before and validation callbacks" do
    it "should execute the before validation on :create" do
      record.valid?
      expect(record.first_name).to eq("foo")
    end

    it "should execute the before validation on :save" do
      record.valid?
      expect(record.last_name).to eq("mudd")
    end

    it "should not execute the before validation on :update" do
      record.valid?
      expect(record.weight).to be_nil
    end

    it "should execute the after validation on :create" do
      record.valid?
      expect(record.email).to eq("foo@bar.com")
    end

    it "should execute the after validation on :save" do
      record.valid?
      expect(record.age).to eq(666)
    end

    it "should not execute the after validation on :update" do
      record.valid?
      expect(record.height).to be_nil
    end

    describe "when validation failed" do
      before(:each) do
        record.date_of_birth = nil
      end

      it "should execute the before validation on :create" do
        record.valid?
        expect(record.first_name).to eq("foo")
      end

      it "should execute the before validation on :save" do
        record.valid?
        expect(record.last_name).to eq("mudd")
      end

      it "should not execute the before validation on :update" do
        record.valid?
        expect(record.weight).to be_nil
      end

      it "should not execute the after validation on :create" do
        record.valid?
        expect(record.email).to be_nil
      end

      it "should not execute the after validation on :save" do
        record.valid?
        expect(record.age).to be_nil
      end

      it "should not execute the after validation on :update" do
        record.valid?
        expect(record.height).to be_nil
      end
    end

    describe "when record is updated" do
      before(:each) do
        record.save!
        record.first_name = nil
        record.email      = nil
      end

      it "should not execute the before validation on :create" do
        record.valid?
        expect(record.first_name).to be_nil
      end

      it "should execute the before validation on :save" do
        record.valid?
        expect(record.last_name).to eq("mudd")
      end

      it "should execute the before validation on :update" do
        record.valid?
        expect(record.weight).to eq(100)
      end

      it "should not execute the after validation on :create" do
        record.valid?
        expect(record.email).to be_nil
      end

      it "should execute the after validation on :save" do
        record.valid?
        expect(record.age).to eq(666)
      end

      it "should execute the after validation on :update" do
        record.valid?
        expect(record.height).to eq(50)
      end

      describe "when validation failed" do
        before(:each) do
          record.date_of_birth = nil
          record.age = nil
        end

        it "should not execute the before validation on :create" do
          record.valid?
          expect(record.first_name).to be_nil
        end

        it "should execute the before validation on :save" do
          record.valid?
          expect(record.last_name).to eq("mudd")
        end

        it "should execute the before validation on :update" do
          record.valid?
          expect(record.weight).to eq(100)
        end

        it "should not execute the after validation on :create" do
          record.valid?
          expect(record.email).to be_nil
        end

        it "should not execute the after validation on :save" do
          record.valid?
          expect(record.age).to be_nil
        end

        it "should not execute the after validation on :update" do
          record.valid?
          expect(record.height).to be_nil
        end
      end
    end
  end

  describe "before and after callbacks happy path" do
    it "should save the record" do
      expect(record.save).to eq(true)
      expect(record).to be_persisted
    end

    it "assign necessary attributes when created" do
      record.save!
      expect(record.disabled).to eq(true)
      expect(record.latitude).to eq(555)
      expect(record.longitude).to eq(777)
      expect(record.date_of_birth).to eq(DateTime.parse("1999-02-02"))
    end

    describe "when updating" do
      before(:each) do
        record.save!
      end

      it "assign necessary attributes when updated" do
        record.save!
        expect(record.disabled).to eq(true)
        expect(record.latitude).to eq(555)
        expect(record.longitude).to eq(888)
        expect(record.date_of_birth).to eq(DateTime.parse("1999-01-01"))
      end
    end

    describe "updating boolean" do
      before(:each) do
        record.disabled = false
      end

      it "should set the correct value because of before_save callback" do
        record.save!
        expect(record.disabled).to eq(true)
      end
    end
  end

  describe "before save callbacks' conditions" do
    before(:each) do
      record.avatar = "cope"
    end

    it "should not save the record" do
      expect(record.save).to eq(false)
      expect(record).not_to be_persisted
    end

    it "should not assign the disabled" do
      record.save
      expect(record.disabled).not_to eq(true)
    end

    it "should not call the before_create action" do
      record.save
      expect(record.date_of_birth).to eq(DateTime.parse("2000-1-1"))
    end

    it "should not call the after_save action" do
      record.save
      expect(record.latitude).to be_nil
    end

    it "should not call the after_create action" do
      record.save
      expect(record.longitude).to be_nil
    end
  end

  describe "before create callbacks' conditions" do
    before(:each) do
      record.avatar = "nope"
    end

    it "should not save the record" do
      expect(record.save).to eq(false)
      expect(record).not_to be_persisted
    end

    it "should assign the disabled" do
      record.save
      expect(record.disabled).to eq(true)
    end

    it "should not assign the date_of_birth" do
      record.save
      expect(record.date_of_birth).to eq(DateTime.parse("2000-1-1"))
    end

    it "should not call the after_save action" do
      record.save
      expect(record.latitude).to be_nil
    end

    it "should not call the after_create action" do
      record.save
      expect(record.longitude).to be_nil
    end
  end

  describe "before update callbacks' conditions" do
    before(:each) do
      record.avatar = "dope"
    end

    it "should have no effect on create" do
      expect(record.save).to eq(true)
      expect(record).to be_persisted
    end

    describe "when updating" do
      before(:each) do
        record.avatar = nil
        record.save!
      end

      it "should assign the latitude and longitude after update" do
        expect(record.save).to eq(true)
        expect(record.latitude).to eq(555)
        expect(record.longitude).to eq(888)
      end

      describe "and condition failed in before_update" do
        before(:each) do
          # Reset to test the callback behavior.
          record.avatar        = "dope"
          record.date_of_birth = nil
          record.longitude     = nil
          record.latitude      = nil
        end

        it "should not save the record" do
          expect(record.save).to eq(false)
        end

        it "should assign the disabled" do
          record.save
          expect(record.disabled).to eq(true)
        end

        it "should not assign the date_of_birth" do
          record.save
          expect(record.date_of_birth).to be_nil
        end

        it "should not call the after_save action" do
          record.save
          expect(record.latitude).to be_nil
        end

        it "should not call the after_update action" do
          record.save
          expect(record.longitude).to be_nil
        end
      end
    end
  end

  describe "after save callbacks' conditions" do
    before(:each) do
      record.avatar = "rope"
    end

    it "should save the record" do
      expect(record.save).to eq(true)
      expect(record).to be_persisted
    end

    it "should not assign the latitude" do
      record.save!
      expect(record.latitude).to be_nil
    end

    it "should not assign the longitude" do
      record.save!
      expect(record.longitude).to eq(777)
    end
  end

  describe "after create callbacks' conditions" do
    before(:each) do
      record.avatar = "pope"
    end

    it "should save the record" do
      expect(record.save).to eq(true)
      expect(record).to be_persisted
    end

    it "should not assign the latitude" do
      record.save!
      expect(record.latitude).to be_nil
    end

    it "should not assign the longitude" do
      record.save!
      expect(record.longitude).to be_nil
    end
  end

  describe "after update callbacks' conditions" do
    before(:each) do
      record.save!
      # Reset to test the callback behavior.
      record.latitude  = nil
      record.longitude = nil
      record.avatar    = "hope"
    end

    it "should save the record" do
      expect(record.save).to eq(true)
      expect(record).to be_persisted
    end

    it "should not assign the latitude" do
      record.save!
      expect(record.latitude).to be_nil
    end

    it "should not assign the longitude" do
      record.save!
      expect(record.longitude).to be_nil
    end    
  end

  describe "before destroy callbacks' conditions" do
    before(:each) do
      record.save!
      record.height = nil
      record.age    = nil
    end

    it "should be destroyed correctly on happy path" do
      expect(record.destroy).to eq(true)
      expect(record).not_to be_persisted
    end

    it "assign the attributes" do
      record.destroy
      expect(record.height).to eq(70)
      expect(record.age).to eq(999)
    end

    describe "when before destroy returns false" do
      before(:each) do
        record.avatar = "back"
        record.height = nil
        record.age    = nil
      end

      it "should not destroy the record" do
        expect(record.destroy).to eq(false)
        expect(record).to be_persisted
      end

      it "should not assign the attributes" do
        record.destroy
        expect(record.height).to be_nil
        expect(record.age).to be_nil
      end
    end

    describe "when after destroy returns false" do
      before(:each) do
        record.avatar = "sack"
        record.height = nil
        record.age    = nil
      end

      it "should destroy the record" do
        expect(record.destroy).to eq(true)
        expect(record).not_to be_persisted
      end

      it "should not assign the attributes in after destroy" do
        record.destroy
        expect(record.height).to eq(70)
        expect(record.age).to be_nil
      end
    end

  end
end