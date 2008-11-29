class Album < RubySqueeze::Item
  attr_reader :artist, :genre
  
  def by_artist(artist)
    invoke "albums 0 5000 artist_id:#{artist.id}"
  end
end
