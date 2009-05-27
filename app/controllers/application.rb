# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  require 'set.rb'
  require 'i18n'
  
  helper :all # include all helpers, all the time
  include AuthenticatedSystem
  include ApplicationHelper
  include TabzHelper
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '0b1deaf6bf7e9a53ea11187cd1bbe6a1'
  
  rescue_from ActionController::InvalidAuthenticityToken, :with => :auth_error
  
  def auth_error
    redirect_to(:controller => 'home', :action => 'auth_error')
  end
  filter_parameter_logging :password 
  
  def is_anonymous 
    if current_user.anonymous?
      redirect_to root_path
    end
  end
end
