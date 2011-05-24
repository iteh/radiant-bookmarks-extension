class BookmarkRangePagePart < PagePart
  content :string
  serialize :content

  def render_content
    "#{start_date} #{end_date}' />"
  end

  def start_date
    content['start_date']
  end

  def end_date
    content['end_date']
  end

  def after_initialize
    self.content ||= {}
  end

end