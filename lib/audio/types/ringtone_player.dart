import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:clock_app/alarm/types/alarm.dart';
import 'package:clock_app/audio/logic/random_start.dart';
import 'package:clock_app/audio/logic/ringtones.dart';
import 'package:clock_app/audio/types/ringtone_manager.dart';
import 'package:clock_app/developer/logic/logger.dart';
import 'package:clock_app/timer/types/timer.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speaker_output/speaker_output.dart';
import 'package:vibration/vibration.dart';

Random random = Random();

class RingtonePlayer {
  static AudioPlayer? _alarmPlayer;
  static AudioPlayer? _timerPlayer;
  static AudioPlayer? _mediaPlayer;
  static AudioPlayer? activePlayer;
  static bool _vibratorIsAvailable = false;
  static bool _stopRisingVolume = false;

  // Chrono Custom: "Also ring on phone speaker". While true, a second copy
  // plays on the built-in speaker (native SpeakerOutput) and the main player
  // goes to Bluetooth.
  static bool _speakerCopyActive = false;
  // Set when Bluetooth disconnects mid-alarm: the main player is silenced and
  // only the speaker copy (alarm volume) keeps playing.
  static bool _mainPlayerMuted = false;
  // Bumped on every play and stop so rising-volume steps from an earlier
  // sound cannot change the volume of a later one.
  static int _playGeneration = 0;

  static Future<void> initialize() async {
    _alarmPlayer ??= AudioPlayer(handleInterruptions: true);
    _timerPlayer ??= AudioPlayer(handleInterruptions: true);
    _mediaPlayer ??= AudioPlayer(handleInterruptions: true);
    _mediaPlayer?.setAndroidAudioAttributes(
      const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
    );
    _vibratorIsAvailable = (await Vibration.hasVibrator()) ?? false;
  }

  static Future<void> playUri(String ringtoneUri,
      {bool vibrate = false,
      LoopMode loopMode = LoopMode.one,
      AndroidAudioUsage channel = AndroidAudioUsage.alarm}) async {
    activePlayer = _mediaPlayer;
    await _play(ringtoneUri, vibrate: vibrate, loopMode: LoopMode.one);
  }

  static Future<void> playAlarm(Alarm alarm,
      {LoopMode loopMode = LoopMode.one}) async {
    await activePlayer?.stop();
    await _stopSpeakerCopy();

    // Dual output only when asked for and Bluetooth audio is connected.
    final bool dual = alarm.alsoRingOnPhoneSpeaker &&
        await SpeakerOutput.isBluetoothOutputConnected();

    _alarmPlayer = AudioPlayer(handleInterruptions: false);
    await _alarmPlayer?.setAndroidAudioAttributes(AndroidAudioAttributes(
      // With dual output the main copy uses media usage, which Android sends
      // to the Bluetooth device; the speaker copy uses alarm usage.
      usage: dual ? AndroidAudioUsage.media : alarm.audioChannel,
      contentType: AndroidAudioContentType.music,
    ));
    activePlayer = _alarmPlayer;
    String uri = await getRingtoneUri(alarm.ringtone);

    logger.t("Playing alarm with uri: $uri (speaker copy: $dual)");

    await _play(uri,
        vibrate: alarm.vibrate,
        loopMode: LoopMode.one,
        volume: alarm.volume / 100,
        secondsToMaxVolume: alarm.risingVolumeDuration.inSeconds,
        startAtRandomPos: alarm.shouldStartMelodyAtRandomPos,
        speakerCopy: dual);
  }

  static Future<void> _stopSpeakerCopy() async {
    if (_speakerCopyActive) await SpeakerOutput.stop();
    _speakerCopyActive = false;
    _mainPlayerMuted = false;
  }

  static Future<void> playTimer(ClockTimer timer,
      {LoopMode loopMode = LoopMode.one}) async {
    await _stopSpeakerCopy();
    await _timerPlayer?.setAndroidAudioAttributes(AndroidAudioAttributes(
      usage: timer.audioChannel,
      contentType: AndroidAudioContentType.music,
    ));
    activePlayer = _timerPlayer;
    await _play(
      timer.ringtone.uri,
      vibrate: timer.vibrate,
      loopMode: LoopMode.one,
      volume: timer.volume / 100,
      secondsToMaxVolume: timer.risingVolumeDuration.inSeconds,
    );
  }

  static Future<void> setVolume(double volume) async {
    logger.t("Setting volume to $volume");
    _stopRisingVolume = true;
    await _applyVolume(volume);
  }

  // Sets the volume on the main player and, if playing, the speaker copy.
  static Future<void> _applyVolume(double volume) async {
    await activePlayer?.setVolume(_mainPlayerMuted ? 0 : volume);
    if (_speakerCopyActive) await SpeakerOutput.setVolume(volume);
  }

  static Future<void> _play(
    String ringtoneUri, {
    bool vibrate = false,
    LoopMode loopMode = LoopMode.one,
    double volume = 1.0,
    int secondsToMaxVolume = 0,
    bool startAtRandomPos = false,
    bool speakerCopy = false,
    // double duration = double.infinity,
  }) async {
    try {
      _stopRisingVolume = false;
      final int generation = ++_playGeneration;

      RingtoneManager.lastPlayedRingtoneUri = ringtoneUri;
      if (_vibratorIsAvailable && vibrate) {
        Vibration.vibrate(pattern: [500, 1000], repeat: 0);
      }
      // activePlayer?.
      await activePlayer?.stop();
      await activePlayer?.setLoopMode(loopMode);
      Duration? duration = await activePlayer
          ?.setAudioSource(AudioSource.uri(Uri.parse(ringtoneUri)));
      logger.t("Duration: $duration");

      // Chrono Custom: pick a start point that is not near the end. Both
      // copies start at the same point.
      final Duration start = startAtRandomPos
          ? randomStartPosition(duration, random)
          : Duration.zero;
      if (start > Duration.zero) {
        logger.t("Starting at position: $start of $duration");
        await activePlayer?.seek(start);
      }
      final double initialVolume = secondsToMaxVolume > 0 ? 0 : volume;
      if (speakerCopy) {
        _mainPlayerMuted = false;
        SpeakerOutput.onBluetoothDisconnected = () {
          // Bluetooth went away: the main copy would now also play on the
          // speaker, slightly out of step. Silence it and keep the speaker
          // copy, which uses the alarm volume.
          logger.t("Bluetooth disconnected, keeping speaker copy only");
          _mainPlayerMuted = true;
          activePlayer?.setVolume(0);
        };
        // Wait until the speaker copy is playing, then start the main copy
        // straight away so the two stay close together.
        _speakerCopyActive = await SpeakerOutput.start(ringtoneUri,
            position: start, volume: initialVolume);
        if (!_speakerCopyActive) {
          logger.e("Speaker copy could not start; playing one copy");
        }
      }
      // Chrono Custom: start at the initial volume without stopping the
      // rising volume steps below (upstream called setVolume here, which set
      // _stopRisingVolume and so cancelled rising volume).
      await _applyVolume(initialVolume);

      // Gradually increase the volume
      if (secondsToMaxVolume > 0) {
        for (int i = 0; i <= 10; i++) {
          Future.delayed(
            Duration(milliseconds: i * (secondsToMaxVolume * 100)),
            () {
              if (!_stopRisingVolume && generation == _playGeneration) {
                _applyVolume((i / 10) * volume);
              }
            },
          );
        }
      }
      // Future.delayed(
      //   Duration(seconds: duration.toInt()),
      //   () async {
      //     await stop();
      //   },
      // );

      // Don't use await here as this will only return after the audio is done
      activePlayer?.play();
    } catch (e) {
      logger.e("Error playing $ringtoneUri: $e");
    }
  }

  static Future<void> pause() async {
    await activePlayer?.pause();
    await _stopSpeakerCopy();
    if (_vibratorIsAvailable) {
      await Vibration.cancel();
    }
  }

  static Future<void> stop() async {
    _playGeneration++;
    await activePlayer?.stop();
    await _stopSpeakerCopy();
    final session = await AudioSession.instance;
    await session.setActive(false);
    if (_vibratorIsAvailable) {
      await Vibration.cancel();
    }
    RingtoneManager.lastPlayedRingtoneUri = "";
    _stopRisingVolume = false;
  }
}
