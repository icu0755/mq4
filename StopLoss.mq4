//+------------------------------------------------------------------+
//|                                                       MyTest.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Globals                                                          |
//+------------------------------------------------------------------+
extern int  ProfitLevel      = 15;
extern int  Magic            = 0;

int         DIGITS, STOP_LEVEL, SPREAD;
double      POINT;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
      DIGITS   = MarketInfo(Symbol(), MODE_DIGITS);
      POINT    = MarketInfo(Symbol(), MODE_POINT);
      STOP_LEVEL  = MarketInfo(Symbol(), MODE_STOPLEVEL);
      SPREAD  = MarketInfo(Symbol(), MODE_SPREAD);
      if (ProfitLevel < STOP_LEVEL + SPREAD) {
         ProfitLevel = STOP_LEVEL + SPREAD;
      }
      Print("ProfitLevel: ", ProfitLevel);
      return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {   
      for (int order = 0; order < OrdersTotal(); order++) {  
         if (OrderSelect(order, SELECT_BY_POS) == true) {  
            SetOrderStopLoss();
         }
      }
      
      Sleep(1000);
  }
//+------------------------------------------------------------------+

double getSignalLevel()
{
   int orderType;
   double openPrice;
   
   orderType = OrderType();
   openPrice = OrderOpenPrice();
   if (OP_BUY == orderType) {
      return openPrice + ProfitLevel;
   } else if (OP_SELL == orderType) {
      return openPrice - ProfitLevel;
   }
   
   return 0;
}

void SetOrderStopLoss() 
{
   int orderType, openPrice, ticket;
   double signal, price, orderStopLoss, sl;
   
   orderType = OrderType();
   openPrice = OrderOpenPrice();
   orderStopLoss = OrderStopLoss();
   ticket = OrderTicket();
   signal = getSignalLevel();
   
   if (signal != 0) {
      if (OP_BUY == orderType) {
         price = MarketInfo(Symbol(), MODE_ASK);
         sl = openPrice + SPREAD;
         if (price > signal && orderStopLoss != sl) {
            OrderModify(ticket, openPrice, NormalizeDouble(sl, DIGITS), OrderTakeProfit(), 0, Blue);
            Print("OrderModify: set stop loss at ", sl);
         }
      } else if (OP_SELL == orderType) {
         price  = MarketInfo(Symbol(), MODE_ASK);
         sl = openPrice - SPREAD;
         if (price < signal && orderStopLoss != sl) {
            OrderModify(ticket, openPrice, NormalizeDouble(sl, DIGITS), OrderTakeProfit(), 0, Red);
            Print("OrderModify: set stop loss at ", sl);
         }
      }
   }
}