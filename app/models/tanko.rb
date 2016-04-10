class Tanko < ActiveRecord::Base
  has_many :containers
  accepts_nested_attributes_for :containers
  validates :service_name, presence: true,
                    length: { minimum: 5 }

end
