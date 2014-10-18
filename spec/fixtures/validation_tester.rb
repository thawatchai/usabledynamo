class ValidationTester
  include UsableDynamo::Document

  self.table_name = "usabledynamo_validation_testers"

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

  timestamps

  index [:email, :created_at]
  index [:first_name, :last_name]

  validates_presence_of :first_name, :last_name, :date_of_birth
  validates_presence_of :weight, :if => Proc.new { |x| x.age && x.age > 10 }
  validates_presence_of :height, :unless => Proc.new { |x| x.age && x.age < 20 }

  validates_uniqueness_of :email, range: { "created_at.ge" => 0 }, allow_blank: true
  validates_uniqueness_of :last_name, scope: :first_name, allow_nil: true, :if => lambda { |x| x.first_name }

  validate :check_unusual_weight, :on => :create, :if => :weight
  validate :check_unusual_height, :on => :update, :unless => lambda { |x| x.height.nil? }
  validate :check_unusual_age

  private

  def check_unusual_weight
    if self.weight > 300
      self.errors[:weight] << "weight should be less than 300 kg"
    end
  end

  def check_unusual_height
    if self.height > 300
      self.errors[:height] << "height should be less than 300 cm"
    end
  end

  def check_unusual_age
    if self.age && self.age > 200
      self.errors[:age] << "age should be less than 200"
    end
  end
end
