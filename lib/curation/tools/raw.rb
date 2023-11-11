module Raw

  def file
    @file ||= URI.open url, 'User-Agent' => "Mozilla/5.0"
  rescue
    log "Curation::Page file error with url #{url}"
  end

  def html
    unless @html
      file.rewind
      @html = file.read
      file.rewind
    end
    @html
  rescue
    log "Curation::Page html error"
  end
end