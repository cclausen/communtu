class AdminsController < ApplicationController
  def title
    _("Administratorbereich")
  end
  before_filter :check_administrator_role, :flash => { :notice => _('Du bist kein Administrator!') }
  
  def index
  end

  def show
  end

  def load_packages
    dist     = Distribution.find(:first)
    @new_count, @update_count = Package.import_source dist.id, dist.native
  end 
  
  def sync_package
    @repository = Repository.find(params[:id])
    @info = Package.import_source @repository  
  end

  def sync_all
    @distribution = Distribution.find(params[:id])
    @infos = @distribution.repositories.map { |r| Package.import_source r }
  end

  def test_all
    @distribution = Distribution.find(params[:id])
    @infos = @distribution.repositories.map { |r| Package.test_source r }
  end

end
