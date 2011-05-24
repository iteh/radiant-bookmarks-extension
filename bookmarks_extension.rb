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
    tab_18n_bookmark_url = {:prefix => "/admin",:url =>"bookmarks",:controller=> "admin/bookmarks", :action => "index"}
    def tab_18n_bookmark_url.to_str
      File.join(self[:prefix],Globalize2Extension.content_locale.to_s,self[:url])
    end

    def tab_18n_bookmark_url.to_s
      to_str
    end

    def tab_18n_bookmark_url.dup
      to_str
    end

    tab 'Content' do

       add_item "Bookmarks", tab_18n_bookmark_url, :after => "Pages"
     #  add_item "Bookmarks EN", "/admin/en/bookmarks", :after => "Pages"
    end

    Radiant::AdminUI.class_eval do
      attr_accessor :bookmarks
    end

    admin.bookmarks = load_default_bookmarks_regions

    Page.send :include, BookmarkTags

  end

  def load_default_bookmarks_regions
    returning OpenStruct.new do |bookmarks|
      bookmarks.index = Radiant::AdminUI::RegionSet.new do |index|
        index.top.concat %w{languages}
        index.main.concat %w{list}
        index.bottom.concat %w{new_button}
      end
    end
  end

end
