package com.example.mobile_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.RemoteViews
import kotlin.math.max

class StudentPalWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val SHARED_PREFS_NAME = "HomeWidgetPlugin"
        private const val KEY_TITLE              = "widget_title"
        private const val KEY_SUBTITLE           = "widget_subtitle"
        private const val KEY_COUNTDOWN          = "widget_countdown"
        private const val KEY_TYPE               = "widget_type"
        private const val KEY_EMPTY_MESSAGE      = "widget_empty_message"
        private const val KEY_DEADLINE_TIMESTAMP = "widget_deadline_timestamp"
        private const val KEY_NICKNAME           = "widget_nickname"

        private const val ACTION_TICK         = "com.example.mobile_app.WIDGET_TICK"
        private const val ACTION_FORCE_UPDATE = "com.example.mobile_app.WIDGET_FORCE_UPDATE"

        private var tickHandler: Handler? = null
        private var tickRunnable: Runnable? = null
        private var isTicking = false

        private fun prefs(context: Context): SharedPreferences =
            context.getSharedPreferences(SHARED_PREFS_NAME, Context.MODE_PRIVATE)

        // home_widget plugin saves all values as Strings; read deadline safely
        private fun readDeadlineMillis(prefs: SharedPreferences): Long {
            return try {
                prefs.getString(KEY_DEADLINE_TIMESTAMP, "0")?.toLongOrNull() ?: 0L
            } catch (e: ClassCastException) {
                prefs.getLong(KEY_DEADLINE_TIMESTAMP, 0L)
            }
        }

        fun triggerForceUpdate(context: Context) {
            context.sendBroadcast(
                Intent(context, StudentPalWidgetProvider::class.java).apply {
                    action = ACTION_FORCE_UPDATE
                }
            )
        }

        private fun startTicking(
            context: Context,
            mgr: AppWidgetManager,
            widgetId: Int,
            deadlineMs: Long
        ) {
            stopTicking()
            isTicking = true
            tickHandler = Handler(Looper.getMainLooper())
            tickRunnable = object : Runnable {
                override fun run() {
                    if (!isTicking) return
                    val remaining = max(0L, deadlineMs - System.currentTimeMillis())
                    val h = remaining / 3_600_000
                    val m = (remaining % 3_600_000) / 60_000
                    val views = RemoteViews(context.packageName, R.layout.widget_layout)
                    views.setTextViewText(R.id.widget_countdown, "%02d:%02d".format(h, m))
                    mgr.partiallyUpdateAppWidget(widgetId, views)
                    if (remaining > 0) tickHandler?.postDelayed(this, 30_000)
                    else isTicking = false
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

    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray) {
        for (id in ids) updateAppWidget(context, mgr, id)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TICK || intent.action == ACTION_FORCE_UPDATE) {
            val mgr = AppWidgetManager.getInstance(context)
            val cn = android.content.ComponentName(context, StudentPalWidgetProvider::class.java)
            for (id in mgr.getAppWidgetIds(cn)) updateAppWidget(context, mgr, id)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleAlarm(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        stopTicking()
        cancelAlarm(context)
    }

    private fun updateAppWidget(context: Context, mgr: AppWidgetManager, widgetId: Int) {
        val p = prefs(context)
        val title      = p.getString(KEY_TITLE, "")                         ?: ""
        val subtitle   = p.getString(KEY_SUBTITLE, "")                      ?: ""
        val countdown  = p.getString(KEY_COUNTDOWN, "")                     ?: ""
        val type       = p.getString(KEY_TYPE, "empty")                     ?: "empty"
        val emptyMsg   = p.getString(KEY_EMPTY_MESSAGE, "Stay Productive!") ?: "Stay Productive!"
        val deadlineMs = readDeadlineMillis(p)
        val nickname   = p.getString(KEY_NICKNAME, "")                      ?: ""

        stopTicking()

        val views = RemoteViews(context.packageName, R.layout.widget_layout)

        if (type == "empty" || title.isEmpty()) {
            views.setViewVisibility(R.id.widget_empty_message, View.VISIBLE)
            views.setViewVisibility(R.id.widget_content,       View.GONE)
            views.setTextViewText(
                R.id.widget_empty_message,
                emptyMsg.ifEmpty { "Stay Productive!" }
            )
        } else {
            views.setViewVisibility(R.id.widget_empty_message, View.GONE)
            views.setViewVisibility(R.id.widget_content,       View.VISIBLE)

            if (nickname.isNotEmpty()) {
                views.setTextViewText(R.id.widget_nickname, "@$nickname")
                views.setViewVisibility(R.id.widget_nickname, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_nickname, View.GONE)
            }

            val accent = if (type == "assignment")
                Color.parseColor("#FFD700")
            else
                Color.parseColor("#00FF7F")

            views.setTextViewText(R.id.widget_subtitle, subtitle.uppercase())
            views.setTextColor(R.id.widget_subtitle, accent)
            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_countdown, countdown.ifEmpty { "00:00" })
            views.setTextColor(R.id.widget_countdown, accent)

            if (deadlineMs > System.currentTimeMillis()) {
                startTicking(context, mgr, widgetId, deadlineMs)
            }
        }

        val tap = PendingIntent.getActivity(
            context, 0,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                data  = Uri.parse("studentpal://widget")
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, tap)

        mgr.updateAppWidget(widgetId, views)
    }

    private fun alarmPendingIntent(context: Context): PendingIntent =
        PendingIntent.getBroadcast(
            context, 1,
            Intent(context, StudentPalWidgetProvider::class.java).apply {
                action = ACTION_TICK
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

    private fun scheduleAlarm(context: Context) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
            .setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                System.currentTimeMillis() + 60_000,
                alarmPendingIntent(context)
            )
    }

    private fun cancelAlarm(context: Context) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
            .cancel(alarmPendingIntent(context))
    }
}
