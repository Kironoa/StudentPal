package com.example.mobile_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.widget.RemoteViews
import android.view.View
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.max

class StudentPalWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val SHARED_PREFS_NAME = "HomeWidgetPlugin"
        private const val KEY_TITLE = "widget_title"
        private const val KEY_SUBTITLE = "widget_subtitle"
        private const val KEY_COUNTDOWN = "widget_countdown"
        private const val KEY_TYPE = "widget_type"
        private const val KEY_EMPTY_MESSAGE = "widget_empty_message"
        private const val KEY_DEADLINE_TIMESTAMP = "widget_deadline_timestamp"
        private const val KEY_NICKNAME = "widget_nickname"

        private const val ACTION_TICK = "com.example.mobile_app.WIDGET_TICK"
        private const val ACTION_FORCE_UPDATE = "com.example.mobile_app.WIDGET_FORCE_UPDATE"

        private var tickHandler: Handler? = null
        private var tickRunnable: Runnable? = null
        private var isTicking = false
        private var storedDeadlineMillis: Long = 0

        private fun getSharedPreferences(context: Context): SharedPreferences {
            return context.getSharedPreferences(SHARED_PREFS_NAME, Context.MODE_PRIVATE)
        }

        fun triggerForceUpdate(context: Context) {
            val intent = Intent(context, StudentPalWidgetProvider::class.java).apply {
                action = ACTION_FORCE_UPDATE
            }
            context.sendBroadcast(intent)
        }

        private fun startTicking(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, deadlineMillis: Long) {
            storedDeadlineMillis = deadlineMillis

            if (isTicking) return
            isTicking = true

            tickHandler = Handler(Looper.getMainLooper())
            tickRunnable = object : Runnable {
                override fun run() {
                    val remaining = max(0L, deadlineMillis - System.currentTimeMillis())
                    val hours = remaining / 3600000
                    val minutes = (remaining % 3600000) / 60000

                    val views = RemoteViews(context.packageName, R.layout.widget_layout)
                    views.setTextViewText(R.id.widget_countdown, String.format("%02d:%02d", hours, minutes))
                    views.setViewVisibility(R.id.widget_empty_message, View.GONE)
                    views.setViewVisibility(R.id.widget_content, View.VISIBLE)

                    appWidgetManager.partiallyUpdateAppWidget(appWidgetId, views)

                    tickHandler?.postDelayed(this, 1000)
                }
            }
            tickHandler?.post(tickRunnable!!)
        }

        private fun stopTicking() {
            isTicking = false
            tickHandler?.removeCallbacksAndMessages(null)
            tickHandler = null
            tickRunnable = null
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_TICK -> {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val thisAppWidget = android.content.ComponentName(context, StudentPalWidgetProvider::class.java)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(thisAppWidget)
                for (appWidgetId in appWidgetIds) {
                    updateAppWidget(context, appWidgetManager, appWidgetId)
                }
            }
            ACTION_FORCE_UPDATE -> {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val thisAppWidget = android.content.ComponentName(context, StudentPalWidgetProvider::class.java)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(thisAppWidget)
                for (appWidgetId in appWidgetIds) {
                    updateAppWidget(context, appWidgetManager, appWidgetId)
                }
            }
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleNextUpdate(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        stopTicking()
        cancelNextUpdate(context)
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout)

        val prefs = getSharedPreferences(context)
        val title = prefs.getString(KEY_TITLE, "") ?: ""
        val subtitle = prefs.getString(KEY_SUBTITLE, "") ?: ""
        val countdown = prefs.getString(KEY_COUNTDOWN, "") ?: ""
        val type = prefs.getString(KEY_TYPE, "empty") ?: "empty"
        val emptyMessage = prefs.getString(KEY_EMPTY_MESSAGE, "Stay Productive!") ?: "Stay Productive!"
        val deadlineTimestamp = prefs.getLong(KEY_DEADLINE_TIMESTAMP, 0L)
        val nickname = prefs.getString(KEY_NICKNAME, "") ?: ""

        stopTicking()

        if (type == "empty" || title.isEmpty()) {
            views.setViewVisibility(R.id.widget_empty_message, View.VISIBLE)
            views.setViewVisibility(R.id.widget_content, View.GONE)
            views.setTextViewText(R.id.widget_empty_message, emptyMessage.ifEmpty { "Stay Productive!" })
        } else {
            views.setViewVisibility(R.id.widget_empty_message, View.GONE)
            views.setViewVisibility(R.id.widget_content, View.VISIBLE)
            if (nickname.isNotEmpty()) {
                views.setTextViewText(R.id.widget_nickname, "@$nickname")
                views.setViewVisibility(R.id.widget_nickname, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_nickname, View.GONE)
            }
            views.setTextViewText(R.id.widget_subtitle, subtitle)
            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_countdown, countdown.ifEmpty { "00:00" })

            if (deadlineTimestamp > System.currentTimeMillis()) {
                startTicking(context, appWidgetManager, appWidgetId, deadlineTimestamp)
            }
        }

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            data = android.net.Uri.parse("studentpal://widget")
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun scheduleNextUpdate(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, StudentPalWidgetProvider::class.java).apply {
            action = ACTION_TICK
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            System.currentTimeMillis() + 60000,
            pendingIntent
        )
    }

    private fun cancelNextUpdate(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, StudentPalWidgetProvider::class.java).apply {
            action = ACTION_TICK
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }
}
