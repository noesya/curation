module Title

  def title
    @title ||= find_title.strip.gsub(/\s+/, ' ')
  end

  protected

  def find_title
    find_title_with_json_ld ||
    find_title_with_metainspector ||
    find_title_with_nokogiri ||
    ''
  end

  def find_title_with_json_ld
    if json_ld.any?
      json_ld.each do |ld|
        # require 'byebug'; byebug
        ld = ld.first if ld.is_a?(Array)
        return ld['headline'] if ld.has_key? 'headline'
      end
    end
    false
  end

  def find_title_with_metainspector
    metainspector_best_title = metainspector.best_title
    metainspector_title = metainspector.title
    # Problème avec une balise <meta property="title" content="Run 0"  />,
    # metainspector croit que c'est le titre de la page.
    # Comme le title contient le best title, avec souvent des infos en plus sur le site, 
    # on vérifie si le best title est bien contenu dans le title
    if  metainspector_title.present? && 
        metainspector_title.present? &&
        metainspector_best_title.present? && 
        metainspector_title.include?(metainspector_best_title)
      return metainspector_best_title
    elsif metainspector_title.present?
      return metainspector_title
    end
    false
  end

  def find_title_with_nokogiri
    begin
      [
        nokogiri.css('[itemprop="headline"]')&.first&.inner_text,
        nokogiri.css('title')&.first&.inner_text
      ].each do |possibility|
        return possibility unless possibility.to_s.empty?
      end
    rescue
      log 'Curation::Page find_title_with_nokogiri error'
    end
  end

end