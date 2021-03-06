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
extern bool OnlyProfit       = true;
extern int  Magic            = 0;

int         DIGITS;
double      POINT;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
      DIGITS   = MarketInfo(Symbol(), MODE_DIGITS);
      POINT    = MarketInfo(Symbol(), MODE_POINT);
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
      int orderType, ticket;
      double trailingStop;
      
      for (int order = 0; order < OrdersTotal(); order++) {  
         if (OrderSelect(order, SELECT_BY_POS) == true) {  
            if (OrderValid()) {
               orderType = OrderType();
               trailingStop = GetTrailingStop(orderType);
               if (StopLossValid(orderType, trailingStop)) {
                  ticket = OrderTicket();
                  SetTrailingStop(ticket, trailingStop);
               }
            }
         }
      }
      
      Sleep(1000);
  }
//+------------------------------------------------------------------+

double GetTrailingStop(int orderType)
{
   return GetLastFractal(orderType);
}

void SetTrailingStop(int ticket, double stopLoss) 
{
   bool error;
   
   error=OrderModify(
      ticket, 
      OrderOpenPrice(), 
      NormalizeDouble(stopLoss, DIGITS),
      OrderTakeProfit(),
      0,
      Red
   );
   
   if (!error) {
      Print("Error order ", ticket, " TrailingStop ", GetLastError(), "   ", Symbol(), "   SL ", stopLoss);
      Comment("Error order ", ticket, " TrailingStop ", GetLastError(), "   ", Symbol(), "   SL ", stopLoss);
   }
}

double GetLastFractal(int orderType)
{
   int mode, shift = 0;
   double fractalValue = 0;
      
   switch (orderType) {
      case OP_BUY:
         mode = MODE_LOWER;
         break;
      case OP_SELL:
         mode = MODE_UPPER;
         break;
      default:
         return 0;      
   }
     
   for (shift=1; shift<100; shift++) {
      fractalValue = iFractals(NULL, 0, mode, shift);
      if (fractalValue) {
         return fractalValue;
      }
   }
   
   return 0;
}

bool OrderValid() 
{
   bool isCurrentSymbol, isMagicFit, isOrderTypeAllowed;
   
   isCurrentSymbol      = OrderSymbol() == Symbol();
   isMagicFit           = OrderMagicNumber() == Magic || Magic == 0;
   isOrderTypeAllowed   = OrderType() < 2;
   
   return isCurrentSymbol && isMagicFit && isOrderTypeAllowed;
}

bool StopLossValid(int orderType, double stopLoss) 
{
   return StopLossValidateProfit(orderType, stopLoss) 
      && StopLossValidateValue(orderType, stopLoss);
}

bool StopLossValidateProfit(int orderType, double stopLoss)
{
   if (OnlyProfit) {
      if (OP_BUY == orderType) {
         return stopLoss >= OrderOpenPrice();
      } else if (OP_SELL == orderType) {
         return stopLoss <= OrderOpenPrice();
      } else {
         Print("Invalid orderType: ", orderType);
         return false;
      }
   }
   
   return true;
}

bool StopLossValidateValue(int orderType, double stopLoss)
{
      double currentStopLoss;
      
      if (stopLoss) {
         currentStopLoss = OrderStopLoss();
         if (currentStopLoss) {
               if (OP_BUY == orderType) {
                  return stopLoss > currentStopLoss;
               } else if (OP_SELL == orderType) {
                  return stopLoss < currentStopLoss;
               }
         }
         return true;
      }
      return false;
}