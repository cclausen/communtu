class Metapackage < BasePackage

  has_many   :metacontents, :dependent => :destroy
  has_many   :comments, :dependent => :destroy
  has_many   :base_packages, :through => :metacontents
#  has_many   :packages, :through => :metacontents, :source => :base_package, :foreign_key => :base_package_id 
  belongs_to :category
  belongs_to :user
  
  validates_presence_of :name, :license_type, :user, :category
  
  @state = { :pending => 0, :published => 1, :rejected => 2 }
  @levels = [ "gar nicht", "normal", "erweitert", "Experte", "Freak" ]
  
  def self.state
    @state
  end
  
  def self.levels
    @levels
  end

  def owned_by? user
    (user_id == user.id)
  end
  
  def is_published?
    return self.published == Metapackage.state[:published]
  end
  
  def migrate(distribution, current_user, failed, doubles)
    ignore = []
    migrate_intern(distribution, current_user, failed, doubles, ignore)
  end
  
  # icon for bundles
  def self.icon(size)
    s = size.to_s
    return '<img border="0" height="'+s+'" width="'+s+'" src="/images/apps/Metapackage.png"/>'
  
  end

  # convert rating to new default_install field
  def convert_rating
    self.default_install = (!rating.nil?) && rating<=1
    self.save
  end
  
  protected

  #### needs to be rewritten
  def migrate_intern(distribution, current_user, failed, doubles, ignore)

    meta = Metapackage.find(:first, :conditions => ["name = ?", self.name])
    if not meta.nil? and not ignore.include? meta
        doubles.push(meta)
    end

    meta = Metapackage.new
    meta.name            = name
    meta.user_id         = current_user.id
    meta.distribution_id = distribution.id
    meta.category_id     = category.id
    meta.description     = description
    meta.rating          = rating
    meta.license_type    = license_type
    
    contents = []
    
    base_packages.each do |package|
        if package.class == Package
            migrated = Package.find(:first, :conditions => ["name = ? and distribution_id = ?", package.name, distribution.id])
            if not migrated.nil?
                contents.push(migrated.id)
            else
                failed.push(package)
            end
        else
            package.migrate_intern(distribution, current_user, failed, doubles, ignore)
        end
    end
    
    if not contents.empty?
        meta.save!
        contents.each do |migrated|
            content = Metacontent.new
            content.metapackage_id  = meta.id
            content.base_package_id = migrated
            content.save!
        end
    end
  end

end
