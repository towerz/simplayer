package {
  import flash.display.LoaderInfo;
  import flash.display.MovieClip;

  import flash.events.Event;
  import flash.events.KeyboardEvent;
  import flash.events.MouseEvent;

  import flash.external.ExternalInterface;

  import flash.geom.Rectangle;

  import flash.system.Security;

  import flash.ui.Keyboard;

  import flash.utils.setTimeout;

  import org.osmf.events.AlternativeAudioEvent;
  import org.osmf.events.LoadEvent;
  import org.osmf.events.MediaElementEvent;
  import org.osmf.events.MediaPlayerCapabilityChangeEvent;
  import org.osmf.events.MediaPlayerStateChangeEvent;
  import org.osmf.events.TimeEvent;

  import org.osmf.media.DefaultMediaFactory;
  import org.osmf.media.MediaElement;
  import org.osmf.media.MediaFactory;
  import org.osmf.media.MediaPlayerSprite;
  import org.osmf.media.URLResource;

  import org.osmf.traits.MediaTraitType;

  [SWF(width="640", height="360")]
  public class Simplayer extends MovieClip {
    protected var _parameters:Object;
    protected var _src:String;
    protected var _callbackName:String;

    protected var _mediaFactory:MediaFactory;
    protected var _playerSprite:MediaPlayerSprite;
    protected var _resource:URLResource;
    protected var _audios:Object;

    protected var _seekTime:Number;

    public function Simplayer() {
      Security.allowDomain("*");
      Security.allowInsecureDomain("*");
      ExternalInterface.marshallExceptions = true;
      _parameters = LoaderInfo(this.root.loaderInfo).parameters;
      _callbackName = _parameters["callback"];
      _addExternalCallbacks();
      _addExternalGetters();
      setTimeout(_pingJavascript, 50);
    }

    protected function _addEventListeners():void {
      _playerSprite.mediaPlayer.addEventListener(MediaPlayerStateChangeEvent.MEDIA_PLAYER_STATE_CHANGE, _onStateChanged);
      _playerSprite.mediaPlayer.addEventListener(TimeEvent.CURRENT_TIME_CHANGE, _onCurrentTimeChanged);
      _playerSprite.mediaPlayer.addEventListener(TimeEvent.COMPLETE, _onComplete);
    }

    protected function _addExternalCallbacks():void {
      ExternalInterface.addCallback("playerLoad", _load);
      ExternalInterface.addCallback("playerPlay", _play);
      ExternalInterface.addCallback("playerPause", _pause);
      ExternalInterface.addCallback("playerSeek", _seek);
      ExternalInterface.addCallback("playerStop", _stop);
      ExternalInterface.addCallback("playerSelectAudioItem", _selectAudioItem);
      ExternalInterface.addCallback("playerSetVolume", _setVolume);
    }

    protected function _addExternalGetters():void {
      ExternalInterface.addCallback("getDuration", _getDuration);
      ExternalInterface.addCallback("getPosition", _getPosition);
      ExternalInterface.addCallback("getVolume", _getVolume);
      ExternalInterface.addCallback("getAudioItems", _getAudioItems);
      ExternalInterface.addCallback("getCurrentAudioItem", _getCurrentAudioItem);
      ExternalInterface.addCallback("getCurrentAudioItemIndex", _getCurrentAudioItemIndex);
      ExternalInterface.addCallback("getAudioItem", _getAudioItem);
      ExternalInterface.addCallback("getAudioItemCount", _getAudioItemCount);
      ExternalInterface.addCallback("getBytesLoaded", _getBytesLoaded);
      ExternalInterface.addCallback("getBytesTotal", _getBytesTotal);
      ExternalInterface.addCallback("canPlay", _canPlay);
      ExternalInterface.addCallback("canPause", _canPause);
      ExternalInterface.addCallback("canSeek", _canSeek);
      ExternalInterface.addCallback("isMuted", _isMuted);
      ExternalInterface.addCallback("isPlaying", _isPlaying);
      ExternalInterface.addCallback("hasAlternativeAudio", _hasAlternativeAudio);
    }

    protected function _pingJavascript() : void {
      _trigger("ready");
      ("src" in _parameters) && _load(_parameters["src"]);
    };

    protected function _getBytesLoaded():Number {
      return _playerSprite.mediaPlayer.bytesLoaded;
    }

    protected function _getBytesTotal():Number {
      return _playerSprite.mediaPlayer.bytesTotal;
    }

    protected function _getDuration():Number {
      return _playerSprite.mediaPlayer.duration;
    }

    protected function _getPosition():Number {
      return _playerSprite.mediaPlayer.currentTime;
    }

    protected function _getVolume(): Number {
      return _playerSprite.mediaPlayer.volume;
    }

    protected function _getAudioItems():Object {
      var items: Object = {0: _getAudioItem(0)};
      for (var i:int = 0; i <  _playerSprite.mediaPlayer.numAlternativeAudioStreams; i++) {
        items[i + 1] = _getAudioItem(i + 1);
      }
      return items;
    }

    protected function _getAudioItem(index:int):Object {
      if (index === 0) {
        return {type: "audio", info: { label: "default", language: "und"}};
      }
      return _playerSprite.mediaPlayer.getAlternativeAudioItemAt(index - 1);
    }

    protected function _getAudioItemCount():int {
      if (_playerSprite.mediaPlayer.hasAlternativeAudio) {
        return 1 + _playerSprite.mediaPlayer.numAlternativeAudioStreams;
      }
      return 1;
    }

    protected function _getCurrentAudioItemIndex():Number {
      return _playerSprite.mediaPlayer.currentAlternativeAudioStreamIndex;
    }

    protected function _getCurrentAudioItem():Object {
      return _getAudioItem(_playerSprite.mediaPlayer.currentAlternativeAudioStreamIndex);
    }

    protected function _isMuted():Boolean {
      if (!_playerSprite) {
        return false;
      }
      return _playerSprite.mediaPlayer.muted;
    }

    protected function _isPlaying():Boolean {
      if (!_playerSprite) {
        return false;
      }
      return _playerSprite.mediaPlayer.playing;
    }

    protected function _hasAlternativeAudio():Boolean {
      if (!_playerSprite) {
        return false;
      }
      return _playerSprite.mediaPlayer.hasAlternativeAudio;
    }

    protected function _canPlay():Boolean {
      if (!_playerSprite) {
        return false;
      }
      return _playerSprite.mediaPlayer.canPlay;
    }

    protected function _canPause():Boolean {
      if (!_playerSprite) {
        return false;
      }
      return _playerSprite.mediaPlayer.canPause;
    }

    protected function _canSeek():Boolean {
      if (!_playerSprite) {
        return false;
      }
      return _playerSprite.mediaPlayer.canSeek;
    }

    protected function _play():void {
      if (!_isPlaying() && _canPlay()) {
        _playerSprite.mediaPlayer.play();
      }
    }

    protected function _pause():void {
      if (_isPlaying() && _canPause()) {
        _playerSprite.mediaPlayer.pause();
      }
    }

    protected function _stop():void {
      if (_isPlaying()) {
        _playerSprite.mediaPlayer.stop();
      }
    }

    protected function _seek(time: Number):void {
      _seekTime = time;
      if (_canSeek() && _playerSprite.mediaPlayer.canSeekTo(time)) {
        _playerSprite.mediaPlayer.seek(time);
        _seekTime = -1;
      }
    }

    protected function _selectAudioItem(index: int):void {
      if (index !== _playerSprite.mediaPlayer.currentAlternativeAudioStreamIndex + 1 &&
          index <= _playerSprite.mediaPlayer.numAlternativeAudioStreams) {
        _playerSprite.mediaPlayer.switchAlternativeAudioIndex(index - 1);
      }
    }

    protected function _setVolume(volume: Number): void {
      _playerSprite.mediaPlayer.volume = volume;
    }

    protected function _load(url:String):void {
      _src = url;
      if (!!stage) {
        init();
      } else {
        addEventListener(Event.ADDED_TO_STAGE, init);
      }
    }

    protected function _onStageResize(event : Event) : void {
      stage.fullScreenSourceRect = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
      _playerSprite.width = stage.stageWidth;
      _playerSprite.height = stage.stageHeight;
    };

    protected function _trigger(event : String, ...args) : void {
      log("triggering " + event);
      if (ExternalInterface.available && _callbackName) {
        ExternalInterface.call(_callbackName, event, args);
      }
    };

    protected function log(message:String):void {
      trace(message);
      ExternalInterface.available && _parameters.debug && ExternalInterface.call("console.log", message)
    }

    protected function init():void {
      removeEventListener(Event.ADDED_TO_STAGE, init);
      stage.addEventListener(Event.RESIZE, _onStageResize);
      initPlayer();
      _parameters.enableKeyboardShortcuts && stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
      log("ready to play: " + _src);
    }

    protected function initPlayer():void {
      _resource = new URLResource(_src);
      _mediaFactory = new DefaultMediaFactory();

      var element:MediaElement = _mediaFactory.createMediaElement(_resource);

      log("has time trait: " + element.hasTrait(MediaTraitType.TIME));

      _playerSprite = new MediaPlayerSprite();
      _playerSprite.media = element;

      _playerSprite.mediaPlayer.autoPlay = true;
      _playerSprite.mediaPlayer.addEventListener(MediaPlayerCapabilityChangeEvent.HAS_ALTERNATIVE_AUDIO_CHANGE, hasAlternativeAudioChanged);
      _playerSprite.mediaPlayer.addEventListener(AlternativeAudioEvent.AUDIO_SWITCHING_CHANGE, alternativeAudioSwitchChanged);
      _playerSprite.width = _parameters.width || 640;
      _playerSprite.height = _parameters.height || 360;
      addChild(_playerSprite);
      _addEventListeners();
    }

    protected function keyUpHandler(e:KeyboardEvent):void {
      log("key: " + e.keyCode);
      switch (e.keyCode) {
        case (Keyboard.SPACE):
          playPausePressed();
          break;
        case (Keyboard.A):
          swapLanguagePressed();
          break;
        default:
          break;
      }
    }

    protected function playPausePressed():void {
      if (!_playerSprite.mediaPlayer.paused && _playerSprite.mediaPlayer.canPause)
        _playerSprite.mediaPlayer.pause();
      else if (!_playerSprite.mediaPlayer.playing && _playerSprite.mediaPlayer.canPlay)
        _playerSprite.mediaPlayer.play();
    }

    protected function swapLanguagePressed():void {
      if (!_playerSprite.mediaPlayer.alternativeAudioStreamSwitching && _playerSprite.mediaPlayer.hasAlternativeAudio) {
        var current:int = _playerSprite.mediaPlayer.currentAlternativeAudioStreamIndex;
        var total:int = _playerSprite.mediaPlayer.numAlternativeAudioStreams;
        var next:int = current + 1;

        log("next language: " + audioLanguage(next));
        if (next < total) {
          _playerSprite.mediaPlayer.switchAlternativeAudioIndex(next);
        } else {
          _playerSprite.mediaPlayer.switchAlternativeAudioIndex(-1);
        }
      } else {
        log("cannot change language");
      }
    }

    protected function hasAlternativeAudioChanged(e:MediaPlayerCapabilityChangeEvent):void {
      log("hasAlternativeAudioChanged - enabled: " + e.enabled);
      _trigger("hasAlternativeAudioChanged", e.enabled);
    }

    protected function alternativeAudioSwitchChanged(e:AlternativeAudioEvent):void {
      var current:int = _playerSprite.mediaPlayer.currentAlternativeAudioStreamIndex;
      if (e.switching) {
        log("audio switching began - exiting: " + currentAudioLanguage());
      } else {
        log("audio switching ended - now: " + currentAudioLanguage());
      }
      _trigger("alternativeAudioSwitch", e.switching);
    }

    protected function _onCurrentTimeChanged(e:TimeEvent):void{
      log("currentTime changed:" + e.time);
      _trigger("currentTimeChange", e.time);
    }

    protected function _onComplete(e:TimeEvent):void{
      log("complete");
      _trigger("complete");
    }

    protected function _onStateChanged(e:MediaPlayerStateChangeEvent):void{
      log("state changed:" + e.state);
      if (e.state == "playing" && _seekTime > 0) {
        _seek(_seekTime);
      }
      _trigger("stateChange", e.state);
    }

    protected function audioLanguage(languageIndex:int):String {
      var total:int = _playerSprite.mediaPlayer.numAlternativeAudioStreams;
      if (languageIndex > -1 && languageIndex < total) {
        return _playerSprite.mediaPlayer.getAlternativeAudioItemAt(languageIndex).info.label;
      } else {
        return "default";
      }
    }

    protected function currentAudioLanguage():String {
      return audioLanguage(_playerSprite.mediaPlayer.currentAlternativeAudioStreamIndex);
    }
  }
}
