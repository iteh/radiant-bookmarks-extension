# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application_controller'
require 'radiant-bookmarks-extension/version'
class BookmarksExtension < Radiant::Extension
  version RadiantBookmarksExtension::VERSION
  description "Adds bookmarks to Radiant."
  url "http://yourwebsite.com/bookmarks"
  
  # extension_config do |config|
  #   config.gem 'some-awesome-gem
  #   config.after_initialize do
  #     run_something
  #   end
  # end

  # See your config/routes.rb file in this extension to define custom routes
  
  def activate
    # tab 'Content' do
    #   add_item "Bookmarks", "/admin/bookmarks", :after => "Pages"
    # end
  end
end
