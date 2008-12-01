class Album < RubySqueeze::Item
  attr_reader :artist, :genre
  
  def self.by_artist(artist)
    find :artist_id => artist.id
  end
end
