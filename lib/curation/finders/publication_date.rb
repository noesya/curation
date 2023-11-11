module PublicationDate

  def date
    @date ||= find_date
  end

  protected

  def find_date
    if json_ld.any?
      json_ld.each do |ld|
        next unless ['NewsArticle', 'ReportageNewsArticle'].include? ld['@type']
        return Date.parse ld['datePublished'] if ld.has_key? 'datePublished'
      end
    end
    return Date.parse metatags['date'] rescue nil
    return Date.parse metatags['pubdate'] rescue nil
    return Date.parse nokogiri.css('meta[property="article:published"]').first['content'] rescue nil
    return Date.parse nokogiri.css('meta[property="article:published_time"]').first['content'] rescue nil
    return Date.parse nokogiri.css('meta[property="og:article:published_time"]').first['content'] rescue nil
    chunks = html.split('DisplayDate')
    if chunks.count > 1
      value = chunks[1]
      value = value.split(',').first
      value = value.gsub('"', '')
      value = value[1..-1] if value[0] == ':'
      return Date.parse value rescue nil
    end
    begin
      value = nokogiri.css('.postDate').first
      value = value.inner_text
      value = value.gsub(' — ', '')
      return Date.parse value
    rescue
    end
    begin
      value = nokogiri.css('.gta_post_date').first
      value = value.inner_text
      return Date.parse value
    rescue
    end
  end
end