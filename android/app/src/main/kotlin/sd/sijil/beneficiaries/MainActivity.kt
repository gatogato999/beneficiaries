package sd.sijil.beneficiaries

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pickResult: MethodChannel.Result? = null
    private val pickCode = 4242

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sd.sijil/files")
        channel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "initialFile" -> {
                    result.success(consume(intent))
                }
                "pick" -> {
                    pickResult = result
                    val i = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                    }
                    startActivityForResult(i, pickCode)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        consume(intent)?.let { channel?.invokeMethod("fileOpened", it) }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == pickCode) {
            val r = pickResult
            pickResult = null
            val uri = if (resultCode == Activity.RESULT_OK) data?.data else null
            r?.success(uri?.let { readUri(it) })
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    // Reads a VIEW intent once, then neutralises it so a rotation does not re-import.
    private fun consume(i: Intent?): String? {
        if (i == null || i.action != Intent.ACTION_VIEW) return null
        val uri = i.data ?: return null
        i.action = Intent.ACTION_MAIN
        i.data = null
        return readUri(uri)
    }

    private fun readUri(uri: Uri): String? = try {
        contentResolver.openInputStream(uri)?.use { s ->
            val bytes = s.readBytes()
            if (bytes.size > 5_000_000) null else String(bytes, Charsets.UTF_8)
        }
    } catch (e: Exception) {
        null
    }
}
