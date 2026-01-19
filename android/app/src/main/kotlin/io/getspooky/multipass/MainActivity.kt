package io.getspooky.multipass

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle

class MainActivity: FlutterActivity() {
    private val CHANNEL = "io.getspooky.multipass/strongbox"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        val strongboxModule = StrongboxModule(context.packageManager)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            strongboxModule.onMethodCall(call, result)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val base64Json = intent?.getStringExtra("import_json_base64")
        if (base64Json != null) {
            // Give Flutter a moment to initialize if necessary
            window.decorView.postDelayed({
                methodChannel?.invokeMethod("autoImportBase64", base64Json)
            }, 1000)
        }

        val route = intent?.getStringExtra("route")
        if (route != null) {
            window.decorView.postDelayed({
                methodChannel?.invokeMethod("navigate", route)
            }, 1500)
        }
    }
}
