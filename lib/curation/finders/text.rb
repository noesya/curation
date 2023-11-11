module Text

  BLACKLIST = [
    'head', 'script', 'style', 'iframe', 'nav', 'noscript', 'header', 'footer', 'aside',
    '.navigation', '.top-menu-container', '.navbar', '.navbar-header', '.breadcrumb',
    '#breadcrumbs', '[typeof="v:Breadcrumb"]', '.skip-link', '.search', '.search-form',
    '.categories', '.post-categories', '.datas', '.post-datas', '.twitter-media',
    '.instagram-media', '.widget', '.related-post-tags', '.social-list', '.top-scroll',
    '.comments', '.signature', '.publicite', '.footer', '.Footer', '.footer-copyright',
    '[itemprop*="author"]', '[style*="display:none;"]', '[style*="display:none"]',
    '[style*="display: none;"]', '[style*="display: none"]', '[aria-hidden="true"]'
  ]

  def text
    # require 'byebug'; byebug
    @text ||= find_text
  end

  protected

  def find_text
    text = find_text_with_json_ld || find_text_with_nokogiri
    text.to_s.dup.gsub!('<br><br>', '<br>')
    # require 'byebug'; byebug
    text = clean_encoding text
    text
  end

  def find_text_with_json_ld
    if json_ld.any?
      json_ld.each do |ld|
        next unless ['NewsArticle', 'ReportageNewsArticle'].include? ld['@type']
        return ld['text'] if ld.has_key? 'text'
        return ld['articleBody'] if ld.has_key? 'articleBody'
      end
    end
    nil
  end

  def find_text_with_nokogiri
    h = nokogiri.dup
    h.xpath('//style').remove
    BLACKLIST.each do |tag|
      h.css(tag).remove
    end
    nodes = h.css('p')
    if nodes.any? 
      text = nodes.to_html
      text
    else
      # Cleanup was too hard, let's try softer
      h = nokogiri.dup
      h.text
    end
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
      # require 'byebug'; byebug
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