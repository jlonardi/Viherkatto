class Light < ActiveRecord::Base

  has_many :plants
  has_many :roofs

  attr_accessible :desc, :id

  validates :desc, presence: true, length: { maximum: 100 }
  validates :id, presence: true, :numericality => {:only_integer => true, :greater_than => 0}
end
