sinon = require 'sinon'
assert = require 'assert'
jsdom = require 'mocha-jsdom'

Player = null
PlayerComponent = null

describe "Player Component", ->
  jsdom()

  beforeEach ->
    Player = require '../lib/player'

    view = require '../lib/player-view'
    PlayerComponent = view.PlayerComponent
    @PlayerView = view.PlayerView

    @cantik = {
      'pluginManager': {
        'plugins': {'playlist': {}}
      },
      'utils': {'formatTime': sinon.spy()}
    }
    @cantik.pluginManager.plugins.playlist.on = sinon.spy()
    @player = new Player(@cantik)
    @player.on = sinon.spy()
    @pc = new PlayerComponent({player: @player, cantik: @cantik})
    @pc.setState = sinon.spy()

  it "Initialized", ->
    assert.deepEqual(@pc.state, {
      'playing': @player.playing,
      'playingTrack': @player.playingTrack,
      'currentTime': null,
      'duration': null,
      'mute': false,
      'repeat': @cantik.pluginManager.plugins.playlist.repeat,
      'random': @cantik.pluginManager.plugins.playlist.random
    })

    assert(@player.on.calledWith('track_changed'))
    assert(@player.on.calledWith('play_state_changed'))
    assert(@cantik.pluginManager.plugins.playlist.on.calledWith('random_changed'))
    assert(@cantik.pluginManager.plugins.playlist.on.calledWith('repeat_changed'))

  it "Update Playing Track", ->
    @pc.updatePlayingState = sinon.spy()
    @pc.refs = {audioObject: {load: sinon.spy()}}
    @player.playingTrack = {title: 'toto'}

    do @pc.updatePlayingTrack

    assert(@pc.setState.calledWith({playingTrack: {title: 'toto'}}))

    do @pc.setState.firstCall.args[1].bind(@pc)

    assert(@pc.refs.audioObject.load.called)
    assert(@pc.updatePlayingState.called)

  it "Update Playing State to Play", ->
    @player.playing = true
    @pc.refs = {audioObject: {play: sinon.spy()}}

    do @pc.updatePlayingState

    assert(@pc.setState.calledWith({playing: true}))
    assert(@pc.refs.audioObject.play.called)

  it "Update Playing State to Pause", ->
    @pc.state.playing = true
    @player.playing = false
    @pc.refs = {audioObject: {pause: sinon.spy()}}

    do @pc.updatePlayingState

    assert(@pc.setState.calledWith({playing: false}))
    assert(@pc.refs.audioObject.pause.called)

  it "Update Random", ->
    @cantik.pluginManager.plugins.playlist.random = 'test'

    do @pc.updateRandom

    assert(@pc.setState.calledWith({random: 'test'}))

  it "Update Repeat", ->
    @cantik.pluginManager.plugins.playlist.repeat = 'one'

    do @pc.updateRepeat

    assert(@pc.setState.calledWith({repeat: 'one'}))

  it "Set Random", ->
    @cantik.pluginManager.plugins.playlist.setRandom = sinon.spy()

    @pc.setRandom 'test'

    assert(@cantik.pluginManager.plugins.playlist.setRandom.calledWith('test'))

  it "Switch Repeat State", ->
    @cantik.pluginManager.plugins.playlist.switchRepeatState = sinon.spy()

    do @pc.switchRepeatState

    assert(@cantik.pluginManager.plugins.playlist.switchRepeatState.called)

  it "Update Duration", ->
    @pc.refs = {
      progressBar: {
        noUiSlider: {
          updateOptions: sinon.spy()
        }
      },
      audioObject: {duration: 100}
    }

    do @pc.updateDuration

    assert(@pc.setState.called)
    assert(@pc.refs.progressBar.noUiSlider.updateOptions.calledWith({
      range: {
        min: 0,
        max: 100
      }
    }))

  it "Update Current Time", ->
    @pc.refs = {
      progressBar: {
        noUiSlider: {
          set: sinon.spy()
        }
      },
      audioObject: {currentTime: 100}
    }

    do @pc.updateCurrentTime

    assert(@pc.setState.called)
    assert(@pc.refs.progressBar.noUiSlider.set.calledWith(100))

  it "Set Current Time", ->
    @pc.refs = {
      audioObject: {currentTime: 100}
    }

    @pc.setCurrentTime 250

    assert.deepEqual(@pc.refs.audioObject.currentTime, 250)

  it "End Of Track when Repeat one", ->
    @cantik.pluginManager.plugins.playlist.repeat = 'one'
    @pc.updatePlayingState = sinon.spy()
    @pc.setCurrentTime = sinon.spy()

    do @pc.endOfTrack

    assert(@pc.setCurrentTime.calledWith(0))
    assert.deepEqual(@player.playing, true)
    assert(@pc.updatePlayingState.called)

  it "End Of Track when no Repeat", ->
    @player.next = sinon.spy()

    do @pc.endOfTrack

    assert(@player.next.called)

  it "Set Mute", ->
    @pc.refs = {
      audioObject: {muted: true}
    }

    @pc.setMute false

    assert(@pc.setState.calledWith(mute: false))
    assert.deepEqual(@pc.refs.audioObject.muted, false)

  it "Set Volume", ->
    @pc.refs = {
      audioObject: {volume: 0.5}
    }

    @pc.setVolume 0.8

    assert.deepEqual(@pc.refs.audioObject.volume, 0.8)


  it "Render", ->
    new @PlayerView(@player, {
      'pluginManager': {
        'plugins': {'playlist': {'on': sinon.spy()}}
      },
      'utils': {'formatTime': sinon.spy()}
    })

    # Clean data-react-id
    html = document.getElementsByTagName("body")[0].innerHTML.replace(/ data-reactroot=""/g, '')

    assert.equal(html,
    '<div><div class="panel panel-default" id="player"><audio controls=""></audio><p class="track-artist"><span class="title"></span><span class="artist"></span></p><div class="panel-body"><div class="left-button"><button><i class="material-icons previous">skip_previous</i></button><button><i class="material-icons play">play_arrow</i></button><button><i class="material-icons next">skip_next</i></button></div><span class="elapsed-time"></span><div class="progress"><div class="slider shor progressbar noUi-target noUi-ltr noUi-horizontal noUi-connect"><div class="noUi-base"><div class="noUi-origin noUi-background" style="left: 0%;"><div class="noUi-handle noUi-handle-lower"></div></div></div></div></div><span class="total-time"></span><div class="volume-container"><button class="volume-button"><i class="material-icons volume-icon">volume_up</i></button><div class="slider shor volume noUi-target noUi-ltr noUi-horizontal noUi-connect"><div class="noUi-base"><div class="noUi-origin noUi-background" style="left: 50%;"><div class="noUi-handle noUi-handle-lower"></div></div></div></div></div><div class="right-button"><button class="random"><i class="material-icons">shuffle</i></button></div></div></div></div>')
