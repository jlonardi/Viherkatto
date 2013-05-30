class Roof < ActiveRecord::Base

 has_one :light
 has_many :locations
 has_many :environments, :through => :locations
 belongs_to :greenroof

  attr_accessible :area, :declination, :load_capacity, :light, :light_id

  validates :area, presence: true, :inclusion => {:in => (0...10000)}, :numericality => {:only_integer => true}
  validates :declination, presence: true, :inclusion => {:in => (0...90)}, :numericality => {:only_integer => true}
  validates :load_capacity, presence: true, :inclusion => {:in => (0...10000000)}, :numericality => {:only_integer => true}
end
