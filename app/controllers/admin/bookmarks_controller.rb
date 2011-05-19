class Admin::BookmarksController < Admin::ResourceController

  include Globalize2::GlobalizedFieldsControllerExtension

#  def index
#    @bookmarks = Bookmark.find(:all,:include =>:translations)
#  end

#  def new
#    @bookmark = Bookmark.new
#  end
#
#  def edit
#    @bookmark = Bookmark.find(params[:id])
#  end


end
