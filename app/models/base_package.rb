class BasePackage < ActiveRecord::Base
  require 'set.rb'
  require 'lib/utils.rb'

  has_many :user_packages, :foreign_key => :package_id
  has_many :videos
  has_many :conflicts, :foreign_key => :package_id
  has_many :conflicting_packages, :source => :base_package, :through => :conflicts
  has_many :dependencies, :dependent => :destroy
  
#  def name
#    translation(self.name_tid)
#  end
        
#  def name_english
#    trans = Translation.find(:first, :conditions => {:translatable_id => self.name_tid, :language_code => "en"})
#    return trans.contents
#  end
                  
#  def description
#    translation(self.description_tid)
#  end                           

    # type of a package, for sorting package lists
  def ptype
    # first display metapackages
    if self.class == Metapackage then
      return 0
    # then program packages
    elsif self.is_program then
      return 1
    # the library packages etc.  
    else return 2
    end
  end

  def debian_name
    if self.class == Metapackage then
      if self.is_published? then
        n="communtu-"+self.name_english
      else 
        n="communtu-private-bundle-"+self.name_english
      end
    else
      n=self.name
    end 
    return BasePackage.debianize_name(n)
  end
  
  def self.debianize_name(n)
    return n.downcase.gsub("ä","ae").gsub("ö","oe").gsub("ü","ue").gsub("ß","ss").gsub(/[^a-z0-9.+-]/, '-')
    # todo: is umlaut elimination really needed?
  end
  
  # packages directly or indirectly installed by this bundle
  def all_recursive_packages
    packages = Set.[]
    all_recursive_packages_aux packages
    return packages
  end
  
  def all_recursive_packages_aux packages
    if !packages.include?(self) then
      packages.add(self)
      if self.class == Package
        self.package_distrs.each do |pd|
          pd.depends_or_recommends.each do |p|
            p.all_recursive_packages_aux packages
          end
        end
      else
        self.base_packages.each do |p|
          p.all_recursive_packages_aux packages
        end
      end
    end
  end


  # packages directly or indirectly installed by this bundle, structured output
  def structured_all_recursive_packages
    packages = {} 
    deps = []
    structured_all_recursive_packages_aux packages, deps
    return packages
  end
  
  def structured_all_recursive_packages_aux packages, deps
    if !deps.include?(self)
      deps.push(self)
      packages_local = {}
      if self.class == Package
        self.package_distrs.each do |pd|
          pd.depends_or_recommends.each do |p|
            p.structured_all_recursive_packages_aux packages_local, deps
          end  
        end
        
      else
        self.base_packages.each do |p|
          p.structured_all_recursive_packages_aux packages_local, deps
        end
      end
      packages[self] = packages_local
    end
  end

end
