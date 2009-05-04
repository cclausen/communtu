class DebsController < ApplicationController
  # GET /debs
  # GET /debs.xml
  def index
    @debs = Deb.find_all_by_generated(false)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @debs }
    end
  end

  # GET /debs/1
  # GET /debs/1.xml
  def show
    @deb = Deb.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @deb }
    end
  end

  # GET /debs/new
  # GET /debs/new.xml
  def new
    @deb = Deb.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @deb }
    end
  end

  # GET /debs/1/edit
  def edit
    @deb = Deb.find(params[:id])
  end

  # POST /debs
  # POST /debs.xml
  def create
    @deb = Deb.new(params[:deb])

    respond_to do |format|
      if @deb.save
        flash[:notice] = 'Deb was successfully created.'
        format.html { redirect_to(@deb) }
        format.xml  { render :xml => @deb, :status => :created, :location => @deb }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @deb.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /debs/1
  # PUT /debs/1.xml
  def update
    @deb = Deb.find(params[:id])

    respond_to do |format|
      if @deb.update_attributes(params[:deb])
        flash[:notice] = 'Deb was successfully updated.'
        format.html { redirect_to(@deb) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @deb.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /debs/1
  # DELETE /debs/1.xml
  def destroy
    @deb = Deb.find(params[:id])
    @deb.destroy

    respond_to do |format|
      format.html { redirect_to(debs_url) }
      format.xml  { head :ok }
    end
  end
  
  def generate
    @deb = Deb.find(params[:id])
    @deb.generate
    redirect_to(debs_url)
  end

  def generate_all
    @debs = Deb.find_all_by_generated(false)
    @debs.each {|deb| deb.generate}
    redirect_to(debs_url)
  end

end