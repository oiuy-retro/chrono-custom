package com.oiuyretro.chrono.speaker_output

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Chrono Custom: plays a second copy of the alarm sound on the phone's
 * built-in speaker while Bluetooth audio is connected.
 *
 * This is a Flutter plugin (not code in MainActivity) so that it is also
 * registered in the background engine that rings alarms.
 *
 * Routing:
 * - Android 9+ (API 28): MediaPlayer with alarm usage and
 *   setPreferredDevice(TYPE_BUILTIN_SPEAKER).
 * - Android 6 to 8.1 (API 23-27): MediaPlayer with alarm usage and no
 *   preferred device; Android's own policy normally sends alarm sounds to the
 *   speaker.
 * - Below Android 6 Bluetooth output cannot be detected, so Dart never
 *   starts the copy.
 */
class SpeakerOutputPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var flutterAssets: FlutterPlugin.FlutterAssets? = null
    private var audioManager: AudioManager? = null
    private var player: MediaPlayer? = null
    private var deviceCallback: Any? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        flutterAssets = binding.flutterAssets
        audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager?
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopPlayer()
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "status" -> result.success(
                    mapOf(
                        "sdk" to Build.VERSION.SDK_INT,
                        "bluetoothOutput" to isBluetoothOutputConnected(),
                        "canForceSpeaker" to (Build.VERSION.SDK_INT >= 28),
                    )
                )
                "start" -> start(
                    call.argument<String>("uri") ?: "",
                    (call.argument<Number>("positionMs") ?: 0).toInt(),
                    (call.argument<Number>("volume") ?: 1.0).toFloat(),
                    result
                )
                "setVolume" -> {
                    val v = (call.argument<Number>("volume") ?: 1.0).toFloat().coerceIn(0f, 1f)
                    player?.setVolume(v, v)
                    result.success(null)
                }
                "pause" -> {
                    player?.let { if (it.isPlaying) it.pause() }
                    result.success(null)
                }
                "stop" -> {
                    stopPlayer()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in ${call.method}", e)
            result.success(if (call.method == "start") false else null)
        }
    }

    private fun isBluetoothType(type: Int): Boolean = when (type) {
        AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
        AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
        AudioDeviceInfo.TYPE_HEARING_AID,
        AudioDeviceInfo.TYPE_BLE_HEADSET,
        AudioDeviceInfo.TYPE_BLE_SPEAKER,
        AudioDeviceInfo.TYPE_BLE_BROADCAST -> true
        else -> false
    }

    private fun isBluetoothOutputConnected(): Boolean {
        if (Build.VERSION.SDK_INT < 23) return false
        val am = audioManager ?: return false
        return am.getDevices(AudioManager.GET_DEVICES_OUTPUTS).any { isBluetoothType(it.type) }
    }

    private fun builtInSpeaker(): AudioDeviceInfo? {
        if (Build.VERSION.SDK_INT < 23) return null
        return audioManager?.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            ?.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
    }

    private fun setDataSource(mp: MediaPlayer, uri: String) {
        when {
            uri.startsWith("asset:///") -> {
                val name = uri.removePrefix("asset:///")
                val path = flutterAssets?.getAssetFilePathByName(name) ?: name
                context.assets.openFd(path).use {
                    mp.setDataSource(it.fileDescriptor, it.startOffset, it.length)
                }
            }
            uri.startsWith("/") -> mp.setDataSource(uri)
            else -> mp.setDataSource(context, Uri.parse(uri))
        }
    }

    private fun start(uri: String, positionMs: Int, volume: Float, result: MethodChannel.Result) {
        stopPlayer()
        if (Build.VERSION.SDK_INT < 23 || uri.isEmpty()) {
            result.success(false)
            return
        }
        val replied = AtomicBoolean(false)
        fun reply(ok: Boolean) {
            if (replied.compareAndSet(false, true)) mainHandler.post { result.success(ok) }
        }

        val mp = MediaPlayer()
        player = mp
        mp.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()
        )
        setDataSource(mp, uri)
        mp.isLooping = true
        val v = volume.coerceIn(0f, 1f)
        mp.setVolume(v, v)
        if (Build.VERSION.SDK_INT >= 28) {
            builtInSpeaker()?.let { mp.setPreferredDevice(it) }
        }
        mp.setOnErrorListener { _, what, extra ->
            Log.e(TAG, "MediaPlayer error $what/$extra")
            reply(false)
            stopPlayer()
            true
        }
        mp.setOnPreparedListener {
            if (player !== mp) {
                reply(false)
                return@setOnPreparedListener
            }
            if (positionMs > 0 && positionMs < mp.duration) {
                mp.setOnSeekCompleteListener {
                    mp.setOnSeekCompleteListener(null)
                    if (player === mp) mp.start()
                    reply(player === mp)
                }
                mp.seekTo(positionMs)
            } else {
                mp.start()
                reply(true)
            }
        }
        mp.prepareAsync()
        registerDeviceCallback()
    }

    private fun registerDeviceCallback() {
        if (Build.VERSION.SDK_INT < 23 || deviceCallback != null) return
        val cb = object : AudioDeviceCallback() {
            override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) {
                if (player != null && removedDevices.any { isBluetoothType(it.type) } &&
                    !isBluetoothOutputConnected()
                ) {
                    // The Bluetooth copy would now come out of the speaker
                    // too. Keep this (alarm volume) copy and tell Dart to
                    // silence the other one.
                    channel.invokeMethod("bluetoothDisconnected", null)
                }
            }
        }
        audioManager?.registerAudioDeviceCallback(cb, mainHandler)
        deviceCallback = cb
    }

    private fun stopPlayer() {
        if (Build.VERSION.SDK_INT >= 23) {
            (deviceCallback as? AudioDeviceCallback)?.let {
                audioManager?.unregisterAudioDeviceCallback(it)
            }
        }
        deviceCallback = null
        player?.let {
            try {
                it.stop()
            } catch (_: Exception) {
            }
            it.release()
        }
        player = null
    }

    companion object {
        private const val TAG = "SpeakerOutput"
        private const val CHANNEL = "com.oiuyretro.chrono/speaker_output"
    }
}
