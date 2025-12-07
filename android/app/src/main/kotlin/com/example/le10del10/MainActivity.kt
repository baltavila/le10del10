package com.example.le10del10

import android.content.pm.PackageManager
import android.content.pm.Signature
import android.os.Build
import android.util.Base64
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import java.security.MessageDigest

class MainActivity : FlutterActivity() {

    override fun onStart() {
        super.onStart()
        printFacebookKeyHash()
    }

    private fun printFacebookKeyHash() {
        val tag = "FBKeyHash"
        try {
            val pkgName = packageName
            val pm = applicationContext.packageManager
            val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                pm.getPackageInfo(pkgName, PackageManager.GET_SIGNING_CERTIFICATES)
            } else {
                @Suppress("DEPRECATION")
                pm.getPackageInfo(pkgName, PackageManager.GET_SIGNATURES)
            }

            val signatures: Array<Signature> = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                info.signingInfo?.apkContentsSigners ?: emptyArray()
            } else {
                @Suppress("DEPRECATION")
                info.signatures ?: emptyArray()
            }

            for (sig in signatures) {
                val md = MessageDigest.getInstance("SHA")
                md.update(sig.toByteArray())
                val keyHash = Base64.encodeToString(md.digest(), Base64.NO_WRAP)
                Log.d(tag, keyHash)
            }
        } catch (e: Exception) {
            Log.e(tag, "Error generating key hash", e)
        }
    }
}
