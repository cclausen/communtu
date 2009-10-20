class DistributionsController < ApplicationController
  
  def title
    t(:controller_distributions_0)
  end
  # GET /distributions
  # GET /distributions.xml
  def index
    @distributions = Distribution.find(:all, :order => 'short_name DESC')
    session[:search] = nil
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @distributions }
    end
  end

  # GET /distributions/1
  # GET /distributions/1.xml
  def show
    @distribution = Distribution.find(params[:id])
    session[:search] = nil
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @distribution }
    end
  end

  # GET /distributions/new
  # GET /distributions/new.xml
  def new
    @distribution = Distribution.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @distribution }
    end
  end

  # GET /distributions/1/edit
  def edit
    require "lib/utils.rb"
    @distribution = Distribution.find(params[:id])
  end
  
  # POST /distributions
  # POST /distributions.xml
  def create
    @distribution = Distribution.new(params[:distribution])
    @translation1 = Translation.new
    @translation2 = Translation.new
    @last_trans = Translation.find(:first, :order => "translatable_id DESC")
    last_id = @last_trans.translatable_id
    @translation1.translatable_id = last_id + 1
    @translation1.contents = params[:distribution][:description]
    @translation2.translatable_id = last_id + 2
    @translation2.contents = params[:distribution][:url]
    @distribution.description_tid = last_id + 1
    @distribution.url_tid = last_id + 2
    @translation1.language_code = I18n.locale.to_s
    @translation2.language_code = I18n.locale.to_s
    @translation1.save
    @translation2.save
    respond_to do |format|
      if @distribution.save
        flash[:notice] = t(:controller_distributions_1)
        format.html { redirect_to(@distribution) }
        format.xml  { render :xml => @distribution, :status => :created, :location => @distribution }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @distribution.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /distributions/1
  # PUT /distributions/1.xml
  def update
    @distribution = Distribution.find(params[:id])
    @trans_update_des = Translation.find(:first, :conditions => { :translatable_id => @distribution.description_tid, :language_code => I18n.locale.to_s})
    if @trans_update_des == nil
      @trans_update_des = Translation.new
      @trans_update_des.translatable_id = @distribution.description_tid
      @trans_update_des.contents = params[:distribution][:description]
      @trans_update_des.language_code = I18n.locale.to_s
    else
    @trans_update_des.contents = params[:distribution][:description]
    end
    @trans_update_des.save
    @trans_update_url = Translation.find(:first, :conditions =>
        { :translatable_id => @distribution.url_tid, :language_code => I18n.locale.to_s})
    if @trans_update_url == nil
      @trans_update_url = Translation.new
      @trans_update_url.translatable_id = @distribution.url_tid
      @trans_update_url.contents = params[:distribution][:url]
      @trans_update_url.language_code = I18n.locale.to_s
    else
    @trans_update_url.contents = params[:distribution][:url]
    end
    @trans_update_url.save
    respond_to do |format|
      if @distribution.update_attributes(params[:distribution])
        flash[:notice] = t(:controller_distributions_2)
        format.html { redirect_to(@distribution) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @distribution.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /distributions/1
  # DELETE /distributions/1.xml
  def destroy
    @distribution = Distribution.find(params[:id])
    @translation_url = Translation.find(:all, :conditions => { :translatable_id => @distribution.url_tid })
    m = @translation_url.count
    e = 0
    m.times do
     @translation_url[e].delete
     e = e + 1
    end
    @translation_des = Translation.find(:all, :conditions => { :translatable_id => @distribution.description_tid })
    m = @translation_des.count
    e = 0
    m.times do
     @translation_des[e].delete
     e = e + 1
    end
    @distribution.delete
    
    respond_to do |format|
      format.html { redirect_to(distributions_url) }
      format.xml  { head :ok }
    end
  end

  def migrate
    @distribution = Distribution.find(params[:id])
    @new_dist = Distribution.find(:first,:conditions => {:id => @distribution.id+1})
    # only proceed if new distribution is new and fresh
    if !@new_dist.nil? and Repository.find_by_distribution_id(@new_dist.id).nil? then
      @distribution.repositories.each do |r|
        r.migrate(@new_dist)
      end
      redirect_to(@new_dist)
    else
      flash[:error] = t(:cannot_migrate)
      redirect_to(@distribution)
    end
  end
end
