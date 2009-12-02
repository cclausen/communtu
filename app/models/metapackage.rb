class Metapackage < BasePackage

  require 'set.rb'
  require 'utils'
  require "lib/utils.rb"
    
  has_many   :metacontents, :dependent => :destroy
  has_many   :base_packages, :through => :metacontents
  has_many   :debs # destroy via callback
#  has_many   :packages, :through => :metacontents, :source => :base_package, :foreign_key => :base_package_id 
  belongs_to :category
  belongs_to :user
  
  acts_as_rateable
  
  validates_presence_of :name, :license_type, :user, :category # , :version, :description
  
  @state = { :pending => 0, :published => 1, :rejected => 2 }

  def name
    trans = translation(self.name_tid)
    if trans == "unknown"
    trans = "Neues Bündel"
    end
    return trans
  end

  def name_english
    trans = Translation.find(:first, :conditions => {:translatable_id => self.name_tid, :language_code => "en"})
    if trans != nil
     return trans.contents
    else
     return ""
    end
  end

  def description_english
    trans = Translation.find(:first, :conditions => {:translatable_id => self.description_tid, :language_code => "en"})
    if trans != nil
      return trans.contents
    else
      return ""              
    end
  end

  def description
    trans = translation(self.description_tid)
    if trans == "unknown"
    trans = ""
    end
    return trans
  end

  def self.state
    @state
  end
  
  def owned_by? user
    (user_id == user.id)
  end
  
  def is_published?
    return self.published == Metapackage.state[:published]
  end

  # contained packages (without bundles)
  def packages
    base_packages.select{|p| p.class == Package}
  end
  
  # metapackages using this one
  def metapackages
    Metapackage.find(:all,:conditions => ["metacontents.base_package_id = ?",self.id], :include => :metacontents)
  end

  def metaconents_for(package)
    Metacontent.find(:first,:conditions => ["metapackage_id = ? and base_package_id = ?",self.id,package.id])
  end

  # list of packages used for generation of debian metapackage
  def package_names_for_deb(dist,der,lic,sec,arch)
      mcs = Metacontent.find(:all,:conditions =>
             ["metapackage_id = ? and metacontents_distrs.distribution_id = ? and metacontents_derivatives.derivative_id = ?",
              self.id,dist.id,der.id],:include => [:metacontents_distrs, :metacontents_derivatives])
      packages = mcs.map{|mc| mc.base_package}.select{|p| p.is_present(dist,lic,sec,arch)}.map{|p| p.debian_name}
  end

  #conflicts within the bundle
  def internal_conflicts
    all_cons = {}
    packages = self.base_packages
    packages.each do |p|
      cons = p.conflicting_packages & packages
      if !cons.empty? then
        mcp = metaconents_for(p)
        newcons = cons.clone
        cons.each do |c|
          mcc = metaconents_for(c)
          if (mcp.distributions & mcc.distributions).empty? or (mcp.derivatives & mcc.derivatives).empty?
            newcons.delete(c)
          end
        end
        if !newcons.empty? then
          all_cons[p]=newcons
        end
      end
    end
    return all_cons
  end

  def self.update_conflicts
    begin
      puts "New iteration"
      modified = false
      Metapackage.all.each do |m|
        m.base_packages.each do |p|
          p.conflicting_packages.each do |cp|
            if Conflict.find(:first,:conditions => {:package_id => m.id, :package2_id => cp.id}).nil?
              modified = true
              Conflict.create(:package_id => m.id, :package2_id => cp.id)
            end
          end
        end
      end
    end while modified
  end

  # use edos_checkdeb for detection of conflicts
  def edos_conflicts
    name = self.debian_name
    description = "test"
    Distribution.all.each do |dist|
      package_list_list = []
      Derivative.all.each do |der|
        # use largest license and security type, this should reveal all conflicts  
        package_list_list << package_names_for_deb(dist,der,1,2)
      end
      package_list_list.uniq.each do |package_names|
        puts
        puts name, dist.name
        Dir.chdir dist.dir_name
        # TODO: better check *all* bundles, since there can be indirect conflicts
        Deb.write_control(name,package_names,description,1)
        system "cat [0-9]* control | edos-debcheck -explain #{name}"
        system "rm control"
      end
    end
  end

  # this function is needed to complement is_present for class Package
  def is_present(distribution,licence,security,arch)
    true
  end

  def compute_license_type
    (self.base_packages.map{|p| p.compute_license_type} <<0).max
  end
  
  def compute_security_type
    (self.base_packages.map{|p| p.compute_security_type} <<0).max
  end
  
   def installedsize(dist)
     self.base_packages.map{|p| p.installedsize(dist)}.compact.sum
  end
  
  # copy the metapackage contents from from_dist to to_dist
  def migrate(from_dist, to_dist)
    not_found = []
    self.metacontents.each do |mc|
      # look for the mcs belonging to from_dist
      # *and* having packages available for to_dist
      if mc.distributions.include?(from_dist)
        if mc.base_package.class != Package 
          # bundle, always append it
          append = true
        else
          # package, only append it if present in the distribution
          if mc.base_package.distributions.include?(to_dist)
            append = true
          else
            not_found << mc.base_package
            append = false
          end
        end
        if append && !mc.distributions.include?(to_dist)
          mc.distributions << to_dist
        end
      end
    end
    return not_found    
  end
  
  # icon for bundles
  def self.icon(size)
    s = size.to_s
    return '<img border="0" height="'+s+'" width="'+s+'" src="/images/apps/Metapackage.png"/>'
  
  end

## installation and creating debian metapackages

  def recursive_packages package_names, package_sources, dist, license, security
    arch = Architecture.find(:first) # TODO: make this more generic
    self.base_packages.each do |p|
        if p.class == Package
            reps = p.repositories_dist(dist,arch).select{|r| r.security_type<=security && r.license_type<=license}
            if !reps.empty? then
              package_names.push(p.name)
              reps.each do |rep|
                package_sources.add(rep)
              end
            end
        else
            p.recursive_packages package_names, package_sources, dist, license, security
        end
    end
  end

  def recursive_packages_sources package_sources, dist, license, security
    arch = Architecture.find(:first) # TODO: make this more generic
    self.base_packages.each do |p|
        if p.class == Package
            reps = p.repositories_dist(dist,arch).select{|r| r.security_type<=security && r.license_type<=license}
            if !reps.empty? then
              reps.each do |rep|
                if package_sources[rep].nil? then
                  package_sources[rep] = [p]
                else  
                  package_sources[rep] << p
                end
              end
            end
        else
            p.recursive_packages_sources package_sources, dist, license, security
        end
    end
  end

  def debianize
    # start with version 0.1 if there is none
    if self.version.nil? or self.version.empty? then
      self.version = "0.1"
      self.debianized_version = "0.1"
      self.save
    end
    # abort if it does not make sense to debianize
    if !self.modified or self.debianizing
      return false
    end
    self.debianized_version = self.version
    self.debianizing = true
    self.save
    # generate debs
    Distribution.all.each do |dist|
      Derivative.all.each do |der|
        (0..1).each do |lic|
          (0..2).each do |sec|
            codename = Deb.compute_codename(dist,der,lic,sec)
            version = "#{self.version}-#{codename}"
            deb = Deb.create({:metapackage_id => self.id, :distribution_id => dist.id, :derivative_id => der.id, 
                              :license_type => lic, :security_type => sec, :version => self.version,
                              :url => version, :generated => false})
          end
        end
      end
    end
    return true
  end
  
  def generate_debs
    # generate debian packages from debs
    Deb.find(:all,:conditions => ["metapackage_id = ? and version = ?",self.id,self.version]).each do |deb|
      deb.generate
    end
    return true
  end

  def generate_debs_then_unlock
    generate_debs
    safe_system "dotlockfile -u #{RAILS_ROOT}/forklock"
  end

  def fork_generate_debs
    # only allow one fork at a time, in order to prevent memory leaks
    safe_system "dotlockfile -r 1000 #{RAILS_ROOT}/forklock"
    fork do
      system 'echo "Metapackage.find('+self.id.to_s+').generate_debs_then_unlock" | nohup script/console production'
    end
  end
  
  def self.debianize_all
    Metapackage.all.each do |m|
      puts
      puts
      puts "++++++++++++++++++++++ Processing package #{m.name}"
      puts
      m.debianize
    end
  end 
    
  protected
  
  # :dependent => :destroy will not work since the metapackage is needed for destroying the debs
  def before_destroy
    Deb.destroy(self.debs.map{|d| d.id})
  end
  
end
