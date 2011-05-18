class Admin::BookmarksController < ApplicationController

  include Globalize2::GlobalizedFieldsControllerExtension

  def index
    @bookmarks = Bookmark.find(:all,:include =>:translations)
  end
end
