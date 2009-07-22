require 'open-uri'
require 'zlib'
require 'lib/utils'

class Repository < ActiveRecord::Base
  belongs_to :distribution
  has_many :package_distrs, :dependent => :destroy
  has_many :packages, :through => :package_distrs
  validates_presence_of :license_type, :url, :distribution_id
  
  def name
    self.url+" "+self.subtype
  end
  
  # migrate a repository to a different distribution
  def migrate(dist)
    newurl = url.gsub(self.distribution.short_name.downcase, \
                      dist.short_name.downcase)
    Repository.create({:distribution_id => dist.id,
                       :security_type => security_type,
                       :license_type => license_type,
                       :type => type,
                       :url => newurl,
                       :subtype => subtype,
                       :gpgkey => gpgkey})
  end

  def self.get_url_from_source source
    parts = source.split " "
    if parts.length >= 3
      # add trailing "/" if necessary
      if parts[1][-1] != 47 then
        parts[1] += "/"
      end
      # get URL for 32 bit version - this should be changed in the future!
      if parts[3].nil? then
        url = parts[1] + parts[2] + "/Packages.gz"
      else
        url = parts[1] + "dists/" + parts[2] + "/" + parts[3] + "/binary-i386/Packages.gz"
      end
      return {:url => url}
    else
      return {:error => source+t(:model_package_6)}
    end
  end

  # test whether a source is present
  def test_source
    url  = Repository.get_url_from_source(self.name)[:url]
    if url.nil? then return {:error => I18n.t(:model_package_7,{:repo=> self.url + " " + self.subtype})} end
    begin
      file = open(url, 'User-Agent' => 'Ruby-Wget')
    rescue
      return {:error => url}
    else
      return {}
    end
  end


  # import repository info from the url
  def import_source

    distribution_id = self.distribution_id

    # get URL for repository
    url  = Repository.get_url_from_source(self.name)
    if !url[:error].nil? then
      return url
    end
    url = url[:url]
    # read in all packages from repository
    packages = self.packages_to_hash url
    if !packages[:error].nil? or !packages[:notice].nil? then
      return packages
    end

    info = { "package_count" => packages.size, "update_count" => 0, "new_count" => 0,\
      "failed" => [], "url" => url }

    # delete packages that are no longer in the repository
    pps = packages[:packages].values
    self.package_distrs.each do |pd|
      if !pps.include?(pd.package) then
        pd.destroy
      end
    end

    # enter packages
    packages[:packages].each do |name,package|

      # adapt description if nil
      if package["Description"].nil?
        package["Description"] = ""
      end

      # compute attributes for package
      attributes_package = { :name => name,
          :description => package["Description"],\
          :fullsection => package["Section"],\
          # für :section nur den letzten Teil verwenden
          :section => package["Section"].split("/")[-1]}

      # look for existing package
      p = Package.find(:first, :conditions => ["name=?",name])
      if p.nil?
        # no package? create a new one
        p= Package.new(attributes_package)
        if p.save
          info["new_count"] = info["new_count"].next
        else
          info["failed"].push name
        end
      else
        # package exists, then update attributes
        if p.update_attributes(attributes_package)
          info["update_count"] = info["update_count"].next
        else
          info["failed"].push name
        end
      end

      # compute attributes for package_distr
      attributes_package_distr = {
          :package_id => p.id,
          :version => package["Version"],
          :distribution_id => distribution_id,
          :filename => package["Filename"],
          :repository_id => self.id,
          :size => package["Size"],
          :installedsize => package["Installed-Size"]}

      # compute license type by minimum with existing one
      if p.license_type.nil? then
        p.license_type = self.license_type
      else
        p.license_type = min(self.license_type,p.license_type)
      end

      # compute security type by minimum with existing one
      if p.security_type.nil? then
        p.security_type = self.security_type
      else
        p.security_type = min(self.security_type,p.security_type)
      end

      # update package_distr
      pd = PackageDistr.find(:first, :conditions =>
             ["package_id = ? and repository_id = ?",p.id,self.id])
      if pd.nil?
        # no package_distr? create a new one
          pd = PackageDistr.new(attributes_package_distr)
          if !pd.save then
            info["failed"].push(name + " " + self.url)
          end
      else
        # package exists, then update attributes
          if !pd.update_attributes(attributes_package_distr) then
            info["failed"].push(name + " " + self.url)
          end
      end
    end # packages[:packages].each

    # enter dependency info - this must happen *after* creation of the packages!
    packages[:packages].each do |name,package|
      p = Package.find(:first, :conditions => ["name=?",name])
      if not p.nil?
        pd = PackageDistr.find(:first, :conditions =>
           ["package_id = ? and repository_id = ?",p.id,self.id])
        if not pd.nil?
          pd.dependencies.delete_all
          pd.assign_depends(Repository.parse_dependencies(package["Depends"]))
          pd.assign_recommends(Repository.parse_dependencies(package["Recommends"]))
          pd.assign_suggests(Repository.parse_dependencies(package["Suggests"]))
          pd.assign_conflicts(Repository.parse_unversioned_dependencies(package["Conflicts"]))
        else raise I18n.t(:model_package_9,{:repo_name => self.name, :package_name => p.name})
        end
      else raise I18n.t(:model_package_10,{:repo_name => self.name, :package_name => name})
      end
    end

    return info
  end

  # get all dependencies
  def self.parse_dependencies(s)
    if s.nil? then
      return []
    else
      s.split(",").map{|s1| s1.split(" (").first.lstrip}.map{ |name|
        Package.find_by_name(name) }.compact
    end
  end

  # get all dependencies without version
  def self.parse_unversioned_dependencies(s)
    if s.nil? then
      return []
    else
      packages = []
      s.split(",").map{|s1| s1.split(" (")}.each do |p|
        if p.length == 1 then
          packages.push(Package.find_by_name(p.first.lstrip))
        end
      end
      return packages.compact
    end
  end

  def packages_to_hash url
    if url.nil? then return {:error => I18n.t(:model_package_11)} end
    begin
      file = open(url, 'User-Agent' => 'Ruby-Wget')
    rescue
      return {:error => I18n.t(:model_package_could_not_read,:url => url)}
    else
      contents = file.read
      if contents==self.package_file then
        return {:notice => I18n.t(:model_package_need_not_update,:url => url)}
      end
      self.package_file = contents
      self.save
      file.seek(0,IO::SEEK_SET)
      packages = {}
      reader   = Zlib::GzipReader.new(file)

      while !reader.eof? && line = reader.readline do
        if not line.sub!(/^Package: /, "").nil?
            package = line.chomp
            packages.store package, {}
            readpackage = lambda do |content|
              if !reader.eof? then
                line = reader.readline
                if (not line == "\n")
                    if (line.match(/^ /).nil?)
                        upto_colon = line.match(/^.*: /)
                        option = if upto_colon.nil? then ""
                                 else upto_colon [0].chop.chop end
                        content = line.gsub(option+": ", "").strip.chomp

                        if Repository.is_valid_option? option
                            packages[package].store option, content
                        end
                    else
                        content << (line.chomp)
                    end
                    readpackage.call content
                end
              end
            end
            readpackage.call ""
        else
           return {:error => I18n.t(:model_package_12,{:file=>url})+":<br><code>"+line+"</code>"}
        end
      end
      return {:packages => packages}
    end
  end

  def self.is_valid_option? option
    option == "Version" or option == "Description" or option == "Section" \
     or option == "Depends" or option == "Recommends" \
     or option == "Conflicts" or option == "Suggests" \
     or option == "Installed-Size" or option == "Size" \
     or option == "Filename"
  end
  
end
