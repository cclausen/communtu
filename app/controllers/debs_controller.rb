# (c) 2008-2011 by Allgemeinbildung e.V., Bremen, Germany
# This file is part of Communtu.

# Communtu is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Communtu is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero Public License for more details.

# You should have received a copy of the GNU Affero Public License
# along with Communtu.  If not, see <http://www.gnu.org/licenses/>.

class DebsController < ApplicationController
  before_filter :check_administrator_role, :add_flash => { :notice => I18n.t(:no_admin) }

  def title
    t(:controller_debs_0)
  end
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
        flash[:notice] = t(:controller_debs_1)
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
        flash[:notice] = t(:controller_debs_2)
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
    # this may take very long, hence fork
    flash[:notice] =  t(:deb_generation_in_background)
    fork do
      ActiveRecord::Base.connection.reconnect!
      @deb.generate
    end
    ActiveRecord::Base.connection.reconnect!
    redirect_to(deb_path(@deb))
  end

  def generate_all
    @debs = Deb.find_all_by_generated(false)
    # this may take very long, hence fork
    flash[:notice] =  t(:deb_generation_in_background)
    fork do
      ActiveRecord::Base.connection.reconnect!
      @debs.each {|deb| deb.generate}
    end
    ActiveRecord::Base.connection.reconnect!
    redirect_to(debs_url)
  end

  def bundle
    @bundle = Metapackage.find(params[:id])
    @debs = Deb.find_all_by_metapackage_id_and_generated(params[:id],false)
  end

  def generate_bundle
    @debs = Deb.find_all_by_metapackage_id_and_generated(params[:id],false)
    # this may take very long, hence fork
    flash[:notice] =  t(:deb_generation_in_background)
    fork do
      ActiveRecord::Base.connection.reconnect!
      @debs.each {|deb| deb.generate}
    end
    ActiveRecord::Base.connection.reconnect!
    redirect_to :action => 'bundle', :id => params[:id]
  end
end
