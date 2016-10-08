events = require 'events'
require 'coffee-react/register'
PlayerView = require('./player-view').PlayerView
PlayerComponent = require('./player-view').PlayerComponent

module.exports =
class Player
  constructor: (@cantik) ->
    events.EventEmitter.call(@)

    @playing = false
    @playingTrack = {}

  activate: (state) ->
    @playerView = new PlayerView(@, @cantik)

  deactivate: ->
    if @centralAreaView?
      @playerView.destroy()

  serialize: ->
    playerViewState: @playerView.serialize()

  getLastTrack: ->
    @cantik.pluginManager.plugins.playlist.getLastTrack.bind(@cantik.pluginManager.plugins.playlist)()

  getNextTrack: ->
    @cantik.pluginManager.plugins.playlist.getNextTrack.bind(@cantik.pluginManager.plugins.playlist)()

  playTrack: (track) ->
    if track?
      @playingTrack = track
      @emit('track_changed', track)
    @playing = true
    @emit('play_state_changed', @)

  play: ->
    # Need to play
    if not @playing
      # No track -> getTrackToPlay
      if Object.keys(@playingTrack).length is 0
        @playTrack @getNextTrack()
      else
        do @playTrack

      @playing = true
      @emit('play_state_changed', @)

    # Need to pause
    else
      @playing = false
      @emit('play_state_changed', @)

  back: ->
    @playTrack @getLastTrack()

  next: ->
    @playTrack @getNextTrack()

Player.prototype.__proto__ = events.EventEmitter.prototype
