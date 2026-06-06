package com.example.quanlychitieu.quanlychitieu

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val balance = widgetData.getString("balance", "0 đ")
                val income = widgetData.getString("income", "0 đ")
                val expense = widgetData.getString("expense", "0 đ")

                setTextViewText(R.id.tv_balance, balance)
                setTextViewText(R.id.tv_income, income)
                setTextViewText(R.id.tv_expense, expense)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
