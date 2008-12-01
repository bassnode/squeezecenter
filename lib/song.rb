class Song < RubySqueeze::Item
  attr_reader :artist, :album, :genre
  

  def [](attribute)
    attributes[attribute]
  end

  def by_artist(artist)
    invoke "tracks 0 5000 artist_id:#{artist.id}"
  end
end
