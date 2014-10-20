class CallbackTester
  include UsableDynamo::Document

  self.table_name = "usabledynamo_callback_testers"

  string_attr :id, auto: true

  string_attr   :first_name
  string_attr   :last_name
  string_attr   :email
  integer_attr  :age
  float_attr    :weight
  float_attr    :height
  boolean_attr  :disabled

  date_attr     :date_of_birth
  binary_attr   :avatar

  float_attr    :latitude
  float_attr    :longitude

  timestamps

  index [:email, :created_at]
  index [:first_name, :last_name]

  after_find :assign_necessary_attributes

  before_validation :before_validation_on_create_action, on: :create
  before_validation :before_validation_on_update_action, on: :update
  before_validation :before_validation_on_save_action, on: :save

  after_validation :after_validation_on_create_action, on: :create
  after_validation :after_validation_on_update_action, on: :update
  after_validation :after_validation_on_save_action, on: :save

  validates_presence_of :date_of_birth

  before_save   :before_save_action
  before_create :before_create_action
  before_update :before_update_action

  after_save   :after_save_action
  after_create :after_create_action
  after_update :after_update_action

  before_destroy :before_destroy_action
  after_destroy  :after_destroy_action

  private

  def assign_necessary_attributes
    self.avatar = "sorry"
  end

  def before_validation_on_create_action
    self.first_name = "foo"
  end

  def before_validation_on_update_action
    self.weight = 100
  end

  def before_validation_on_save_action
    self.last_name = "mudd"
  end

  def after_validation_on_create_action
    self.email = "foo@bar.com"
  end

  def after_validation_on_update_action
    self.height = 50
  end

  def after_validation_on_save_action
    self.age = 666
  end

  def before_save_action
    return false if self.avatar == "cope"
    self.disabled = true
  end

  def before_create_action
    return false if self.avatar == "nope"
    self.date_of_birth = DateTime.parse("1999-02-02")
  end

  def before_update_action
    return false if self.avatar == "dope"
    self.date_of_birth = DateTime.parse("1999-01-01")
  end

  def after_save_action
    return false if self.avatar == "rope"
    self.latitude = 555
  end

  def after_create_action
    return false if self.avatar == "pope"
    self.longitude = 777
  end

  def after_update_action
    return false if self.avatar == "hope"
    self.longitude = 888
  end

  def before_destroy_action
    return false if self.avatar == "back"
    self.height = 70
  end

  def after_destroy_action
    return false if self.avatar == "sack"
    self.age = 999
  end
end
