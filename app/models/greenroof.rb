class Greenroof < ActiveRecord::Base

  belongs_to :user

  has_many :plants, through: :groofplants
  has_many :roofs, through: :groofroofs
  has_many :bases, through: :groofbases

  accepts_nested_attributes_for :plants, :roofs, :bases

  attr_accessible :plants, :roofs, :bases, :address, :purpose, :note, :user_id

  validates :address, presence: true, length: { maximum: 150 }
  validates :purpose, allow_blank: false, numericality: true, inclusion: {in: (0...2)}
  validates :note, length: { maximum: 1500 }
  validates :user_id, allow_blank: false, numericality: true

end
