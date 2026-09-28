//+------------------------------------------------------------------+
//| Advanced Previous Highs & Lows - MT5                             |
//| Professional multi-timeframe indicator                          |
//+------------------------------------------------------------------+
#property strict
#property version   "4.00"
#property description "Previous completed Day/Week/Month levels for every MT5 chart timeframe"
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   6

input group "Levels"
input bool ShowDaily   = true;
input bool ShowWeekly  = true;
input bool ShowMonthly = true;

input group "Lines"
input bool ShowLines = true;
input int  LineWidth = 2;
input ENUM_LINE_STYLE DailyStyle   = STYLE_SOLID;
input ENUM_LINE_STYLE WeeklyStyle  = STYLE_DASH;
input ENUM_LINE_STYLE MonthlyStyle = STYLE_DOT;
input color DailyHighColor   = clrDodgerBlue;
input color DailyLowColor    = clrTomato;
input color WeeklyHighColor  = clrLimeGreen;
input color WeeklyLowColor   = clrMagenta;
input color MonthlyHighColor = clrGold;
input color MonthlyLowColor  = clrDeepPink;

input group "Labels"
input bool ShowLabels = true;
input bool ShowValues = true;
input int  FontSize = 9;
input string FontName = "Arial";

input group "Zones"
input bool ShowZones = false;
input int  ZonePoints = 20;
input uchar ZoneTransparency = 85;

input group "Alerts"
input bool EnableAlerts = true;
input bool AlertOnTouch = true;
input bool AlertOnBreakout = true;
input bool PushNotification = false;
input int AlertCooldownSeconds = 300;

//--- buffers
double g_dailyHigh[], g_dailyLow[];
double g_weeklyHigh[], g_weeklyLow[];
double g_monthlyHigh[], g_monthlyLow[];

string Prefix = "APHL4_";
datetime LastAlert = 0;
datetime LastAlertBar = 0;
string LastAlertKey = "";

//+------------------------------------------------------------------+
int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME,"Advanced Previous H/L v4");
   ConfigurePlot(0,g_dailyHigh,"Daily High",DailyHighColor,DailyStyle);
   ConfigurePlot(1,g_dailyLow,"Daily Low",DailyLowColor,DailyStyle);
   ConfigurePlot(2,g_weeklyHigh,"Weekly High",WeeklyHighColor,WeeklyStyle);
   ConfigurePlot(3,g_weeklyLow,"Weekly Low",WeeklyLowColor,WeeklyStyle);
   ConfigurePlot(4,g_monthlyHigh,"Monthly High",MonthlyHighColor,MonthlyStyle);
   ConfigurePlot(5,g_monthlyLow,"Monthly Low",MonthlyLowColor,MonthlyStyle);

   EventSetTimer(1);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void ConfigurePlot(const int index,double &buffer[],const string label,
                   const color clr,const ENUM_LINE_STYLE style)
{
   SetIndexBuffer(index,buffer,INDICATOR_DATA);
   ArraySetAsSeries(buffer,true);
   PlotIndexSetInteger(index,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(index,PLOT_LINE_STYLE,style);
   PlotIndexSetInteger(index,PLOT_LINE_WIDTH,MathMax(1,MathMin(5,LineWidth)));
   PlotIndexSetInteger(index,PLOT_LINE_COLOR,clr);
   PlotIndexSetString(index,PLOT_LABEL,label);
   PlotIndexSetDouble(index,PLOT_EMPTY_VALUE,EMPTY_VALUE);
}

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],
                const double &high[],const double &low[],
                const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
{
   if(rates_total < 2) return 0;

   ArraySetAsSeries(time,true);
   int first = (prev_calculated==0 ? rates_total-1 : rates_total-prev_calculated+1);
   if(first > rates_total-1) first = rates_total-1;

   for(int i=first; i>=0; i--)
   {
      if(ShowDaily)
      {
         g_dailyHigh[i]=PreviousHigh(i,PERIOD_D1);
         g_dailyLow[i] =PreviousLow(i,PERIOD_D1);
      }
      else { g_dailyHigh[i]=EMPTY_VALUE; g_dailyLow[i]=EMPTY_VALUE; }

      if(ShowWeekly)
      {
         g_weeklyHigh[i]=PreviousHigh(i,PERIOD_W1);
         g_weeklyLow[i] =PreviousLow(i,PERIOD_W1);
      }
      else { g_weeklyHigh[i]=EMPTY_VALUE; g_weeklyLow[i]=EMPTY_VALUE; }

      if(ShowMonthly)
      {
         g_monthlyHigh[i]=PreviousHigh(i,PERIOD_MN1);
         g_monthlyLow[i] =PreviousLow(i,PERIOD_MN1);
      }
      else { g_monthlyHigh[i]=EMPTY_VALUE; g_monthlyLow[i]=EMPTY_VALUE; }
   }

   // Objects and alerts are updated on every tick, not only on a new bar.
   UpdateObjects();
   CheckAlerts();
   return rates_total;
}

//+------------------------------------------------------------------+
//| Series indexes increase into the past: current period is shift 0,|
//| therefore the previous completed period is shift + 1.            |
//+------------------------------------------------------------------+
double PreviousHigh(const int chartShift,const ENUM_TIMEFRAMES tf)
{
   datetime t=iTime(_Symbol,_Period,chartShift);
   if(t<=0) return EMPTY_VALUE;
   int currentShift=iBarShift(_Symbol,tf,t,false);
   if(currentShift<0) return EMPTY_VALUE;
   int previousShift=currentShift+1;
   if(Bars(_Symbol,tf)<=previousShift) return EMPTY_VALUE;
   double value=iHigh(_Symbol,tf,previousShift);
   return (value>0 ? NormalizeDouble(value,_Digits) : EMPTY_VALUE);
}

double PreviousLow(const int chartShift,const ENUM_TIMEFRAMES tf)
{
   datetime t=iTime(_Symbol,_Period,chartShift);
   if(t<=0) return EMPTY_VALUE;
   int currentShift=iBarShift(_Symbol,tf,t,false);
   if(currentShift<0) return EMPTY_VALUE;
   int previousShift=currentShift+1;
   if(Bars(_Symbol,tf)<=previousShift) return EMPTY_VALUE;
   double value=iLow(_Symbol,tf,previousShift);
   return (value>0 ? NormalizeDouble(value,_Digits) : EMPTY_VALUE);
}

//+------------------------------------------------------------------+
void UpdateObjects()
{
   if(ShowLines)
   {
      DrawLevel("D_H",g_dailyHigh[0],DailyHighColor,DailyStyle);
      DrawLevel("D_L",g_dailyLow[0],DailyLowColor,DailyStyle);
      DrawLevel("W_H",g_weeklyHigh[0],WeeklyHighColor,WeeklyStyle);
      DrawLevel("W_L",g_weeklyLow[0],WeeklyLowColor,WeeklyStyle);
      DrawLevel("M_H",g_monthlyHigh[0],MonthlyHighColor,MonthlyStyle);
      DrawLevel("M_L",g_monthlyLow[0],MonthlyLowColor,MonthlyStyle);
   }
   else
   {
      DeleteObject("D_H"); DeleteObject("D_L"); DeleteObject("W_H");
      DeleteObject("W_L"); DeleteObject("M_H"); DeleteObject("M_L");
   }

   if(ShowLabels)
   {
      DrawLabel("D_H_TXT","PDH",g_dailyHigh[0],DailyHighColor);
      DrawLabel("D_L_TXT","PDL",g_dailyLow[0],DailyLowColor);
      DrawLabel("W_H_TXT","PWH",g_weeklyHigh[0],WeeklyHighColor);
      DrawLabel("W_L_TXT","PWL",g_weeklyLow[0],WeeklyLowColor);
      DrawLabel("M_H_TXT","PMH",g_monthlyHigh[0],MonthlyHighColor);
      DrawLabel("M_L_TXT","PML",g_monthlyLow[0],MonthlyLowColor);
   }
   else
   {
      DeleteObject("D_H_TXT"); DeleteObject("D_L_TXT");
      DeleteObject("W_H_TXT"); DeleteObject("W_L_TXT");
      DeleteObject("M_H_TXT"); DeleteObject("M_L_TXT");
   }

   if(ShowZones)
   {
      DrawZone("D_ZONE",g_dailyHigh[0],g_dailyLow[0],DailyHighColor);
      DrawZone("W_ZONE",g_weeklyHigh[0],g_weeklyLow[0],WeeklyHighColor);
      DrawZone("M_ZONE",g_monthlyHigh[0],g_monthlyLow[0],MonthlyHighColor);
   }
   else { DeleteObject("D_ZONE"); DeleteObject("W_ZONE"); DeleteObject("M_ZONE"); }
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
void DrawLevel(const string id,const double price,const color clr,const ENUM_LINE_STYLE style)
{
   string name=Prefix+id;
   if(price==EMPTY_VALUE || price<=0) { DeleteObject(id); return; }
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_HLINE,0,0,price);
   ObjectSetDouble(0,name,OBJPROP_PRICE,price);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_STYLE,style);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,MathMax(1,MathMin(5,LineWidth)));
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
}

//+------------------------------------------------------------------+
void DrawLabel(const string id,const string text,const double price,const color clr)
{
   string name=Prefix+id;
   if(price==EMPTY_VALUE || price<=0) { DeleteObject(id); return; }
   datetime t=iTime(_Symbol,_Period,0);
   if(t<=0) return;
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_TEXT,0,t,price);
   ObjectMove(0,name,0,t,price);
   string value=text+(ShowValues ? " "+DoubleToString(price,_Digits) : "");
   ObjectSetString(0,name,OBJPROP_TEXT,value);
   ObjectSetString(0,name,OBJPROP_FONT,FontName);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,MathMax(6,FontSize));
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
}

//+------------------------------------------------------------------+
void DrawZone(const string id,const double highPrice,const double lowPrice,const color clr)
{
   if(highPrice==EMPTY_VALUE || lowPrice==EMPTY_VALUE) { DeleteObject(id); return; }
   string name=Prefix+id;
   datetime right=iTime(_Symbol,_Period,0);
   int seconds=PeriodSeconds(_Period);
   if(seconds<=0) seconds=60;
   datetime left=right-(datetime)(seconds*2);
   double pad=ZonePoints*_Point;
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_RECTANGLE,0,left,highPrice+pad,right,lowPrice-pad);
   ObjectMove(0,name,0,left,highPrice+pad);
   ObjectMove(0,name,1,right,lowPrice-pad);
   ObjectSetInteger(0,name,OBJPROP_COLOR,ColorToARGB(clr,ZoneTransparency));
   ObjectSetInteger(0,name,OBJPROP_FILL,true);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
}

//+------------------------------------------------------------------+
void CheckAlerts()
{
   if(!EnableAlerts || Bars(_Symbol,_Period)<2) return;
   double c0=iClose(_Symbol,_Period,0), c1=iClose(_Symbol,_Period,1);
   double h=iHigh(_Symbol,_Period,0), l=iLow(_Symbol,_Period,0);
   CheckOne("PDH",g_dailyHigh[0],c0,c1,h,l,true);
   CheckOne("PDL",g_dailyLow[0],c0,c1,h,l,false);
   CheckOne("PWH",g_weeklyHigh[0],c0,c1,h,l,true);
   CheckOne("PWL",g_weeklyLow[0],c0,c1,h,l,false);
   CheckOne("PMH",g_monthlyHigh[0],c0,c1,h,l,true);
   CheckOne("PML",g_monthlyLow[0],c0,c1,h,l,false);
}

void CheckOne(const string tag,const double level,const double c0,const double c1,
              const double h,const double l,const bool isHigh)
{
   if(level==EMPTY_VALUE || level<=0) return;
   datetime bar=iTime(_Symbol,_Period,0);
   if(AlertOnBreakout)
   {
      bool crossed=(isHigh ? (c0>level && c1<=level) : (c0<level && c1>=level));
      if(crossed) FireAlert(tag+" breakout",level,bar);
   }
   if(AlertOnTouch && h>=level && l<=level)
      FireAlert(tag+" touched",level,bar);
}

void FireAlert(const string text,const double level,const datetime bar)
{
   string key=text+IntegerToString((long)bar);
   if(key==LastAlertKey) return;
   if(TimeCurrent()-LastAlert<AlertCooldownSeconds) return;
   LastAlert=TimeCurrent(); LastAlertKey=key;
   string msg=_Symbol+" "+text+" @ "+DoubleToString(level,_Digits);
   Alert(msg);
   Print("[APHL] "+msg);
   if(PushNotification) SendNotification(msg);
}

//+------------------------------------------------------------------+
void DeleteObject(const string id)
{
   ObjectDelete(0,Prefix+id);
}

void OnTimer()
{
   // Timer keeps the levels/labels current even when ticks are sparse.
   if(Bars(_Symbol,_Period)>0) UpdateObjects();
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   for(int i=ObjectsTotal(0)-1;i>=0;i--)
   {
      string name=ObjectName(0,i);
      if(StringFind(name,Prefix)==0) ObjectDelete(0,name);
   }
}
//+------------------------------------------------------------------+
