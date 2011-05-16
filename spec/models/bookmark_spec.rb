require File.dirname(__FILE__) + '/../spec_helper'

describe Bookmark do
  before(:each) do
    @bookmark = Bookmark.new
  end

  it "should be valid" do
    @bookmark.should be_valid
  end
end
