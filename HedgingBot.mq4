//+------------------------------------------------------------------+
//|                                                   HedgingBot.mq4 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// Input parameters
extern double TakeProfit = 100.0;
extern double StopLoss = 200.0;

double upperBand = iBands(NULL, 0, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, 0);
double lowerBand = iBands(NULL, 0, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, 0);

double entryPrice = 0.0;
int MarketOrder = 0;
int MarketOrderType;
double HedgeOrder1Price;
int HedgeOrder1Type;
double HedgeOrder2Price;
int HedgeOrder2Type;
double HedgeOrder3Price;
int HedgeOrder3Type;
int HedgeOrder1 = 0;
int HedgeOrder2 = 0;
int HedgeOrder3 = 0;
int HedgeOrder4 = 0;
int HedgeOrder5 = 0;
int HedgeOrder6 = 0;
int HedgeOrder7 = 0;

// Risk management
double MarketOrderRisk = 0.0025;
double HedgeOrder1Risk = 0.0075;
double HedgeOrder2Risk = 0.015;  
double HedgeOrder3Risk = 0.03; 
double HedgeOrder4Risk = 0.06;  
double HedgeOrder5Risk = 0.12;  
double HedgeOrder6Risk = 0.24;
double HedgeOrder7Risk = 0.48;

bool isOrderOpenedToday = false;
bool isHedgeOrder1OpenedToday = false;
bool isHedgeOrder2OpenedToday = false;
bool isHedgeOrder3OpenedToday = false;
bool isHedgeOrder4OpenedToday = false;
bool isHedgeOrder5OpenedToday = false;
bool isHedgeOrder6OpenedToday = false;
bool isHedgeOrder7OpenedToday = false;

datetime lastOrderCloseTime;
datetime lastOrderOpenTime;

bool isAnyOrderClosedToday() {
   for(int i = OrdersHistoryTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
         if(TimeDay(OrderCloseTime()) == TimeDay(TimeCurrent())) {
            return true;
         }
      }
   }
   return false;
}

void CloseAllOrders() {
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS)) {
         OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3);
      }
   }
}

double CalculateLotSize(double risk) {
   double balance = AccountBalance();
   double lotSize = (balance * risk) / StopLoss;
   return NormalizeDouble(lotSize, 2);
}

double CalculateVolatility() {
   int VolatilityPeriod = 5;
   int Mode = 0;
   int Price1 = 2;
   int Price2 = 3;
   return (iMA("USDJPY", 0, VolatilityPeriod, 0, Mode, Price1, 0) - iMA("USDJPY", 0, VolatilityPeriod, 0, Mode, Price2, 0)) * 100;
}

bool IsLondonSession() {
   datetime currTime = TimeCurrent();
   int currHour = TimeHour(currTime);
   return (currHour >= 8 && currHour < 17);
}

int start() {
   double volatility = CalculateVolatility();
   double highVolatilityThreshold = 15.0; // Set this to the value that you consider as high volatility
// Kiểm tra xem ngày hiện tại có khác với ngày mà lệnh cuối cùng được mở hay không
if (TimeDay(lastOrderOpenTime) != TimeDay(TimeCurrent())) {
   // Nếu khác, đặt lại các biến
   isOrderOpenedToday = false;
   isHedgeOrder1OpenedToday = false;
   isHedgeOrder2OpenedToday = false;
   isHedgeOrder3OpenedToday = false;
   isHedgeOrder4OpenedToday = false;
   isHedgeOrder5OpenedToday = false;
   isHedgeOrder6OpenedToday = false;
   isHedgeOrder7OpenedToday = false;
}

if(isAnyOrderClosedToday()) {
   CloseAllOrders();
   lastOrderCloseTime = TimeCurrent(); // Cập nhật thời gian đóng lệnh cuối cùng
   isOrderOpenedToday = true;
   isHedgeOrder1OpenedToday = true;
   isHedgeOrder2OpenedToday = true;
   isHedgeOrder3OpenedToday = true;
   isHedgeOrder4OpenedToday = true;
   isHedgeOrder5OpenedToday = true;
   isHedgeOrder6OpenedToday = true;
   isHedgeOrder7OpenedToday = true;
}

// Check if there are no open orders
   if (OrdersTotal() == 0) {
      MarketOrder = 0;
      HedgeOrder1 = 0;
      HedgeOrder2 = 0;
      HedgeOrder3 = 0;
      HedgeOrder4 = 0;
      HedgeOrder5 = 0;
      HedgeOrder6 = 0;
      HedgeOrder7 = 0;
   }
   if (TimeCurrent() - lastOrderCloseTime >= 12 * 60 * 60) {
      if (MarketOrder == 0 && IsLondonSession() && !isOrderOpenedToday && volatility > highVolatilityThreshold) {
         double lotSize = CalculateLotSize(MarketOrderRisk);
         if (Close[0] > upperBand) {
         // Buy when RSI is below 30 and price is above the upper Bollinger Band
            entryPrice = Ask;
            OrderSend(Symbol(), OP_BUY, lotSize, Ask, 3, Ask - StopLoss * Point, Ask + TakeProfit * Point, "Buy Order", 12345, 0, Green);
            MarketOrder = 1;
            MarketOrderType = OP_BUY;
            isOrderOpenedToday = true;
         } else if (Close[0] < lowerBand) {
         // Sell when RSI is above 70 and price is below the lower Bollinger Band
            entryPrice = Bid;
            OrderSend(Symbol(), OP_SELL, lotSize, Bid, 3, Bid + StopLoss * Point, Bid - TakeProfit * Point, "Sell Order", 12345, 0, Red);
            MarketOrder = 1;
            MarketOrderType = OP_SELL;
            isOrderOpenedToday = true;
         }
      } else if (HedgeOrder1 == 0 && MarketOrder == 1 && !isHedgeOrder1OpenedToday) {
         double lotSize = CalculateLotSize(HedgeOrder1Risk);
         if(MarketOrderType == OP_BUY && (entryPrice - Bid) >= 100 * Point) {
            // Open a sell order if the price drops 100 pips below the buy order entry price
            OrderSend(Symbol(), OP_SELL, lotSize, Bid, 3, Bid + StopLoss * Point, Bid - TakeProfit * Point, "Sell Order", 12345, 0, Red);
            HedgeOrder1 = 1;
            HedgeOrder1Price = Bid;
            HedgeOrder1Type = OP_SELL;
            isHedgeOrder1OpenedToday = true;
         } else if(MarketOrderType == OP_SELL && (Ask - entryPrice) >= 100 * Point) {
            // Open a buy order if the price rises 100 pips above the sell order entry price
            OrderSend(Symbol(), OP_BUY, lotSize, Ask, 3, Ask - StopLoss * Point, Ask + TakeProfit * Point, "Buy Order", 12345, 0, Green);
            HedgeOrder1 = 1;
            HedgeOrder1Price = Ask;
            HedgeOrder1Type = OP_BUY;
            isHedgeOrder1OpenedToday = true;
         }
      } else if (HedgeOrder2 == 0 && HedgeOrder1 == 1 && MathAbs(Ask - entryPrice) <= 10 * Point && !isHedgeOrder2OpenedToday) {
      double lotSize = CalculateLotSize(HedgeOrder2Risk);
      if(MarketOrderType == OP_BUY) {
         OrderSend(Symbol(), OP_BUY, lotSize, Ask, 3, Ask - StopLoss * Point, Ask + TakeProfit * Point, "Buy Order", 12345, 0, Green);
         HedgeOrder2 = 1;
         HedgeOrder2Price = Ask;
         HedgeOrder2Type = OP_BUY;
         isHedgeOrder2OpenedToday = true;
      } else if(MarketOrderType == OP_SELL) {
         OrderSend(Symbol(), OP_SELL, lotSize, Bid, 3, Bid + StopLoss * Point, Bid - TakeProfit * Point, "Sell Order", 12345, 0, Red);
         HedgeOrder2 = 1;
         HedgeOrder2Price = Bid;
         HedgeOrder2Type = OP_SELL;
         isHedgeOrder2OpenedToday = true;
      }
   } else if (HedgeOrder3 == 0 && HedgeOrder2 == 1 && MathAbs(Ask - HedgeOrder1Price) <= 10 * Point && !isHedgeOrder3OpenedToday) {
         double lotSize = CalculateLotSize(HedgeOrder3Risk);
         if(HedgeOrder1Type == OP_BUY) {
            // Open a buy order if the price returns to the buy order entry price of HedgeOrder1
            OrderSend(Symbol(), OP_BUY, lotSize, Ask, 3, Ask - StopLoss * Point, Ask + TakeProfit * Point, "Buy Order", 12345, 0, Green);
            HedgeOrder3 = 1;
            isHedgeOrder3OpenedToday = true;
         } else if(HedgeOrder1Type == OP_SELL) {
            // Open a sell order if the price returns to the sell order entry price of HedgeOrder1
            OrderSend(Symbol(), OP_SELL, lotSize, Bid, 3, Bid + StopLoss * Point, Bid - TakeProfit * Point, "Sell Order", 12345, 0, Red);
            HedgeOrder3 = 1;
            isHedgeOrder3OpenedToday = true;
         }
      } 
      else if (HedgeOrder4 == 0 && HedgeOrder3 == 1 && MathAbs(Ask - HedgeOrder2Price) <= 10 * Point && !isHedgeOrder4OpenedToday) {
      double lotSize = CalculateLotSize(HedgeOrder4Risk);
      if(HedgeOrder2Type == OP_BUY) {
         // Open a buy order if the price returns to the buy order entry price of HedgeOrder2
         OrderSend(Symbol(), OP_BUY, lotSize, Ask, 3, Ask - StopLoss * Point, Ask + TakeProfit * Point, "Buy Order", 12345, 0, Green);
         HedgeOrder4 = 1;
         isHedgeOrder4OpenedToday = true;
      } else if(HedgeOrder2Type == OP_SELL) {
         // Open a sell order if the price returns to the sell order entry price of HedgeOrder2
         OrderSend(Symbol(), OP_SELL, lotSize, Bid, 3, Bid + StopLoss * Point, Bid - TakeProfit * Point, "Sell Order", 12345, 0, Red);
         HedgeOrder4 = 1;
         isHedgeOrder4OpenedToday = true;
      }
   } else if (HedgeOrder5 == 0 && HedgeOrder4 == 1 && MathAbs(Ask - HedgeOrder1Price) <= 10 * Point && !isHedgeOrder5OpenedToday) {
      double lotSize = CalculateLotSize(HedgeOrder5Risk);
      if(HedgeOrder1Type == OP_BUY) {
         // Open a buy order if the price returns to the buy order entry price of HedgeOrder1
         OrderSend(Symbol(), OP_BUY, lotSize, Ask, 3, Ask - StopLoss * Point, Ask + TakeProfit * Point, "Buy Order", 12345, 0, Green);
         HedgeOrder5 = 1;
         isHedgeOrder5OpenedToday = true;
      } else if(HedgeOrder1Type == OP_SELL) {
         // Open a sell order if the price returns to the sell order entry price of HedgeOrder1
         OrderSend(Symbol(), OP_SELL, lotSize, Bid, 3, Bid + StopLoss * Point, Bid - TakeProfit * Point, "Sell Order", 12345, 0, Red);
         HedgeOrder5 = 1;
         isHedgeOrder5OpenedToday = true;
      }
   } else if (HedgeOrder6 == 0 && HedgeOrder5 == 1 && MathAbs(Ask - HedgeOrder2Price) <= 10 * Point && !isHedgeOrder6OpenedToday) {
   double lotSize = CalculateLotSize(HedgeOrder6Risk);
   if(HedgeOrder2Type == OP_BUY) {
      // Open a buy order if the price returns to the buy order entry price of HedgeOrder2
      OrderSend(Symbol(), OP_BUY, lotSize, Ask, 3, Ask - StopLoss * Point, Ask + TakeProfit * Point, "Buy Order", 12345, 0, Green);
      HedgeOrder6 = 1;
      isHedgeOrder6OpenedToday = true;
   } else if(HedgeOrder2Type == OP_SELL) {
      // Open a sell order if the price returns to the sell order entry price of HedgeOrder2
      OrderSend(Symbol(), OP_SELL, lotSize, Bid, 3, Bid + StopLoss * Point, Bid - TakeProfit * Point, "Sell Order", 12345, 0, Red);
      HedgeOrder6 = 1;
      isHedgeOrder6OpenedToday = true;
   }
} else if (HedgeOrder7 == 0 && HedgeOrder6 == 1 && MathAbs(Ask - HedgeOrder1Price) <= 10 * Point && !isHedgeOrder7OpenedToday) {
   double lotSize = CalculateLotSize(HedgeOrder7Risk);
   if(HedgeOrder1Type == OP_BUY) {
      // Open a buy order if the price returns to the buy order entry price of HedgeOrder1
      OrderSend(Symbol(), OP_BUY, lotSize, Ask, 3, Ask - StopLoss * Point, Ask + TakeProfit * Point, "Buy Order", 12345, 0, Green);
      HedgeOrder7 = 1;
      isHedgeOrder7OpenedToday = true;
   } else if(HedgeOrder1Type == OP_SELL) {
      // Open a sell order if the price returns to the sell order entry price of HedgeOrder1
      OrderSend(Symbol(), OP_SELL, lotSize, Bid, 3, Bid + StopLoss * Point, Bid - TakeProfit * Point, "Sell Order", 12345, 0, Red);
      HedgeOrder7 = 1;
      isHedgeOrder7OpenedToday = true;
   }
}
}
   return(0);
}
//+------------------------------------------------------------------+