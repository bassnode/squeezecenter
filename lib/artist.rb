# artists <start> <itemsPerResponse> <taggedParameters>
class Artist < RubySqueeze::Item
  
  def albums
    @albums ||= Album.by_artist(self)
  end

  def songs
    @songs ||= Song.by_artist(self)
  end

end
