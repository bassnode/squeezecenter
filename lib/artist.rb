# artists <start> <itemsPerResponse> <taggedParameters>
class Artist < RubySqueeze::Item
  attr_reader :albums, :songs

  def initialize(id)
    @id = id
  end
  
  def albums
    @albums ||= Album.by_artist(self)
  end

  def songs
    @songs ||= Song.by_artist(self)
  end

end
