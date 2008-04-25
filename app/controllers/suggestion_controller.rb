class SuggestionController < ApplicationController
  
  before_filter :authorize_user_subresource
  
  def show
    @profile   = current_user.user_profiles
    @root      = Category.find(1)
    @selection = {}
    @profile.each do |p|

        category = Category.find(p.category_id)
        metas    = Metapackage.find(:all, :conditions => ["category_id = ? and rating <= ? and license_type <= ?", category.id, p.rating, current_user.license])
        @selection.store(category, metas)
    
    end
  end 

  def recursive_packages meta, package_install, package_sources    
    meta.base_packages.each do |p|
        if p.class == Package
            package_install << (p.name + " ")
            package_sources.store(p.repository, p.repository.url)
        else
            recursive_packages p, package_install, package_sources
        end
    end
  end

  def install

    script          = ""
    package_install = ""
    sources         = {}
    package_sources = ""
   
    script += "#!/bin/bash\n\n"
    script += "file=\"/etc/apt/sources.list\"\n\n"
    
    packages = params[:post]
    packages.each do |id,unused|
    
        package = Metapackage.find(id)
        recursive_packages package, package_install, sources
    end
    
    gen_package_sources sources, package_sources
    
    script += package_sources
    script += "apt-get update\n"
    script += "apt-get install " + package_install + "\n"
    
    respond_to do |format|
        format.text { send_data(script, :filename => "install.sh", :type => "text", :disposition => "attachment") }
    end
    
  end
  
  private
  
    def gen_package_sources sources, package_sources
        sources.each do |repository, url|
            out  = "source=\"" + url + " " + repository.subtype + "\"\n"
            out += "grep -q \"repository.url" + ".*" + repository.subtype + "\" $file\n\n"
            out += "if [ \"$?\" != \"0\" ]; then\n" +
            "\techo \"$source\" >> $file\n" +
            "fi\n\n"
            package_sources << out
        end
    end
      
end

