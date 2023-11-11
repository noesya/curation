module Text

  def text
    @text ||= find_text_and_clean
  end

  protected

  BLACKLIST_HARD = [
    'head', 'script', 'style', 'iframe', 'nav', 'noscript', 'header', 'footer', 'aside',
    '.navigation', '.top-menu-container', '.navbar', '.navbar-header', '.breadcrumb',
    '#breadcrumbs', '[typeof="v:Breadcrumb"]', '.skip-link', '.search', '.search-form',
    '.categories', '.post-categories', '.datas', '.post-datas', '.twitter-media',
    '.instagram-media', '.widget', '.related-post-tags', '.social-list', '.top-scroll',
    '.comments', '.signature', '.publicite', '.footer', '.Footer', '.footer-copyright',
    '[itemprop*="author"]', '[style*="display:none;"]', '[style*="display:none"]',
    '[style*="display: none;"]', '[style*="display: none"]', '[aria-hidden="true"]'
  ]

  BLACKLIST_SOFT = [
    'head', 'script', 'noscript', 'style', 'iframe', 'nav', 'footer', 'aside', '[role="dialog"]'
  ]

  def find_text_and_clean
    text = find_text.to_s.dup
    text = text.gsub('<br><br>', '<br>')
    text = text.gsub(/\s+/, ' ')
    text = clean_encoding(text)
    text

  end

  def find_text
    find_text_with_json_ld || 
    find_text_with_nokogiri_hard ||
    find_text_with_nokogiri_soft
  end

  def find_text_with_json_ld
    if json_ld.any?
      json_ld.each do |ld|
        next unless ['NewsArticle', 'ReportageNewsArticle'].include? ld['@type']
        return ld['text'] if ld.has_key? 'text'
        return ld['articleBody'] if ld.has_key? 'articleBody'
      end
    end
    false
  end

  def find_text_with_nokogiri_hard
    h = nokogiri.dup
    h.xpath('//style').remove
    BLACKLIST_HARD.each do |tag|
      h.css(tag).remove
    end
    nodes = h.css('p')
    text = nodes.to_html
    text.present? ? text : false
  end

  def find_text_with_nokogiri_soft
    h = nokogiri.dup
    h.xpath('//style').remove
    BLACKLIST_SOFT.each do |tag|
      h.css(tag).remove
    end
    h.text
  end

  # r&Atilde;&copy;forme -> réforme
  def clean_encoding(text)
    clean_text = HTMLEntities.new.decode text
    double_encoding = false
    [
      'Ã©', # é
      'Ã¨', # è
      'Ã®', # î
      'Ãª', # ê
    ].each do |string|
      double_encoding = true if clean_text.include? string
    end
    if double_encoding
      clean_text.encode('iso-8859-1', undef: :replace)
                .force_encoding('utf-8')
    else
      text
    end
  end

end