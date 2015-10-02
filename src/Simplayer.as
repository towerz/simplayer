package {
  import flash.display.LoaderInfo;
  import flash.display.MovieClip;

  import flash.events.Event;
  import flash.events.KeyboardEvent;

  import flash.external.ExternalInterface;

  import flash.system.Security;

  import flash.ui.Keyboard;

  import org.osmf.elements.F4MElement;
  import org.osmf.elements.SerialElement;

  import org.osmf.events.AlternativeAudioEvent;
  import org.osmf.events.LoadEvent;
  import org.osmf.events.MediaElementEvent;
  import org.osmf.events.MediaPlayerCapabilityChangeEvent;
  import org.osmf.events.MediaPlayerStateChangeEvent;

  import org.osmf.media.DefaultMediaFactory;
  import org.osmf.media.MediaElement;
  import org.osmf.media.MediaFactory;
  import org.osmf.media.MediaPlayerSprite;
  import org.osmf.media.URLResource;

  import org.osmf.metadata.Metadata;
  import org.osmf.metadata.MetadataNamespaces;

  import org.osmf.traits.MediaTraitType;

  [SWF(width="640", height="360")]
  public class Simplayer extends MovieClip {
    public var parameters:Object;
    public var src:String;

    public var mediaFactory:MediaFactory;
    public var playerSprite:MediaPlayerSprite;
    public var metadata:Object;
    public var resource:URLResource;
    public var audios:Object;

    public function Simplayer() {
      Security.allowDomain("*");
      Security.allowInsecureDomain("*");
      parameters = LoaderInfo(this.root.loaderInfo).parameters;
      _addExternalCallbacks();
      _addExternalGetters();
      ("src" in parameters) && (src = parameters["src"]);
      src && _load(src);
    }

    protected function _addExternalCallbacks():void {
      ExternalInterface.addCallback('playerLoad', _load);
      ExternalInterface.addCallback('playerPlay', _play);
      ExternalInterface.addCallback('playerPause', _pause);
      ExternalInterface.addCallback('playerSelectAudioItem', _selectAudioItem);
    }

    protected function _addExternalGetters():void {
      ExternalInterface.addCallback('getDuration', _getDuration);
      ExternalInterface.addCallback('getPosition', _getPosition);
      ExternalInterface.addCallback('getAudioItem', _getAudioItem);
      ExternalInterface.addCallback('getAudioItemCount', _getAudioItemCount);
      ExternalInterface.addCallback('canPlay', _canPlay);
      ExternalInterface.addCallback('isPlaying', _isPlaying);
    }

    protected function _getDuration():Number {
      return playerSprite.mediaPlayer.duration;
    }

    protected function _getPosition():Number {
      return playerSprite.mediaPlayer.currentTime;
    }

    protected function _getAudioItem(index:int):Object {
      if (index === 0) {
        return {type: "audio", info: { label: "default", language: "und"}};
      }
      return playerSprite.mediaPlayer.getAlternativeAudioItemAt(index - 1);
    }

    protected function _getAudioItemCount():int {
      if (playerSprite.mediaPlayer.hasAlternativeAudio) {
        return 1 + playerSprite.mediaPlayer.numAlternativeAudioStreams;
      }
      return 1;
    }

    protected function _isPlaying():Boolean {
      return playerSprite.mediaPlayer.playing;
    }

    protected function _canPlay():Boolean {
      return playerSprite.mediaPlayer.canPlay;
    }

    protected function _play():void {
      if (!_isPlaying() && _canPlay()) {
        playerSprite.mediaPlayer.play();
      }
    }

    protected function _pause():void {
      if (_isPlaying()) {
        playerSprite.mediaPlayer.pause();
      }
    }

    protected function _selectAudioItem(index: int):void {
      if (index <= playerSprite.mediaPlayer.numAlternativeAudioStreams) {
        playerSprite.mediaPlayer.switchAlternativeAudioIndex(index - 1);
      }
    }

    protected function _load(url:String):void {
      src = url;
      if (!!stage) {
        init();
      } else {
        addEventListener(Event.ADDED_TO_STAGE, init);
      }
    }

    protected function log(message:String):void {
      trace(message);
      ExternalInterface.available && ExternalInterface.call("console.log", message)
    }

    protected function init():void {
      removeEventListener(Event.ADDED_TO_STAGE, init);
      initPlayer();
      stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
      log("ready to play: " + src);
    }

    protected function initPlayer():void {
      resource = new URLResource(src);
      mediaFactory = new DefaultMediaFactory();

      var element:MediaElement = mediaFactory.createMediaElement(resource);

      log("has time trait: " + element.hasTrait(MediaTraitType.TIME));

      playerSprite = new MediaPlayerSprite();
      playerSprite.media = element;

      playerSprite.mediaPlayer.autoPlay = true;
      playerSprite.mediaPlayer.addEventListener(MediaPlayerCapabilityChangeEvent.HAS_ALTERNATIVE_AUDIO_CHANGE, hasAlternativeAudioChanged);
      playerSprite.mediaPlayer.addEventListener(AlternativeAudioEvent.AUDIO_SWITCHING_CHANGE, alternativeAudioSwitchChanged);
      playerSprite.width = parameters.width || 640;
      playerSprite.height = parameters.height || 360;
      addChild(playerSprite);
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
      if (!playerSprite.mediaPlayer.paused && playerSprite.mediaPlayer.canPause)
        playerSprite.mediaPlayer.pause();
      else if (!playerSprite.mediaPlayer.playing && playerSprite.mediaPlayer.canPlay)
        playerSprite.mediaPlayer.play();
    }

    protected function swapLanguagePressed():void {
      if (!playerSprite.mediaPlayer.alternativeAudioStreamSwitching && playerSprite.mediaPlayer.hasAlternativeAudio) {
        var current:int = playerSprite.mediaPlayer.currentAlternativeAudioStreamIndex;
        var total:int = playerSprite.mediaPlayer.numAlternativeAudioStreams;
        var next:int = current + 1;

        log("next language: " + audioLanguage(next));
        if (next < total) {
          playerSprite.mediaPlayer.switchAlternativeAudioIndex(next);
        } else {
          playerSprite.mediaPlayer.switchAlternativeAudioIndex(-1);
        }
      } else {
        log("cannot change language");
      }
    }

    protected function hasAlternativeAudioChanged(e:MediaPlayerCapabilityChangeEvent):void {
      log("hasAlternativeAudioChanged - enabled: " + e.enabled);
    }

    protected function alternativeAudioSwitchChanged(e:AlternativeAudioEvent):void {
      var current:int = playerSprite.mediaPlayer.currentAlternativeAudioStreamIndex;

      if (e.switching) {
        log("audio switching began - exiting: " + currentAudioLanguage());
      } else {
        log("audio switching ended - now: " + currentAudioLanguage());
      }
    }

    protected function audioLanguage(languageIndex:int):String {
      var total:int = playerSprite.mediaPlayer.numAlternativeAudioStreams;
      if (languageIndex > -1 && languageIndex < total) {
        return playerSprite.mediaPlayer.getAlternativeAudioItemAt(languageIndex).info.label;
      } else {
        return "default";
      }
    }

    protected function currentAudioLanguage():String {
      return audioLanguage(playerSprite.mediaPlayer.currentAlternativeAudioStreamIndex);
    }
  }
}
