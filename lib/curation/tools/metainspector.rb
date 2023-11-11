module Metainspector

  def metainspector
    unless @metainspector
      @metainspector = html.nil?  ? MetaInspector.new(url)
                                  : MetaInspector.new(url, document: html)
    end
    @metainspector
  rescue
    log 'Curation::Page metainspector error'
  end

  def metatags
    @metatags ||= metainspector.meta_tag['name']
  rescue
    log 'Curation::Page metatags error'
  end
end