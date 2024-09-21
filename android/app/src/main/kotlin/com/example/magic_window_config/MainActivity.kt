package com.example.magic_window_config

import android.annotation.TargetApi
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "get_activities_channel" // 与Flutter端的通道名称保持一致

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getActivities") {
                val packageName = call.arguments as String
                val activities = getActivities(packageName)
                result.success(activities)
            } else {
                result.notImplemented()
            }
        }
    }


    private fun getActivities(packageName: String): List<String> {
//        val activityNames = mutableListOf<String>()
//        val intent = Intent()
//        intent.`package` = packageName
//        val pManager: PackageManager = getPackageManager()
//        val activities: List<ResolveInfo> = pManager.queryIntentActivities(intent, PackageManager.MATCH_ALL)
//        for (info in activities) {
//            activityNames.add(info.activityInfo.name)
//        }
//        return activityNames

        val activityNames = mutableListOf<String>()
        try {
            //Get all activity classes in the AndroidManifest.xml
            val packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)


            val appPackageInfo = if (true) {
                packageInfo
            } else {
                val pmFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    PackageManager.MATCH_DISABLED_COMPONENTS
                } else {
                    PackageManager.GET_DISABLED_COMPONENTS
                }
                packageManager.getPackageArchiveInfo(
                    packageInfo.applicationInfo.sourceDir,
                    PackageManager.GET_ACTIVITIES or pmFlag
                )
            }

            appPackageInfo?.activities?.let { activities ->
                for (ai in activities) {
                    activityNames.add(ai.name)
                }
            }
        } catch (exception: PackageManager.NameNotFoundException) {
            exception.printStackTrace()
        } catch (exception: RuntimeException) {
            exception.printStackTrace()
        }

        return activityNames
    }
}
