//+------------------------------------------------------------------+
//|                    Advanced Previous Highs and Lows MT5           |
//|                         Version 3.5 Professional                  |
//|                    Works on All Timeframes                        |
//+------------------------------------------------------------------+

#property copyright "Copilot - Advanced Trading Tools"
#property version   "3.50"
#property strict
#property description "Professional Advanced Previous Highs and Lows - Multi Timeframe Support"
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots 6

//--- Input Parameters
input group "=== Display Settings ==="
input bool ShowDailyHL = true;           // Show Daily High/Low
input bool ShowWeeklyHL = true;          // Show Weekly High/Low
input bool ShowMonthlyHL = true;         // Show Monthly High/Low

input group "=== Label Settings ==="
input bool ShowLabels = true;            // Show Price Labels
input bool ShowLabelValues = true;       // Show Price Values on Labels
input int LabelFontSize = 9;             // Label Font Size
input string LabelFont = "Arial";        // Label Font Name
input int LabelDistance = 20;            // Label Distance from Right Edge

input group "=== Daily High/Low Settings ==="
input color DailyHighColor = clrBlue;           // Daily High Color
input color DailyLowColor = clrRed;             // Daily Low Color
input int DailyLineWidth = 2;                   // Daily Line Width (1-5)
input ENUM_LINE_STYLE DailyLineStyle = STYLE_SOLID;

input group "=== Weekly High/Low Settings ==="
input color WeeklyHighColor = clrGreen;        // Weekly High Color
input color WeeklyLowColor = clrMagenta;       // Weekly Low Color
input int WeeklyLineWidth = 2;                  // Weekly Line Width (1-5)
input ENUM_LINE_STYLE WeeklyLineStyle = STYLE_DASH;

input group "=== Monthly High/Low Settings ==="
input color MonthlyHighColor = clrOrange;      // Monthly High Color
input color MonthlyLowColor = clrPurple;       // Monthly Low Color
input int MonthlyLineWidth = 2;                // Monthly Line Width (1-5)
input ENUM_LINE_STYLE MonthlyLineStyle = STYLE_DOT;

input group "=== Alert Settings ==="
input bool EnableAlert = true;           // Enable Sound Alerts
input bool EnableNotification = false;   // Enable Push Notifications
input bool AlertOnBreakout = true;       // Alert on Breakout
input bool AlertOnTouch = true;          // Alert on Touch
input int AlertCooldown = 300;           // Alert Cooldown (seconds)

input group "=== Advanced Settings ==="
input bool RoundPrices = true;           // Round Prices to Tick Size
input bool ShowExtendedLines = true;     // Extend lines to right edge

//--- Indicator Buffers
double DailyHighBuff[];
double DailyLowBuff[];
double WeeklyHighBuff[];
double WeeklyLowBuff[];
double MonthlyHighBuff[];
double MonthlyLowBuff[];

//--- Global Variables
string objPrefix = "APHL_";
int alertCount = 0;
datetime lastAlertTime = 0;
datetime lastDailyTime = 0;
datetime lastWeeklyTime = 0;
datetime lastMonthlyTime = 0;

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME, "Adv Prev HL v3.5");
   
   // Setup Daily High/Low
   SetIndexBuffer(0, DailyHighBuff, INDICATOR_DATA);
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(0, PLOT_LINE_STYLE, DailyLineStyle);
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, DailyLineWidth);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, DailyHighColor);
   PlotIndexSetString(0, PLOT_LABEL, "Daily High");

   SetIndexBuffer(1, DailyLowBuff, INDICATOR_DATA);
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(1, PLOT_LINE_STYLE, DailyLineStyle);
   PlotIndexSetInteger(1, PLOT_LINE_WIDTH, DailyLineWidth);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, DailyLowColor);
   PlotIndexSetString(1, PLOT_LABEL, "Daily Low");

   // Setup Weekly High/Low
   SetIndexBuffer(2, WeeklyHighBuff, INDICATOR_DATA);
   PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(2, PLOT_LINE_STYLE, WeeklyLineStyle);
   PlotIndexSetInteger(2, PLOT_LINE_WIDTH, WeeklyLineWidth);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, WeeklyHighColor);
   PlotIndexSetString(2, PLOT_LABEL, "Weekly High");

   SetIndexBuffer(3, WeeklyLowBuff, INDICATOR_DATA);
   PlotIndexSetInteger(3, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(3, PLOT_LINE_STYLE, WeeklyLineStyle);
   PlotIndexSetInteger(3, PLOT_LINE_WIDTH, WeeklyLineWidth);
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, WeeklyLowColor);
   PlotIndexSetString(3, PLOT_LABEL, "Weekly Low");

   // Setup Monthly High/Low
   SetIndexBuffer(4, MonthlyHighBuff, INDICATOR_DATA);
   PlotIndexSetInteger(4, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(4, PLOT_LINE_STYLE, MonthlyLineStyle);
   PlotIndexSetInteger(4, PLOT_LINE_WIDTH, MonthlyLineWidth);
   PlotIndexSetInteger(4, PLOT_LINE_COLOR, MonthlyHighColor);
   PlotIndexSetString(4, PLOT_LABEL, "Monthly High");

   SetIndexBuffer(5, MonthlyLowBuff, INDICATOR_DATA);
   PlotIndexSetInteger(5, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(5, PLOT_LINE_STYLE, MonthlyLineStyle);
   PlotIndexSetInteger(5, PLOT_LINE_WIDTH, MonthlyLineWidth);
   PlotIndexSetInteger(5, PLOT_LINE_COLOR, MonthlyLowColor);
   PlotIndexSetString(5, PLOT_LABEL, "Monthly Low");

   Print("✓ Advanced Previous Highs and Lows Indicator v3.5 initialized successfully");
   Print("✓ Symbol: " + _Symbol + " | Timeframe: " + IntegerToString(_Period));
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Main Calculation                                                 |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if (rates_total < 2)
      return 0;

   int limit;
   if (prev_calculated == 0)
      limit = rates_total - 1;
   else
      limit = rates_total - prev_calculated;

   // Calculate all bars
   for (int i = limit; i >= 0; i--)
   {
      // Daily High/Low
      if (ShowDailyHL)
      {
         DailyHighBuff[i] = GetPreviousHigh(i, PERIOD_D1);
         DailyLowBuff[i] = GetPreviousLow(i, PERIOD_D1);
      }
      else
      {
         DailyHighBuff[i] = 0;
         DailyLowBuff[i] = 0;
      }

      // Weekly High/Low
      if (ShowWeeklyHL)
      {
         WeeklyHighBuff[i] = GetPreviousHigh(i, PERIOD_W1);
         WeeklyLowBuff[i] = GetPreviousLow(i, PERIOD_W1);
      }
      else
      {
         WeeklyHighBuff[i] = 0;
         WeeklyLowBuff[i] = 0;
      }

      // Monthly High/Low
      if (ShowMonthlyHL)
      {
         MonthlyHighBuff[i] = GetPreviousHigh(i, PERIOD_MN1);
         MonthlyLowBuff[i] = GetPreviousLow(i, PERIOD_MN1);
      }
      else
      {
         MonthlyHighBuff[i] = 0;
         MonthlyLowBuff[i] = 0;
      }
   }

   // Update labels and check alerts on new bar
   if (prev_calculated < rates_total)
   {
      if (ShowLabels)
         UpdateLabels();
      
      if (EnableAlert)
         CheckAlerts();
   }

   return rates_total;
}

//+------------------------------------------------------------------+
//| Get Previous High for specific timeframe                         |
//+------------------------------------------------------------------+
double GetPreviousHigh(int barIndex, ENUM_TIMEFRAMES tf)
{
   if (barIndex >= Bars(_Symbol, _Period))
      return 0;

   datetime currentBarTime = iTime(_Symbol, _Period, barIndex);
   if (currentBarTime == 0)
      return 0;

   // Get bar shift on target timeframe
   int tfBarShift = iBarShift(_Symbol, tf, currentBarTime, false);
   
   if (tfBarShift < 1)
      return 0;

   // Get high of previous bar on target timeframe
   double high = iHigh(_Symbol, tf, tfBarShift - 1);
   
   if (RoundPrices)
      high = NormalizeDouble(high, _Digits);

   return high;
}

//+------------------------------------------------------------------+
//| Get Previous Low for specific timeframe                          |
//+------------------------------------------------------------------+
double GetPreviousLow(int barIndex, ENUM_TIMEFRAMES tf)
{
   if (barIndex >= Bars(_Symbol, _Period))
      return 0;

   datetime currentBarTime = iTime(_Symbol, _Period, barIndex);
   if (currentBarTime == 0)
      return 0;

   // Get bar shift on target timeframe
   int tfBarShift = iBarShift(_Symbol, tf, currentBarTime, false);
   
   if (tfBarShift < 1)
      return 0;

   // Get low of previous bar on target timeframe
   double low = iLow(_Symbol, tf, tfBarShift - 1);
   
   if (RoundPrices)
      low = NormalizeDouble(low, _Digits);

   return low;
}

//+------------------------------------------------------------------+
//| Update Labels                                                    |
//+------------------------------------------------------------------+
void UpdateLabels()
{
   if (Bars(_Symbol, _Period) < 2)
      return;

   double currentClose = iClose(_Symbol, _Period, 0);
   datetime currentTime = iTime(_Symbol, _Period, 0);

   // Daily Labels
   if (ShowDailyHL)
   {
      double dailyHigh = DailyHighBuff[0];
      double dailyLow = DailyLowBuff[0];

      if (dailyHigh > 0)
      {
         CreateLabel("DH", dailyHigh, "DH", DailyHighColor);
      }

      if (dailyLow > 0)
      {
         CreateLabel("DL", dailyLow, "DL", DailyLowColor);
      }
   }

   // Weekly Labels
   if (ShowWeeklyHL)
   {
      double weeklyHigh = WeeklyHighBuff[0];
      double weeklyLow = WeeklyLowBuff[0];

      if (weeklyHigh > 0)
      {
         CreateLabel("WH", weeklyHigh, "WH", WeeklyHighColor);
      }

      if (weeklyLow > 0)
      {
         CreateLabel("WL", weeklyLow, "WL", WeeklyLowColor);
      }
   }

   // Monthly Labels
   if (ShowMonthlyHL)
   {
      double monthlyHigh = MonthlyHighBuff[0];
      double monthlyLow = MonthlyLowBuff[0];

      if (monthlyHigh > 0)
      {
         CreateLabel("MH", monthlyHigh, "MH", MonthlyHighColor);
      }

      if (monthlyLow > 0)
      {
         CreateLabel("ML", monthlyLow, "ML", MonthlyLowColor);
      }
   }
}

//+------------------------------------------------------------------+
//| Create or Update Label                                           |
//+------------------------------------------------------------------+
void CreateLabel(string name, double price, string text, color textColor)
{
   string objName = objPrefix + name;
   
   // Delete old label
   ObjectDelete(0, objName);

   // Create new text object
   if (ObjectCreate(0, objName, OBJ_TEXT, 0, TimeCurrent(), price))
   {
      string displayText = text;
      if (ShowLabelValues)
         displayText = text + " " + DoubleToString(price, _Digits);

      ObjectSetString(0, objName, OBJPROP_TEXT, displayText);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, textColor);
      ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, LabelFontSize);
      ObjectSetString(0, objName, OBJPROP_FONT, LabelFont);
      ObjectSetDouble(0, objName, OBJPROP_PRICE, price);
      ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_LEFT_CENTER);
      ObjectSetInteger(0, objName, OBJPROP_BACK, false);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
   }
}

//+------------------------------------------------------------------+
//| Check for Alert Conditions                                       |
//+------------------------------------------------------------------+
void CheckAlerts()
{
   if (Bars(_Symbol, _Period) < 2)
      return;

   double currentClose = iClose(_Symbol, _Period, 0);
   double previousClose = iClose(_Symbol, _Period, 1);
   double currentHigh = iHigh(_Symbol, _Period, 0);
   double currentLow = iLow(_Symbol, _Period, 0);

   // Daily Alerts
   if (ShowDailyHL)
   {
      double dailyHigh = DailyHighBuff[0];
      double dailyLow = DailyLowBuff[0];

      if (dailyHigh > 0)
      {
         // Breakout up
         if (AlertOnBreakout && currentClose > dailyHigh && previousClose <= dailyHigh)
            SendAlert("Daily High Breakout at " + DoubleToString(dailyHigh, _Digits));

         // Touch
         if (AlertOnTouch && currentHigh >= dailyHigh && currentLow < dailyHigh)
            SendAlert("Daily High Touched at " + DoubleToString(dailyHigh, _Digits));
      }

      if (dailyLow > 0)
      {
         // Breakout down
         if (AlertOnBreakout && currentClose < dailyLow && previousClose >= dailyLow)
            SendAlert("Daily Low Breakout at " + DoubleToString(dailyLow, _Digits));

         // Touch
         if (AlertOnTouch && currentLow <= dailyLow && currentHigh > dailyLow)
            SendAlert("Daily Low Touched at " + DoubleToString(dailyLow, _Digits));
      }
   }

   // Weekly Alerts
   if (ShowWeeklyHL)
   {
      double weeklyHigh = WeeklyHighBuff[0];
      double weeklyLow = WeeklyLowBuff[0];

      if (weeklyHigh > 0)
      {
         if (AlertOnBreakout && currentClose > weeklyHigh && previousClose <= weeklyHigh)
            SendAlert("Weekly High Breakout at " + DoubleToString(weeklyHigh, _Digits));

         if (AlertOnTouch && currentHigh >= weeklyHigh && currentLow < weeklyHigh)
            SendAlert("Weekly High Touched at " + DoubleToString(weeklyHigh, _Digits));
      }

      if (weeklyLow > 0)
      {
         if (AlertOnBreakout && currentClose < weeklyLow && previousClose >= weeklyLow)
            SendAlert("Weekly Low Breakout at " + DoubleToString(weeklyLow, _Digits));

         if (AlertOnTouch && currentLow <= weeklyLow && currentHigh > weeklyLow)
            SendAlert("Weekly Low Touched at " + DoubleToString(weeklyLow, _Digits));
      }
   }

   // Monthly Alerts
   if (ShowMonthlyHL)
   {
      double monthlyHigh = MonthlyHighBuff[0];
      double monthlyLow = MonthlyLowBuff[0];

      if (monthlyHigh > 0)
      {
         if (AlertOnBreakout && currentClose > monthlyHigh && previousClose <= monthlyHigh)
            SendAlert("Monthly High Breakout at " + DoubleToString(monthlyHigh, _Digits));

         if (AlertOnTouch && currentHigh >= monthlyHigh && currentLow < monthlyHigh)
            SendAlert("Monthly High Touched at " + DoubleToString(monthlyHigh, _Digits));
      }

      if (monthlyLow > 0)
      {
         if (AlertOnBreakout && currentClose < monthlyLow && previousClose >= monthlyLow)
            SendAlert("Monthly Low Breakout at " + DoubleToString(monthlyLow, _Digits));

         if (AlertOnTouch && currentLow <= monthlyLow && currentHigh > monthlyLow)
            SendAlert("Monthly Low Touched at " + DoubleToString(monthlyLow, _Digits));
      }
   }
}

//+------------------------------------------------------------------+
//| Send Alert                                                       |
//+------------------------------------------------------------------+
void SendAlert(string message)
{
   // Cooldown check
   if (TimeCurrent() - lastAlertTime < AlertCooldown)
      return;

   lastAlertTime = TimeCurrent();
   alertCount++;

   string fullMessage = "⚠️ APHL Alert #" + IntegerToString(alertCount) + 
                       "\n" + _Symbol + " " + IntegerToString(_Period) + "m" +
                       "\n" + message + 
                       "\n" + TimeToString(TimeCurrent());

   // Sound Alert
   Alert(fullMessage);

   // Push Notification
   if (EnableNotification)
      SendNotification(fullMessage);

   // Log
   Print(fullMessage);
}

//+------------------------------------------------------------------+
//| Deinitialization                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Delete all indicator objects
   for (int i = ObjectsTotal(0) - 1; i >= 0; i--)
   {
      string objName = ObjectName(0, i);
      if (StringFind(objName, objPrefix) == 0)
         ObjectDelete(0, objName);
   }

   string reasonText = GetReasonText(reason);
   Print("✓ Advanced Previous Highs and Lows Indicator removed. Reason: " + reasonText);
}

//+------------------------------------------------------------------+
//| Get Deinitialization Reason Text                                 |
//+------------------------------------------------------------------+
string GetReasonText(int reason)
{
   switch (reason)
   {
      case REASON_CHARTCHANGE:    return "Chart Changed";
      case REASON_CHARTCLOSE:     return "Chart Closed";
      case REASON_PARAMETERS:     return "Parameters Changed";
      case REASON_RECOMPILE:      return "Recompiled";
      case REASON_REMOVE:         return "Removed";
      case REASON_TEMPLATE:       return "Template Changed";
      case REASON_INITFAILED:     return "Init Failed";
      case REASON_ACCOUNT:        return "Account Changed";
      default:                    return "Unknown (" + IntegerToString(reason) + ")";
   }
}

//+------------------------------------------------------------------+
