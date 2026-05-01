package com.example.mobile_app
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews

class StudentPalWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val SHARED_PREFS_NAME = "HomeWidgetPlugin"
        
        // Current Class
        private const val KEY_CURRENT_SUBJECT = "widget_current_subject"
        private const val KEY_CURRENT_TIME = "widget_current_time"
        private const val KEY_CURRENT_VISIBLE = "widget_current_visible"
        
        // Next Class
        private const val KEY_NEXT_SUBJECT = "widget_next_subject"
        private const val KEY_NEXT_COUNTDOWN = "widget_next_countdown"
        private const val KEY_NEXT_VISIBLE = "widget_next_visible"
        
        // Today's Schedule
        private const val KEY_SCHEDULE_COUNT = "widget_schedule_count"
        private const val KEY_SCHEDULE_VISIBLE = "widget_schedule_visible"
        
        // Assignments
        private const val KEY_ASSIGNMENTS_COUNT = "widget_assignments_count"
        private const val KEY_ASSIGNMENTS_VISIBLE = "widget_assignments_visible"
        
        // Error state
        private const val KEY_ERROR_MESSAGE = "widget_error_message"
        private const val KEY_HAS_ERROR = "widget_has_error"

        private fun prefs(context: Context): SharedPreferences =
            context.getSharedPreferences(SHARED_PREFS_NAME, Context.MODE_PRIVATE)
    }

    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray) {
        for (id in ids) updateAppWidget(context, mgr, id)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == "com.example.mobile_app.WIDGET_FORCE_UPDATE") {
            val mgr = AppWidgetManager.getInstance(context)
            val cn = android.content.ComponentName(context, StudentPalWidgetProvider::class.java)
            for (id in mgr.getAppWidgetIds(cn)) updateAppWidget(context, mgr, id)
        }
    }

    private fun updateAppWidget(context: Context, mgr: AppWidgetManager, widgetId: Int) {
        val p = prefs(context)
        
        val hasError = p.getBoolean(KEY_HAS_ERROR, false)
        val errorMessage = p.getString(KEY_ERROR_MESSAGE, "") ?: ""
        
        val views = RemoteViews(context.packageName, R.layout.widget_layout)
        
        if (hasError || errorMessage.isNotEmpty()) {
            // Show error state
            views.setViewVisibility(R.id.widget_empty_state, View.VISIBLE)
            views.setViewVisibility(R.id.widget_grid, View.GONE)
            views.setTextViewText(R.id.widget_empty_message, errorMessage.ifEmpty { "Oops! Something went wrong" })
            views.setTextViewText(R.id.widget_empty_sub, "Tap to open StudentPal")
        } else {
            // Show grid
            views.setViewVisibility(R.id.widget_empty_state, View.GONE)
            views.setViewVisibility(R.id.widget_grid, View.VISIBLE)
            
            // Current Class Section
            val currentVisible = p.getBoolean(KEY_CURRENT_VISIBLE, false)
            if (currentVisible) {
                val currentSubject = p.getString(KEY_CURRENT_SUBJECT, "--") ?: "--"
                val currentTime = p.getString(KEY_CURRENT_TIME, "") ?: ""
                views.setTextViewText(R.id.widget_current_subject, currentSubject)
                views.setTextViewText(R.id.widget_current_time, currentTime)
            } else {
                views.setTextViewText(R.id.widget_current_subject, "No class")
                views.setTextViewText(R.id.widget_current_time, "right now")
            }
            
            // Next Class Section
            val nextVisible = p.getBoolean(KEY_NEXT_VISIBLE, false)
            if (nextVisible) {
                val nextSubject = p.getString(KEY_NEXT_SUBJECT, "--") ?: "--"
                val nextCountdown = p.getString(KEY_NEXT_COUNTDOWN, "--") ?: "--"
                views.setTextViewText(R.id.widget_next_subject, nextSubject)
                views.setTextViewText(R.id.widget_next_countdown, nextCountdown)
            } else {
                views.setTextViewText(R.id.widget_next_subject, "No more")
                views.setTextViewText(R.id.widget_next_countdown, "classes today")
            }
            
            // Today's Schedule Section
            val scheduleVisible = p.getBoolean(KEY_SCHEDULE_VISIBLE, false)
            val scheduleCount = p.getInt(KEY_SCHEDULE_COUNT, 0)
            if (scheduleVisible) {
                views.setTextViewText(R.id.widget_schedule_count, scheduleCount.toString())
                views.setTextViewText(R.id.widget_schedule_sublabel, 
                    if (scheduleCount == 1) "class left" else "classes left")
            } else {
                views.setTextViewText(R.id.widget_schedule_count, "0")
                views.setTextViewText(R.id.widget_schedule_sublabel, "classes left")
            }
            
            // Assignments Section
            val assignmentsVisible = p.getBoolean(KEY_ASSIGNMENTS_VISIBLE, false)
            val assignmentsCount = p.getInt(KEY_ASSIGNMENTS_COUNT, 0)
            if (assignmentsVisible) {
                views.setTextViewText(R.id.widget_assignments_count, assignmentsCount.toString())
                views.setTextViewText(R.id.widget_assignments_sublabel,
                    if (assignmentsCount == 1) "pending" else "pending")
            } else {
                views.setTextViewText(R.id.widget_assignments_count, "0")
                views.setTextViewText(R.id.widget_assignments_sublabel, "pending")
            }
        }
        
        // Set click intent to open app
        val tap = PendingIntent.getActivity(
            context, 0,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, tap)
        
        mgr.updateAppWidget(widgetId, views)
    }
}
