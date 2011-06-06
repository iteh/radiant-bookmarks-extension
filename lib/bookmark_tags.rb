module BookmarkTags
  include Radiant::Taggable

  desc %{
    Display a Bookmark
    <pre><code><r:bookmark id=""/></code></pre>
  }

  tag 'bookmark' do |tag|
    tag.locals.bookmark = Bookmark.find(tag.attr['id']) if tag.attr['id']
    raise StandardTags::TagError, "no bookmark set"  if tag.locals.bookmark.nil?
    tag.expand
  end

  desc %{
    Display Bookmarks
    <pre><code><r:bookmarks type="" start_date="" end_date="" date=""]/></code></pre>
  }
  tag 'bookmarks' do |tag|
    bookmarks_type = tag.attr['type'] || "by_week"
    start_date = tag.attr['start_date'] ? Date.parse(tag.attr['start_date']) : Date.today
    end_date = tag.attr['end_date'] ? Date.parse(tag.attr['end_date']) : Date.today
    date = tag.attr['date'] ? Date.parse(tag.attr['date']) : Date.today
    case bookmarks_type
      when "by_tag"
        tag.locals.bookmarks = Bookmark.by_week Date.today
      when "by_date_range"
        tag.locals.bookmarks = Bookmark.by_date_range start_date, end_date
      when "by_day"
        tag.locals.bookmarks = Bookmark.by_day date
      when "by_week"
        tag.locals.bookmarks = Bookmark.by_week date
      when "by_month"
        tag.locals.bookmarks = Bookmark.by_month date
      else
        tag.locals.bookmarks = Bookmark.by_month date
    end

    result = ''
    tag.locals.bookmarks.each do |bookmark|
      tag.locals.bookmark = bookmark
      result << tag.expand
    end
    result
  end

  [:title, :description, :orig_title, :orig_description, :content, :url].each do |method|
    desc %{
      Renders the @#{method.to_s}@ attribute of the bookmark
    <pre><code><r:bookmark:#{method.to_s}/></code></pre>

    }
    tag "bookmark:#{method.to_s}" do |tag|
      tag.locals.bookmark.send(method) #rescue nil
    end

  end


end
