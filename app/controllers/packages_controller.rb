class PackagesController < ApplicationController
  
  # GET /Packages
  # GET /Packages.xml
  def index           
    @distribution = Distribution.find(params[:distribution_id])
    
    if not session[:search].nil?
        @packages = Package.find(:all, :page => {:size => 20, :current => params[:page]},
            :conditions => ["distribution_id = ? AND name like ?", @distribution.id, "%" + session[:search] + "%"], :order => "name")
    else
        if session[:group].nil? or session[:group] == "all"
          @packages = Package.find(:all, :page => {:size => 20, :current => params[:page]},
            :conditions => ["distribution_id = ?", @distribution.id], :order => "name")
        else
          puts session[:group]
          @packages = Package.find(:all, :page => {:size => 20, :current => params[:page]},
            :conditions => ["distribution_id = ? and section = ?", @distribution.id, session[:group]], :order => "name")
        end
    end
    @groups = Package.find(:all, :select => "DISTINCT section", :order => "section")
        respond_to do |format|
          format.html { render :action => "index.html.erb" }
          format.xml  { render :xml => @Packages }
    end
  end
  
  def section
    session[:search] = nil
    group = params[:group]
    if group.nil? or group == "all"
      session[:group] = "all"
    else
      session[:group] = group
    end
    redirect_to distribution_path(Distribution.find(params[:id])) + "/packages"
  end
  
  def search
    session[:search] = params[:search]
    session[:group] = "all"
    redirect_to distribution_path(Distribution.find(params[:id])) + "/packages"
  end

  # GET /Packages/1
  # GET /Packages/1.xml
  def show
    @package = Package.find(params[:id])
    
    if not session[:meta_cart].nil?
      dist = TempMetapackage.find(:first, :conditions => [ "id=?", session[:meta_cart] ])
    end
    
    if not dist.nil?
      @distribution_id = dist.distribution_id
    else
      @distribution_id = -1 if @distribution_id.nil?
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @package }
    end
  end

  # GET /Packages/new
  # GET /Packages/new.xml
  def new
    @package = Package.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @package }
    end
  end

  # GET /Packages/1/edit
  def edit
    @package = Package.find(params[:id])
  end

  # POST /Packages
  # POST /Packages.xml
  def create
    @package = Package.new(params[:Package])

    respond_to do |format|
      if @package.save
        flash[:notice] = 'Package was successfully created.'
        format.html { redirect_to(@Package) }
        format.xml  { render :xml => @package, :status => :created, :location => @package }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @package.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /Packages/1
  # PUT /Packages/1.xml
  def update
    @package = Package.find(params[:id])

    respond_to do |format|
      if @package.update_attributes(params[:Package])
        flash[:notice] = 'Package was successfully updated.'
        format.html { redirect_to(@package) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @package.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /Packages/1
  # DELETE /Packages/1.xml
  def destroy
    @package = Package.find(params[:id])
    @package.destroy

    respond_to do |format|
      format.html { redirect_to(Packages_url) }
      format.xml  { head :ok }
    end
  end
  
end
