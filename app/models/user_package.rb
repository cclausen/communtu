class UserPackage < ActiveRecord::Base
  belongs_to :user
  belongs_to :base_package, :foreign_key => :package_id

end