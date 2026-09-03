package com.juicytropic.juicytropicgame

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "orchard/media_pick"
    private val awayName = "orchard/away"
    private val pickRequest = 0x4C29
    private var pendingResult: MethodChannel.Result? = null
    private var away: MethodChannel? = null

    // Guards against parking the same intent twice within THIS Activity
    // instance (onCreate then configureFlutterEngine before the intent is
    // fully neutralized). Cross-process dedup is intentionally NOT done —
    // two separate push taps that carry the same URL are two separate
    // user intents and both must open the WebView.
    private var parkedHrefThisLaunch: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        if (savedInstanceState == null) {
            parkFrom(intent, fromNewIntent = false)
        }
        neutralizeIntent()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "open") {
                    val many = call.argument<Boolean>("many") ?: false
                    openShelf(many, result)
                } else {
                    result.notImplemented()
                }
            }
        away = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, awayName)
        parkFrom(intent, fromNewIntent = false)?.let { href ->
            away?.invokeMethod("awayTap", href)
        }
        neutralizeIntent()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        parkFrom(intent, fromNewIntent = true)?.let { href ->
            away?.invokeMethod("awayTap", href)
        }
        neutralizeIntent()
    }

    private fun neutralizeIntent() {
        val clean = Intent(this, MainActivity::class.java)
        clean.action = Intent.ACTION_MAIN
        clean.addCategory(Intent.CATEGORY_LAUNCHER)
        setIntent(clean)
    }

    private fun parkFrom(intent: Intent?, fromNewIntent: Boolean): String? {
        val href = hrefIn(intent) ?: return null
        val mid = intent?.getStringExtra("google.message_id")
            ?: intent?.getStringExtra("message_id")
        val sent = intent?.hasExtra("google.sent_time") == true
        val view = intent?.action == Intent.ACTION_VIEW
        if (!fromNewIntent && mid == null && !sent && !view) {
            return null
        }

        // In-memory guard: same-launch double-park protection only.
        // Cross-launch dedup is deliberately absent — a repeat push
        // that reuses an earlier URL is still a fresh user intent
        // and must be parked so Dart routes to it.
        if (!fromNewIntent && parkedHrefThisLaunch == href) {
            return null
        }
        parkedHrefThisLaunch = href

        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        prefs.edit()
            .putString("flutter.px_park", href)
            .putBoolean("flutter.px_live_tap", true)
            .putLong("flutter.px_live_tap_at", System.currentTimeMillis())
            .commit()
        return href
    }

    private fun hrefIn(intent: Intent?): String? {
        val extras = intent?.extras ?: return null
        val named = arrayOf(
            "url", "deep_link", "deeplink", "link", "target",
            "landing", "goto", "open_url", "push_url", "href",
        )
        for (key in named) {
            val value = extras.getString(key)?.trim().orEmpty()
            if (isPage(value)) return value
        }
        for (key in extras.keySet()) {
            val value = extras.get(key)?.toString()?.trim().orEmpty()
            if (isPage(value)) return value
        }
        return null
    }

    private fun isPage(value: String): Boolean {
        if (!(value.startsWith("http://") || value.startsWith("https://"))) {
            return false
        }
        val path = value.substringAfter("://").lowercase()
        return !path.endsWith(".jpg") &&
            !path.endsWith(".jpeg") &&
            !path.endsWith(".png") &&
            !path.endsWith(".webp") &&
            !path.endsWith(".gif")
    }

    private fun openShelf(many: Boolean, result: MethodChannel.Result) {
        pendingResult?.success(emptyList<String>())
        pendingResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, many)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        try {
            startActivityForResult(intent, pickRequest)
        } catch (_: Exception) {
            pendingResult = null
            result.success(emptyList<String>())
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickRequest) return

        val result = pendingResult
        pendingResult = null
        if (result == null) return

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<String>())
            return
        }

        val uris = ArrayList<String>()
        val clip = data.clipData
        if (clip != null) {
            for (i in 0 until clip.itemCount) {
                uris.add(clip.getItemAt(i).uri.toString())
            }
        } else {
            data.data?.let { uris.add(it.toString()) }
        }
        result.success(uris)
    }
}
