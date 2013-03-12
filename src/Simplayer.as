package {
  import flash.display.LoaderInfo;
  import flash.display.MovieClip;

  import flash.events.Event;
  import flash.events.KeyboardEvent;

  import flash.external.ExternalInterface;

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

  [SWF(width="1280", height="720")]
  public class Simplayer extends MovieClip {
    public var parameters:Object;
    public var src:String;

    public var mediaFactory:MediaFactory;
    public var playerSprite:MediaPlayerSprite;
    public var metadata:Object;
    public var resource:URLResource;

    public function Simplayer() {
      parameters = LoaderInfo(this.root.loaderInfo).parameters;

//      if ("src" in parameters)
//        src = parameters["src"];
//      else
//        src = "http://lvh.me/tmp/eugenia.mp4";
//        src = "http://lvh.me/tmp/bial-hds.f4m#fallback_source";
//        src = "http://ec2-23-20-247-100.compute-1.amazonaws.com/hds-vod-drm/tcplay/748579-comeco.mp4.f4m";

      src = "http://vimeo.com/24543244/download?t=1363121492&v=53197526&s=5d32f116bf8c620fda95b8303527d991";

      if (!!stage)
        init();
      else
        addEventListener(Event.ADDED_TO_STAGE, init);
    }

    protected function log(message:String):void {
      trace(message);
      if (ExternalInterface.available)
        ExternalInterface.call("console.log", message);
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

//      var element:SerialElement = new SerialElement();
//      element.addChild(mediaFactory.createMediaElement(resource));
//      element.addChild(mediaFactory.createMediaElement(resource));

      var element:MediaElement = mediaFactory.createMediaElement(resource);

      log("has time trait: " + element.hasTrait(MediaTraitType.TIME));

      playerSprite = new MediaPlayerSprite();
      playerSprite.media = element;

      playerSprite.mediaPlayer.autoPlay = true;
      playerSprite.mediaPlayer.addEventListener(MediaPlayerCapabilityChangeEvent.HAS_ALTERNATIVE_AUDIO_CHANGE, hasAlternativeAudioChanged);
      playerSprite.mediaPlayer.addEventListener(AlternativeAudioEvent.AUDIO_SWITCHING_CHANGE, alternativeAudioSwitchChanged);

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
