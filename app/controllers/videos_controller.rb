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

class VideosController < ApplicationController
  def title
    t(:headline)
  end

  # GET /videos/1
  # GET /videos/1.xml
  def show
    @video = Video.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @video }
    end
  end

  # GET /videos/1/edit
  def edit
    @video = Video.find(params[:id])
  end

  # PUT /videos/1
  # PUT /videos/1.xml
  def update
    @video = Video.find(params[:id])
    @trans_update_url = Translation.find(:first, :conditions => { :translatable_id => @video.url_tid, :language_code => I18n.locale.to_s})
    @trans_update_url.contents = params[:video][:url]
    @trans_update_url.save
    @trans_update_des = Translation.find(:first, :conditions => { :translatable_id => @video.description_tid, :language_code => I18n.locale.to_s})
    if @trans_update_des == nil
      @trans_update_des = Translation.new
      @trans_update_des.translatable_id = @video.description_tid
      @trans_update_des.contents = params[:video][:description]
      @trans_update_des.language_code = I18n.locale.to_s
    else
      @trans_update_des.contents = params[:video][:description]
    end
    @trans_update_des.save
    respond_to do |format|
      if @video.update_attributes(params[:video])
        format.html { redirect_to :controller => :packages, :action => :edit, :id => @video.base_package_id }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @video.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /videos/1
  # DELETE /videos/1.xml
  def destroy
    @video = Video.find(params[:id])
        @translation_url = Translation.find(:all, :conditions => { :translatable_id => @video.url_tid })
    m = @translation_url.length
    e = 0
    m.times do
     @translation_url[e].delete
     e = e + 1
    end
    @translation_des = Translation.find(:all, :conditions => { :translatable_id => @video.description_tid })
    m = @translation_des.length
    e = 0
    m.times do
     @translation_des[e].delete
     e = e + 1
    end
    @video.destroy

    respond_to do |format|
      format.html { redirect_to(videos_url) }
      format.xml  { head :ok }
    end
  end
end
