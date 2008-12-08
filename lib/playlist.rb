class RubySqueeze::Playlist

  def initialize(api, player)
    @api, @player = api, player
  end
  
  def tracks
    playlist_query("tracks 0 1000")
  end
  
  def total_tracks
    playlist_query("tracks").to_i
  end
  
  def stop
    playlist_command :stop
  end
  
  def play
    playlist_command :play
  end
  
  def pause
    playlist_command :pause
  end
  
  def skip_track(count=1)
    playlist_query "index +#{count}"
  end
  
  def current_mode
    @api.invoke("#{@player.id} mode ?")
  end
  
  # Replaces current playlist with passed +opts+, eg:
  #  playlist.load(:album => 22)
  def load(opts)
    playlist_control :load, opts
  end
  
  # Removes all tracks from the playlist
  def clear
    playlist_control :delete
  end

  # Removes passed +opts+ to from current playlist, eg:
  #  playlist.delete(:artist => 212)  
  def delete(opts)
    playlist_control :delete, opts
  end
  
  # Adds passed +opts+ to end of current playlist, eg:
  #  playlist.append(:artist => 12)  
  def append(opts)
    playlist_control :add, opts
  end
  
  # Adds passed +opts+ to beginning of current playlist, eg:
  #  playlist.prepend(:genre => 2)
  def prepend(opts)
    playlist_control :insert, opts
  end
  
  # eg: track_information(:artist, 0)
  def track_information(information_type, index)
    playlist_query("#{information_type.to_s} #{index}")
  end
  
  def currently_playing
    playlist_query("index").to_i
  end
  
  def newsong
    @api.invoke("#{@player.id} playlist newsong")    
  end
  
  protected
    def playlist_query(query)
      @api.invoke("#{@player.id} playlist #{query} ?", false)
    end
    
    def playlist_command(command)
      @api.invoke("#{@player.id} #{command}", false)
    end
    
    def playlist_control(command, opts={})
      command = "#{@player.id} playlistcontrol cmd:#{command} "
      opts.each { |opt, val| command << "#{opt.to_s}_id:#{val.to_s} "}
      @api.invoke(command.strip).to_i
    end
    
    def set_mode(mode)
      @api.invoke("#{@player.id} #{mode.to_s}").eql?(false)
    end
end