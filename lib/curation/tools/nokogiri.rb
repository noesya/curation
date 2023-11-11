module Nokogiri

  def nokogiri
    unless @nokogiri
      if file.nil?
        @nokogiri = metainspector.parsed
      else
        file.rewind
        @nokogiri = Nokogiri::HTML file
        file.rewind
      end
    end
    @nokogiri
  rescue
    log 'Curation::Page nokogiri error'
  end
end