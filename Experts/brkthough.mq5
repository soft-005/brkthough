//+------------------------------------------------------------------+
//|                                                    brkthrough.mq5 |
//|                                        Copyright 2024, kayc Ltd.by vxcode. |
//|                                                         kayc.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, kayc Ltd."
#property link      "kayc.com"
#property version   "1.00"


#include <Trade\Trade.mqh>
#include <brk.mqh>

#define Bid tick("bid")
#define Ask tick("ask")

//+------------------------------------------------------------------+
input group "";
input group "====== General Settings ====";
input string ProductKey = "V10N-CD56-EU12-JP89-FR74-MN23";
input bool AllowSignalTG = true;
input double lot = 0.01;
input double balSet = 15.0;
input double Maxlot = 13.0;
input int maxSL = 170;
input int minTP = 350;
input int PercentEquityUseable = 30;    // Risk percentage per trade
input int TrailingTP = 100;
input double fixedlots = 0;
input int Magic = 5151;
input int ExpireSec = 6500;
//+------------------------------------------------------------------+
input group "====== Sar Settings ====";
input double sarStep = 0.02;
input double sarMax = 0.2;
//+------------------------------------------------------------------+
input group "====== Atr Settings ====";
input int atrVal = 14;
//+------------------------------------------------------------------+
input group "====== SMa Settings ====";
input int maVal = 145;
//+------------------------------------------------------------------+
input group "====== Box Settings ====";
input double buyerBoxPercent = 0.55;
input double sellerBoxPercent = 0.20;
//+------------------------------------------------------------------+
input group "====== EMA && BB Settings ====";
input int EMA_Short = 20;              // Short EMA period
input int EMA_Long = 50;               // Long EMA period
input int BB_Period = 20;              // Bollinger Bands period
input double BB_Deviation = 2.0;       // Bollinger Bands deviation
//+------------------------------------------------------------------+
input group "======  vol spike Settings ====";
input int barsToCheck = 20;          // Evaluate the last 20 bars
input double spikeThreshold = 1.37;   // 50% increase above average volume ~ 1.4-1.35 decrease/increase by 0.01
//+------------------------------------------------------------------+


CTrade trade;
CGraphicalPanel panel;


   
double emaShort[99999], emaLong[99999], emaShort1, emaLong1, atrValue, bbUpper[99999], bbLower[99999], bbMiddle[99999],bb1,lastDealP;
int BB = 0,BB2 = 0,spike=barsToCheck,chgDealP=0;

string entryCom[10],startdatee="",tgId = "-1002175469046", tgToken = "7452450238:AAGBEyQZo0rQCdWRqVo8sHuFZ96Y_HFjwKM";
ulong Epending[100],EEE[100];
int Etrail[100],entryEPosi[100],pendingEPosi[100],ot=0,pt=0,Eis[100],Elog[100],sar,sar4hr,ma,atr,sarZone[100],
    trendOn=0,trendIs=0,barTotal,barDailyTotal,bar4Hour,avZ[5],volINST[4],volOverall=0,volINSTD[4],volOverallD=0,dayOverall=0,hourOverall=0,dailyTradeLog=0,firstOnHour=0,liveZone=0;
double zone[1000000],initialBal = balSet,Lots=lot,equity =  (double)initialBal * (double)PercentEquityUseable/100,point=0.0;
bool firstTick=false;
ENUM_TIMEFRAMES timeF = PERIOD_CURRENT;
datetime entryExp[10];
double bagVal[100],trending1=0.0,trending2=0.0,entrySL[10],entryTP[10],entryP[10],needbrk=0.0,stopline=0.0;
int check[100],bag[100],bagPE[100],bagStat[100],action=0,swit=0,wilup=0,entryType[10],yesbrk=0,activeTrend=1,newbox=0,posi1Chg=0,posi2Chg=0,usedbox=0,firsttbox=0,noentry =0,isFirst=0,posiLine=0;
bool makevoid=false,MrkOpen=false;
 
 
 
 
//---

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   

 if(ProductKey != "V10N-CD56-EU12-JP89-FR74-MN23") {initialBal=0;Comment(" ERROR :: Invalid Access Key !");}
   if(ProductKey != "V10N-CD56-EU12-JP89-FR74-MN23") {return (INIT_FAILED);}
   if(Period() != PERIOD_M30) {Comment(" ERROR :: Invalid Timeframe, Please Switch from ",timeF," to PERIOD_M30 !");}
   if(Period() != PERIOD_M30) {return (INIT_FAILED);}
   if(initialBal <= 0 || AccountInfoDouble(ACCOUNT_EQUITY) < initialBal) {Print("Account bal Less than BalSet. Topup account. or reduce BalSet!");return (INIT_FAILED);}
    
  Print("[Init success] Date: "+TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
  startdatee=TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);
  Print("isTrade Session Open?: ", trade_session());
  MrkOpen=trade_session();
  //
 // if(!CheckInputs()){return INIT_PARAMETERS_INCORRECT;}
  
  //create panel
  if(!panel.OnInit()){return INIT_FAILED;}

  
   trade.SetExpertMagicNumber(Magic);
   //handleVol = ;//iVolumes(_Symbol,PERIOD_M5,VOLUME_REAL);
   
    sar = iSAR(NULL, PERIOD_CURRENT,sarStep,sarMax);
    sar4hr = iSAR(NULL, PERIOD_H4,sarStep,sarMax);
    ma = iMA(NULL, PERIOD_CURRENT, maVal, 0, MODE_SMA, PRICE_CLOSE);
    atr = iATR(NULL,PERIOD_CURRENT,atrVal);
   
   int barTotal = iBars(NULL,timeF),bar4Hour = iBars(NULL, PERIOD_H4),barDailyTotal = iBars(NULL, PERIOD_D1);
   
   int VDDDV = 10;
   for(int vDigits = _Digits; vDigits > 1; vDigits--){VDDDV=VDDDV*10;}
   point=(double)1/VDDDV;
  
   
   ChartSetInteger(0,CHART_AUTOSCROLL, false);
  ChartSetInteger(0,CHART_SHOW_GRID,0);
  ChartSetInteger(0,CHART_SHOW_VOLUMES,CHART_VOLUME_TICK);
  ChartSetInteger(0,CHART_SHIFT,true);
  ChartSetInteger(0,CHART_AUTOSCROLL,true);
  ChartSetInteger(0,CHART_MODE,CHART_VOLUME_TICK);
  
   
   printf("ACCOUNT_LOGIN =  %d",AccountInfoInteger(ACCOUNT_LOGIN)); 
   printf("ACCOUNT_LEVERAGE =  %d",AccountInfoInteger(ACCOUNT_LEVERAGE)); 
   bool thisAccountTradeAllowed=AccountInfoInteger(ACCOUNT_TRADE_ALLOWED); 
   bool EATradeAllowed=AccountInfoInteger(ACCOUNT_TRADE_EXPERT); 
   ENUM_ACCOUNT_TRADE_MODE tradeMode=(ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE); 
   ENUM_ACCOUNT_STOPOUT_MODE stopOutMode=(ENUM_ACCOUNT_STOPOUT_MODE)AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE); 
  
  
//--- Inform about the possibility to perform a trade operation 
   if(thisAccountTradeAllowed) 
      Print("Trade for this account is permitted"); 
   else 
      Print("Trade for this account is prohibited!"); 
  
//--- Find out if it is possible to trade on this account by Expert Advisors 
   if(EATradeAllowed) 
      Print("Trade by Expert Advisors is permitted for this account"); 
   else 
      Print("Trade by Expert Advisors is prohibited for this account!"); 
  
//--- Find out the account type 
   switch(tradeMode) 
     { 
      case(ACCOUNT_TRADE_MODE_DEMO): 
         Print("This is a demo account"); 
         break; 
      case(ACCOUNT_TRADE_MODE_CONTEST): 
         Print("This is a competition account"); 
         break; 
      default:Print("This is a real account!"); 
     } 
  
//--- Find out the StopOut level setting mode 
   switch(stopOutMode) 
     { 
      case(ACCOUNT_STOPOUT_MODE_PERCENT): 
         Print("The StopOut level is specified percentage"); 
         break; 
      default:Print("The StopOut level is specified in monetary terms"); 
     } 


  
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {//---
// logger();
   panel.Destroy(reason);
   Print("[Summary]   Capital Amt: $ "+DoubleToString(balSet,2)+"  Bal: $ "+DoubleToString(initialBal,2)+"  ||  E1O: "+Elog[1]+", E1L: "+Elog[11]+", E1W: "+Elog[21]+", ||  E2O: "+Elog[2]+", E2L: "+Elog[12]+", E2W: "+Elog[22]+", ||  E3O: "+Elog[3]+", E3L: "+Elog[13]+", E3W: "+Elog[23]);
   Print("[Logged out] log: "+IntegerToString(reason)+" |Date|  From: "+startdatee+" To: "+TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
   ObjectsDeleteAll(0);
   
  }
  
  
  
  
  
ENUM_DAY_OF_WEEK day_of_week;

//+------------------------------------------------------------------+
//| Function: Check if trade session is open and excl. Sat and Sun   |
//+------------------------------------------------------------------+
bool trade_session()
  {
   datetime time_now = TimeCurrent();
   MqlDateTime time;
   TimeToStruct(time_now, time);
   uint week_day_now = time.day_of_week;
   uint seconds_now = (time.hour * 3600) + (time.min * 60) + time.sec;
   if(week_day_now == 0)
      day_of_week = SUNDAY;
   if(week_day_now == 1)
      day_of_week = MONDAY;
   if(week_day_now == 2)
      day_of_week = TUESDAY;
   if(week_day_now == 3)
      day_of_week = WEDNESDAY;
   if(week_day_now == 4)
      day_of_week = THURSDAY;
   if(week_day_now == 5)
      day_of_week = FRIDAY;
   if(week_day_now == 6)
      day_of_week = SATURDAY;
   datetime from, to;
   uint session = 0;
   while(SymbolInfoSessionTrade(_Symbol, day_of_week, session, from, to))
     {
      session++;
     }
   uint trade_session_open_seconds = uint(from);
   uint trade_session_close_seconds = uint(to);
   if(trade_session_open_seconds < seconds_now && trade_session_close_seconds > seconds_now && week_day_now >= 1 && week_day_now <= 5)
      return(true);
   return(false);
  }
  
//+------------------------------------------------------------------+
//| Entry logic based on EMA and Bollinger Bands                     |
//+------------------------------------------------------------------+
void CheckEntries() {
   emaShort1 = iMA(_Symbol, _Period, EMA_Short, 0, MODE_EMA, PRICE_CLOSE);
   emaLong1 = iMA(_Symbol, _Period, EMA_Long, 0, MODE_EMA, PRICE_CLOSE);
   
   CopyBuffer(emaShort1,0,1,2,emaShort);
   CopyBuffer(emaLong1,0,1,2,emaLong);
   
   ArraySetAsSeries(emaShort,true);
   ArraySetAsSeries(emaLong,true);
   
   // Bollinger Bands calculation
   bb1 = iBands(_Symbol, _Period, BB_Period,0, BB_Deviation, PRICE_CLOSE);
   
   CopyBuffer(bb1,0,0,3,bbMiddle);
   CopyBuffer(bb1,1,0,3,bbUpper);
   CopyBuffer(bb1,2,0,3,bbLower);
   
   ArraySetAsSeries(bbMiddle,true);
   ArraySetAsSeries(bbUpper,true);
   ArraySetAsSeries(bbLower,true);

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Check for buy signal
   if (emaShort[1] > emaLong[1] && bid <= bbLower[1] &&  close(1) < ma_vall(1) && BB!=1) {BB=1;//remove ma_vall if 4hrs
      //double stopLoss = bid - StopLossPips * Point;
      //double takeProfit = bid + TakeProfitPips * Point;
      //double lotSize = CalculateLotSize(StopLossPips * Point);
     block("ibands buy "+string(low(1)+" "+time(1,PERIOD_CURRENT)),low(1),low(1)-3000*point,1,1,6,PERIOD_CURRENT,1,2);
      Print("Placing buy order at Bollinger lower band");
      //OrderSend(_Symbol, OP_BUY, lotSize, ask, 0, stopLoss, takeProfit, "Scalping Strategy - Buy", MagicNumber);
   }else if (emaShort[1] < emaLong[1] && ask >= bbUpper[1] &&  close(1) > ma_vall(1) && BB != 2) {BB=2;
     // double stopLoss = ask + StopLossPips * Point;
     // double takeProfit = ask - TakeProfitPips * Point;
      //double lotSize = CalculateLotSize(StopLossPips * Point);
   
     block("ibands sell "+string(low(1)+" "+time(1,PERIOD_CURRENT)),low(1),low(1)-3000*point,1,1,6,PERIOD_CURRENT,1,2);
      Print("Placing sell order at Bollinger upper band");
     // OrderSend(_Symbol, OP_SELL, lotSize, bid, 0, stopLoss, takeProfit, "Scalping Strategy - Sell", MagicNumber);
   }
   
   if(close(1) < bbLower[1] && close(0) > bbLower[0] && close(1) < ma_vall(1) && BB2!=1){BB2=1;
     block("2ibands buy "+string(low(1)+" "+time(1,PERIOD_CURRENT)),low(1),low(1)-3000*point,0,0,9,PERIOD_CURRENT,1,2);
   }else if(close(1) > bbUpper[1] && close(0) < bbUpper[0] &&  close(1) > ma_vall(1) && BB2!=2){BB2=2;
     block("2ibands sell "+string(low(1)+" "+time(1,PERIOD_CURRENT)),low(1),low(1)-3000*point,0,0,9,PERIOD_CURRENT,1,2);
   }
   // Check for sell signal
  
}








/////////////////////////////////////#######################################################
void OnTradeTransaction(
         const MqlTradeTransaction& trans,
         const MqlTradeRequest& request,
         const MqlTradeResult& result
      ){
      
      if(trans.type == TRADE_TRANSACTION_DEAL_ADD){
              HistorySelect(TimeCurrent()-60,TimeCurrent()+60);
              if(HistoryDealGetInteger(trans.deal,DEAL_MAGIC) == Magic && HistoryDealGetString(trans.deal,DEAL_SYMBOL) == _Symbol){
                 CDealInfo deal;
                 CPositionInfo posii;
                 deal.Ticket(trans.deal);
                 
                 if(deal.Entry() == DEAL_ENTRY_IN){
                 
                     for(int in=0;in<10;in++){
                        
                        if(deal.Comment() == (string)("E"+in)){ 
                            if(in==2){isFirst=0;}
                                  
                           if(deal.DealType() == DEAL_TYPE_BUY){
                           Eis[in]=1; if(in == 1) closeall(2);
                           }else if(deal.DealType() == DEAL_TYPE_SELL){
                           Eis[in]=2; if(in == 1) closeall(1);
                           }
                           
                            EEE[in]=posii.Ticket();entryEPosi[in]=1;clearPending(in);clearPending(in+1);Print("cleared by 1 EEE[",in,"]::",EEE[in]);
                          
                            Elog[in]+=1;
                        }                    
                     //--
                    }
                     //Print(" dealin :: S dealcomment: ",deal.Comment()," posicomment: ",posii.Comment());
                
                 }else if(deal.Entry() == DEAL_ENTRY_OUT){
                 
                            lastDealP=deal.Profit();  
                 
                     if(deal.DealType() == DEAL_TYPE_BUY){
                           chgDealP=2; 
                     }else if(deal.DealType() == DEAL_TYPE_SELL){
                           chgDealP=1; 
                     }
                     
                     for(int in=0; in < 10; in++){
                        if(EEE[in] > 0){
                          if(!PositionSelectByTicket(EEE[in])){
                              if((deal.DealType() == DEAL_TYPE_BUY && Eis[in] == 2) || (deal.DealType() == DEAL_TYPE_SELL && Eis[in] == 1)){
                              
                                  if(lastDealP < 0){Elog[10+in]+=1;}else if(lastDealP > 0){Elog[20+in]+=1;}
                                   if((lastDealP < 0 || lastDealP > (minTP+50*Lots)) && in == 2){isFirst=1;}
                                  if(in == 1){closeall(Eis[in]);}
                                  EEE[in]=0;entryEPosi[in]=0;Etrail[in]=0;Eis[in]=0;
                             }
                          }
                        }
                     }
                                             
                     initialBal=initialBal+deal.Profit();
                  //Print(" dealout :: profit: $",deal.Profit()," comment: ",deal.Comment()," deal ticket :",HistoryDealGetInteger(trans.deal,DEAL_TICKET)," posii.Ticket() ",posii.Ticket()," comment4: ",posii.Comment()," coment5: ",request.comment,"");
                 }
                  
                    //pending orders
                   /* for (int pos_0 = 0; pos_0 < OrdersTotal(); pos_0++) {
                     ulong orderTicket = OrderGetTicket(pos_0);
                     //trade.OrderDelete(orderTicket);
                     //trade.OrderModify()
                        if(OrderGetInteger(ORDER_MAGIC) == Magic){
                           if(HistoryDealGetString(trans.deal,DEAL_COMMENT) == "E1"){
                           
                              Print(__FUNCTION__," found EEE[1] #",orderTicket);
                           }
                        }
                     
                    }*/
              } 
      }
      
}//---







//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{

//---
   if(initialBal <= 0 || AccountInfoDouble(ACCOUNT_EQUITY) < initialBal) {OnDeinit(55555);}
   int bars = iBars(NULL, timeF),  hourBars = iBars(NULL,PERIOD_H4), barDaily = iBars(NULL, PERIOD_D1);
   
   
   
      //lot assigner
               if(equity >= 10) Lots = 0.01;
               if(equity >= 30) Lots = 0.02;
               if(equity >= 50) Lots = 0.03;
               for(int fu = 1; fu<10000; fu++){if(equity >= (100 * fu)){Lots = 0.05 *fu;}}
               if(Lots > Maxlot) Lots = Maxlot;
               if(fixedlots > 0) Lots = fixedlots;//disabling trade so spreadbeyond max and holidays dont trade. (but if a trade already open up data could handle closing well)
              
                 if(firstTick == false){firstTick = true; 
                      
                     // strategy();
                       //runner back
                       int Hc = 199,Oc=1;
                        double slowoSar[99999];
                         CopyBuffer(sar,0,1,200,slowoSar);
                           ArraySetAsSeries(slowoSar,true);
                      
                        double slowoMa[99999];
                         CopyBuffer(ma,0,1,200,slowoMa);
                           ArraySetAsSeries(slowoMa,true);
                      // Print("Printin: ",PERIOD_D1/timeF);
                       for(int Lc = Hc; Lc >= 1; Lc--){
                           int ck = 199-Oc;
                              double cot = slowoSar[Lc];
                            block("zoner "+string(cot+" "+time(Lc,PERIOD_CURRENT)),cot,cot,Oc,Oc,1,PERIOD_CURRENT,1,8);
                            
                               strategy(slowoSar[Lc],slowoMa[Lc],ck);
                               //---
                               // zone[2]=0;
                               //if(strategy(30,40,2,PERIOD_CURRENT,Lc,1) == 1){/**/}
                               //for(int mZone=0;mZone < 10; mZone++){
                               //    if(strategy(300+(10*mZone),400+(10*mZone),2,PERIOD_CURRENT,Lc,1) == 1){/**/}
                               //}
                              
                             //---
                               //if(Hc < 50){
                                //    zone[1]=0;
                                //  if(strategy(10,20,1,PERIOD_D1,Hc,1) == 1){/**/}
                                //  if(strategy(100,200,1,PERIOD_D1,Hc,1) == 1){/**/}
                                //  if(strategy(110,210,1,PERIOD_D1,Hc,1) == 1){/**/}
                                //  if(strategy(120,220,1,PERIOD_D1,Hc,1) == 1){/**/}
                                //  if(strategy(130,230,1,PERIOD_D1,Hc,1) == 1){/**/}
                                //  if(strategy(140,240,1,PERIOD_D1,Hc,1) == 1){/**/}
                                  
                             //}
                                Hc -= 1; 
                                Oc += 1; 
                                 
                              }
                        }//runerbackk end
                        
                       
                       
    //---                   
  
   
   // Check for a volume spike
   if (spike > barsToCheck){if(IsVolumeSpike(barsToCheck, spikeThreshold)){spike=0;
      // Volume spike confirmed, add additional logic here
      //Print("Potential breakout or reversal signaled by volume spike.");
      block("vool "+string(low(1)+" "+time(1,PERIOD_CURRENT)),low(1),low(1)-2000*point,1,1,8,PERIOD_CURRENT,1,2);
        //voladj
        for(int ur=1;ur<10;ur++){
           
            //if(ur >= 5) continue;
           
           if(EEE[ur] > 0 && Eis[ur] == 1 && entryEPosi[ur] > 3){double entri = lolo(0,7)-40*point; adj_sl(EEE[ur],3,entri); 
           }else if(EEE[ur] > 0 && Eis[ur] == 2 && entryEPosi[ur] > 3){double entri = hihi(0,9)+65*point; adj_sl(EEE[ur],3,entri); 
           } 
        }                
   }}
   
   
   //---
   CheckEntries();


   
   
                
                       
         //---Daily start
         
          if(barDailyTotal != barDaily){
            barDailyTotal = barDaily;
            dailyTradeLog=0;
            
            datetime time_now = TimeCurrent();
            MqlDateTime time;
            TimeToStruct(time_now, time);
            uint week_day_now = time.day_of_week;
            if (week_day_now == 0) Print("[Summary]   Capital Amt: $ "+DoubleToString(balSet,2)+"  Bal: $ "+DoubleToString(initialBal,2)+"  ||  E1O: "+Elog[1]+", E1L: "+Elog[11]+", E1W: "+Elog[21]+", ||  E2O: "+Elog[2]+", E2L: "+Elog[12]+", E2W: "+Elog[22]+", ||  E3O: "+Elog[3]+", E3L: "+Elog[13]+", E3W: "+Elog[23]);

            //Print(" TG Requst: ",(string)sendMessage("..Summary of :"+TimeToString(TimeCurrent()-10000, TIME_DATE)+" [ "+_Symbol+", Lots: ",lots," ] [ ",tgId,tgToken)); 
                             
         }//end for bar check in 1Day timeframe 
                              
                              
                              
       //---4 hours start
       if(bar4Hour != hourBars){
         bar4Hour=hourBars;
         //
         if(MrkOpen != trade_session()) MrkOpen=trade_session();
         
         //
          double slowSar4h[59999];
          CopyBuffer(sar4hr,0,1,2,slowSar4h);
          ArraySetAsSeries(slowSar4h,true);
          if(slowSar4h[1] > open(1,PERIOD_H4)){check[2]=2;
          }else if(slowSar4h[1] < open(1,PERIOD_H4)){check[2]=1;}
       }
       
   
    
    
       
       //---///////////////assumed market start timing for a trend.
       MqlDateTime strucTime;
       TimeCurrent(strucTime);
       
       strucTime.hour = 13;
       strucTime.min = 0;
       strucTime.sec = 0;
       
       datetime timeStart = StructToTime(strucTime);
       strucTime.hour = 15;
       datetime timeStop = StructToTime(strucTime);
       datetime currentT = TimeCurrent();
       if(currentT >= timeStart && currentT <= timeStop && check[3] != 1){check[3] = 1;}else{check[3] = 0;}
       
       strucTime.hour = 20;
       timeStart = StructToTime(strucTime);
       strucTime.hour = 22;
       timeStop = StructToTime(strucTime);
       if(currentT >= timeStart && currentT <= timeStop && check[3] != 1){check[3] = 1;}else{check[3] = 0;}
                   
                   
               
         ////////////////////////////////   
    if(MrkOpen){       
        //---------------------///////////////////////////
        if(EEE[1] > 0){
            if(PositionSelectByTicket(EEE[1])){
               if(PositionGetInteger(POSITION_TIME_UPDATE) == 0){
               //adj
               Print("\\\\\\\\\\\\\\\\\\\\\trade is closed : ",EEE[1]);
               }
               if(PositionGetInteger(POSITION_TIME) != 0){
               
               //
                //if(EEE[1] > 0 && Eis[1] == 2 && Etrail[1] > 0 && (low(0)+30*point) < lolo(1,entryEPosi[1]+5)){adj_sl(EEE[1],9);//Print("i ajd EEE[1] 5");
                //}else if(EEE[1] > 0 && Eis[1] == 1 && Etrail[1] > 0 && (high(0)-30*point) > hihi(1,entryEPosi[1]+5)){adj_sl(EEE[1],9);//Print("i ajd EEE[1] 6");
                //}
      
               //
                //if(EEE[1] > 0 && Eis[1] == 2 && Ask < (PositionGetDouble(POSITION_PRICE_OPEN)-maxSL*point)){
                  //adj_sl(EEE[1],2);Print("mybad 2");
               //}else if(EEE[1] > 0 && Eis[1] == 1 && Bid > (PositionGetDouble(POSITION_PRICE_OPEN)+maxSL*point)){
                //  adj_sl(EEE[1],2);Print("mybad 1");                  }
                  
               //Print("trade is open : ",EEE[1]," profit: ",PositionGetDouble(POSITION_PROFIT));
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && Bid > (PositionGetDouble(POSITION_TP)-50*point) && high(1) > (double)(PositionGetDouble(POSITION_TP)-(minTP*0.5)*point) && Etrail[1] != 1){
                     adj_sl(EEE[1],2);adj_sl(EEE[1],9);adj_tp(EEE[1],9);Etrail[1]=1;Print("i ajd EEE[1] 3");
                  }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && Ask < (PositionGetDouble(POSITION_TP)+50*point) && low(1) < (double)(PositionGetDouble(POSITION_TP)+(minTP*0.5)*point) && Etrail[1] != 1){
                     adj_sl(EEE[1],2);adj_sl(EEE[1],9);adj_tp(EEE[1],9);Etrail[1]=1;Print("i ajd EEE[1] 4");
                  }
               }
            }else{
               //if(chgDealP == Eis[1]){if(lastDealP < 0){Elog[11]+=1;}else if(lastDealP > 0){Elog[21]+=1;}}
               chgDealP=0;lastDealP=0;
               //EEE[1]=0;entryEPosi[1]=0;Etrail[1]=0;Eis[1]=0;/*if(Eis[1] == 1){closeall(2);}else if(Eis[1] == 2){closeall(1);Print("i closed all 3");}*/Print("cleared EEE[1]");
               }
         }
         
         
         
         if(EEE[2] > 0){
            if(PositionSelectByTicket(EEE[2])){
            if(PositionGetInteger(POSITION_TIME_UPDATE) == 0){
               //adj
               Print("\\\\\\\\\\\\\\\\\\\\\trade is closed : ",EEE[2]);
               }
             if(PositionGetInteger(POSITION_TIME) != 0){
                  
                //
               if(EEE[2] > 0 && Eis[2] == 2 && Ask < (PositionGetDouble(POSITION_PRICE_OPEN)-(PositionGetDouble(POSITION_SL)-PositionGetDouble(POSITION_PRICE_OPEN)))){
                 // adj_sl(EEE[2],2);
               }else if(EEE[2] > 0 && Eis[2] == 1 && Bid > (PositionGetDouble(POSITION_PRICE_OPEN)+(PositionGetDouble(POSITION_PRICE_OPEN)-PositionGetDouble(POSITION_SL)))){
                 // adj_sl(EEE[2],2);
                  }
               //Print("trade is open : ",EEE[1]," profit: ",PositionGetDouble(POSITION_PROFIT));
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && Bid > (PositionGetDouble(POSITION_TP)-50*point) && high(1) > (double)(PositionGetDouble(POSITION_TP)-(minTP*0.5)*point) && Etrail[2] != 1){
                     //adj_sl(EEE[2],2);
                     adj_sl(EEE[2],9);adj_tp(EEE[2],9);Etrail[2]=1;Print("i ajd EEE[1] 13");
                  }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && Ask < (PositionGetDouble(POSITION_TP)+50*point) && low(1) < (double)(PositionGetDouble(POSITION_TP)+(minTP*0.5)*point) && Etrail[2] != 1){
                     //adj_sl(EEE[2],2);
                     adj_sl(EEE[2],9);adj_tp(EEE[2],9);Etrail[2]=1;Print("i ajd EEE[1] 14");
                  }
               }
               /*
               if(PositionGetDouble(POSITION_SL) < PositionGetDouble(POSITION_PRICE_OPEN)){
                  if(Bid > (PositionGetDouble(POSITION_TP)-60*point) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                   //adj to void
                   //adj_sl(EEE[2],2);
               }}
               
               if(PositionGetDouble(POSITION_SL) > PositionGetDouble(POSITION_PRICE_OPEN)){
                   if(Ask < (PositionGetDouble(POSITION_TP)+60*point) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                   //adj to void
                   //adj_sl(EEE[2],2);
               }}*/
            }else{
            if(chgDealP == Eis[2]){
              
              // if(lastDealP < 0){Elog[12]+=1;}else if(lastDealP > 0){Elog[22]+=1;}
              }    
                chgDealP=0;lastDealP=0;
               //EEE[2]=0;entryEPosi[2]=0;Etrail[2]=0;/*if(Eis[2] == 1){closeall(1);}else if(Eis[2] == 2){closeall(2);Print("i closed all 4");}*/Eis[2]=0;Print("cleared EEE[2]");
               }
         }
        /* if(EEE[3] > 0){
            if(PositionSelectByTicket(EEE[3])){
               if(PositionGetInteger(POSITION_TIME_UPDATE) == 0){
               //adj
               //Print("trade is closed : ",EEE[1]);
               }
               if(PositionGetInteger(POSITION_TIME) != 0){
               //Print("trade is open : ",EEE[1]," profit: ",PositionGetDouble(POSITION_PROFIT));
                if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && Bid > (PositionGetDouble(POSITION_TP)-50*point)){
                     adj_sl(EEE[3],2);adj_sl(EEE[3],9);adj_tp(EEE[3],9);Etrail[3]=1;
                  }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && Ask < (PositionGetDouble(POSITION_TP)+50*point)){
                     adj_sl(EEE[3],2);adj_sl(EEE[3],9);adj_tp(EEE[3],9);Etrail[3]=1;
                  }
               }
            }else{EEE[3]=0;entryEPosi[3]=0;Etrail[3]=0;if(Eis[3] == 1){closeall(1);}else if(Eis[3] == 2){closeall(2);Print("i closed all 5");}Eis[3]=0;Print("cleared EEE[3]");}
         }*/
                     
                     
                     
                   
      //ADJS TO VOID EEE[2]
      //if(EEE[2] > 0 && Eis[2] == 2 && (low(0)+30*point) < lolo(1,entryEPosi[2]+5)){adj_sl(EEE[2],2);if(Etrail[2] > 0){adj_sl(EEE[2],9);}
      //}else if(EEE[2] > 0 && Eis[2] == 1 && (high(0)-30*point) > hihi(1,entryEPosi[2]+5)){adj_sl(EEE[2],2);if(Etrail[2] > 0){adj_sl(EEE[2],9);}}
      
     // if(stopline > 0.0 && activeTrend == 1 && Bid < stopline){if(posi1Chg >0 && posi1Chg <6){closeall(2);Print("i closed all 6");}else{closeall(1);}
     stopline=0.0;
      //}else if(stopline > 0.0 && activeTrend == 2 && Ask > stopline){if(posi1Chg >0 && posi1Chg <6){closeall(1);Print("i closed all 7");}else{closeall(2);}stopline=0.0;}
      
      
      
     
      
      //if(EEE[3] > 0 && Eis[3] == 2 && Etrail[3] > 0 && (low(0)+30*point) < lolo(1,entryEPosi[3]+5)){adj_sl(EEE[3],9);
      //}else if(EEE[3] > 0 && Eis[3] == 1&& Etrail[3] > 0  && (high(0)-30*point) > hihi(1,entryEPosi[3]+5)){adj_sl(EEE[3],9);}
      }             
               
      
      
                   
                         
                   
                        
      //---//////////////// 30min start (Main)
      if(barTotal != bars){
      barTotal=bars;
      //if(EEE[1] > 0 && ((Eis[1] == 1 && close(1) > bagVal[62]) || (Eis[1] == 2 && close(1) < bagVal[72]))){entryEPosi[1]+=1;}
      //if(EEE[2] > 0 && ((Eis[2] == 1 && close(1) > bagVal[62]) || (Eis[2] == 2 && close(1) < bagVal[72]))){entryEPosi[2]+=1;}
      if(EEE[1] > 0 && entryEPosi[1] > 0){entryEPosi[1]+=1;}
      if(EEE[2] > 0 && entryEPosi[2] > 0){entryEPosi[2]+=1;}
      if(EEE[3] > 0 && entryEPosi[3] > 0){entryEPosi[3]+=1;}
      
      if(posiLine > 0){posiLine+=1;}
      
      //if(makevoid){if(adj_sl(EEE[2],2)){makevoid=false;}}
      
      if(posi1Chg > 0){posi1Chg+=1;}
      if(posi2Chg > 0){posi2Chg+=1;}
       
       spike+=1;
      
      if(Epending[1] > 0 && pendingEPosi[1] > 0){pendingEPosi[1]+=1;}
      if(Epending[2] > 0 && pendingEPosi[2] > 0){pendingEPosi[2]+=1;}
      if(Epending[3] > 0 && pendingEPosi[3] > 0){pendingEPosi[3]+=1;}
     
      
      if(Epending[3] > 0 && pendingEPosi[3] < 7) adj_stop(Epending[3]);  
       
      //Print("Epending[3] ",Epending[3]);
      
      check[0]=0;
      
      
      if(EEE[1] > 0 && Eis[1] == 2 && ((close(1) > bagVal[1] && bagVal[1] > point) || (close(1) > bagVal[2] && bagVal[1] <= point))){//high
        // adj_sl(EEE[1],4);Print("i ajd EEE[1] 1");
      }else if(EEE[1] > 0 && Eis[1] == 1 && ((close(1) < bagVal[11] && bagVal[11] > point) || (close(1) < bagVal[12] && bagVal[11] <= point))){//low
        // adj_sl(EEE[1],4);Print("i ajd EEE[1] 2");
      }
      
      
      
         double lastboxup,lastboxdown,lastboxup2,lastboxdown2;
         int lastboxposi,lastboxposi2;
         //---
        strategy(sar_val(1),ma_vall(1),1);
        
            
               /*   if(((newbox <= 2 && yesbrk == 1  &&  bag[1] == 0 && (high(1)-10*point)>bagVal[2]) || (high(1) > needbrk && needbrk > 0)) && activeTrend == 2){// 
                     stopline=0.0;posi2Chg=0;newbox=3;if(PositionsTotal() > 0){adj_sl(EEE[3],3,high(1)+100*point);adj_sl(EEE[1],3,high(1)+100*point);adj_sl(EEE[2],3,high(1)+100*point);}
                    if(EEE[2]>0){makevoid=true;} yesbrk=0;activeTrend=1;clearPending(1);clearPending(2);needbrk=0.0;line(0,"new trendss : 1 :: "+time(0,PERIOD_CURRENT),time(0,PERIOD_CURRENT),1,3,2,PERIOD_CURRENT);//&& close(1) > ma_vall(1) 
                  }else if(((newbox <= 2 && yesbrk == 2 &&  bag[11] == 0 && (low(1)+10*point)<bagVal[12]) || (low(1) < needbrk && needbrk > 0)) && activeTrend == 1 ){//
                    stopline=0.0; posi1Chg=0;newbox=3;if(PositionsTotal() > 0){adj_sl(EEE[3],3,low(1)-100*point);adj_sl(EEE[1],3,low(1)-100*point);adj_sl(EEE[2],3,low(1)-100*point);}
                    if(EEE[2]>0){makevoid=true;} yesbrk=0;activeTrend=2;clearPending(1);clearPending(2);needbrk=0.0;line(0,"new trendss : 2 :: "+time(0,PERIOD_CURRENT),time(0,PERIOD_CURRENT),1,3,2,PERIOD_CURRENT);}// && close(1) < ma_vall(1)
          
          //
                  if(activeTrend == 1 && close(1) > ma_vall(1) && trendIs == 2){yesbrk=2;
                  }else if(activeTrend == 2 && close(1) < ma_vall(1) && trendIs == 1){yesbrk=1;}
                  */
           //
          for(int op =1;op<10;op++){
                  if((bagVal[41+op] == 0.0 && activeTrend == 1 ) || (bagVal[31+op] == 0.0 && activeTrend == 2)){continue;}
                  
                  if(activeTrend == 2){lastboxdown=bagVal[51+op];lastboxup=bagVal[31+op];}else if(activeTrend == 1){lastboxdown=bagVal[41+op];lastboxup=bagVal[21+op];}
                  lastboxposi=op+1;
                  
                  for(int opp =op+1;opp<10;opp++){
                  if((bagVal[41+opp] == 0.0 && ((activeTrend == 1 && firsttbox==0)  || firsttbox == 1) ) || (bagVal[31+opp] == 0.0 && ((activeTrend == 2 && firsttbox==0) || firsttbox == 2))){continue;}
                  
                  lastboxposi2=opp+1;
                  if((activeTrend == 2 && firsttbox==0) || (firsttbox == 2)){lastboxdown2=bagVal[51+opp];lastboxup2=bagVal[31+opp];}else if((activeTrend == 1 && firsttbox==0) || (firsttbox == 1)){lastboxdown2=bagVal[41+opp];lastboxup2=bagVal[21+opp];}
                  //down to up brk
                  //Print("selling box 1HL : ",bagVal[31+op]," first low : ",bagVal[51+op]," secnd low : ",bagVal[51+opp]);
                 // if( newbox == 1 && open(1) < close(1) && ((close(1)-open(1)) > 30*point)  && bagVal[51+opp] > point  && (( (high(1)-15*point) > bagVal[31+op] && (bagVal[51+op]-10*point) < bagVal[51+opp]) || ((high(1)-15*point) > bagVal[31+opp] && bagVal[51+op] > bagVal[51+opp] &&  bagVal[31+op] < bagVal[31+opp])) && activeTrend == 2 ){//&& trendIs == 2//needbrk=bagVal[51+op];// && (bagVal[51+opp]-bagVal[51+op]) > 30*point
                     //open(1) < ma_vall(1) &&
                     //stopline=0.0;newbox=2;posi1Chg=1;needbrk=bagVal[51+op];if(needbrk > lolo(1,bagPE[2])){needbrk=lolo(1,bagPE[2]);}if(EEE[2]>0){makevoid=true;}clearPending(1);clearPending(2);
                     //if(noentry != 2 && (newbox == 1  && activeTrend == 2 && ((open(1) < close(1) && ((close(1)-open(1)) > 30*point)  && bagVal[51+opp] > point  && (( (high(1)-15*point) > bagVal[31+op] && (bagVal[51+op]-10*point) < bagVal[51+opp]) || ((high(1)-15*point) > bagVal[31+opp] && bagVal[51+op] > bagVal[51+opp] &&  bagVal[31+op] < bagVal[31+opp])))))){noentry=2;}
                    if(newbox >= 1 && newbox < 3 && usedbox==0  && activeTrend == 2 && open(1) < close(1) && ((close(1)-open(1)) > 30*point)  && lastboxdown2 > point  && (( (close(1)-15*point) > lastboxup && (lastboxdown-10*point) < lastboxdown2) || ((close(1)-15*point) > lastboxup2 && lastboxdown > lastboxdown2 &&  lastboxup < lastboxup2))){
                    newbox=3;clearPending(1);clearPending(2);posi1Chg=1;line(0,"s : 1 :: "+time(0,PERIOD_CURRENT),time(0,PERIOD_CURRENT),1,4,2,PERIOD_CURRENT);
                    }
                     if((newbox == 1 || newbox == 3) && activeTrend == 2 && ((close(1) > lastboxup && lastboxup > ma_vall(1)))){// || 
                    noentry =0;isFirst=1; newbox = 2;usedbox=1;firsttbox=2; posiLine=1;activeTrend=1;clearPending(1);clearPending(2);line(0,"new trends : 1 :: "+time(0,PERIOD_CURRENT),time(0,PERIOD_CURRENT),1,2,2,PERIOD_CURRENT);}
                  //up to down
                  //if(newbox == 1 && open(1) > close(1) && ((open(1)-close(1)) > 30*point) &&  bagVal[21+opp] > point && (((low(1)+15*point) < bagVal[41+op] && (bagVal[21+op]+10*point) > bagVal[21+opp]) || ((low(1)+15*point) < bagVal[41+opp] && bagVal[21+op] < bagVal[21+opp] && bagVal[41+op] > bagVal[41+opp])) && activeTrend == 1){//&& (bagVal[21+op]-bagVal[21+opp]) > 30*point
                     //open(1) > ma_vall(1) && 
                    // stopline=0.0;newbox=2;posi2Chg=1;needbrk=bagVal[21+op];if(needbrk < hihi(1,bagPE[12])){needbrk=hihi(1,bagPE[12]);}if(EEE[2]>0){makevoid=true;}clearPending(1);clearPending(2);
                   // if(noentry !=1 &&  newbox == 1 && activeTrend == 1 && ((open(1) > close(1) && ((open(1)-close(1)) > 30*point) &&  bagVal[21+opp] > point && (((low(1)+15*point) < bagVal[41+op] && (bagVal[21+op]+10*point) > bagVal[21+opp]) || ((low(1)+15*point) < bagVal[41+opp] && bagVal[21+op] < bagVal[21+opp] && bagVal[41+op] > bagVal[41+opp]))))){noentry=1;}
                 if(newbox >= 1 && newbox < 3  && usedbox == 0 && activeTrend == 1 && (open(1) > close(1) && ((open(1)-close(1)) > 30*point) &&  lastboxup2 > point && (((close(1)+15*point) < lastboxdown && (lastboxup+10*point) > lastboxup2) || ((close(1)+15*point) < lastboxdown2 && lastboxup < lastboxup2 && lastboxdown > lastboxdown2)))){
                    newbox=3;clearPending(1);clearPending(2);posi2Chg=1;line(0,"s : 2 :: "+time(0,PERIOD_CURRENT),time(0,PERIOD_CURRENT),1,4,2,PERIOD_CURRENT);
                    }
                  if((newbox == 1 || newbox == 3) && activeTrend == 1 && ((close(1) < lastboxdown && lastboxdown < ma_vall(1)))){
                    noentry =0;isFirst=1;newbox = 2;usedbox=1;firsttbox=1;   posiLine=1;activeTrend=2;clearPending(1);clearPending(2);line(0,"new trends : 2 :: "+time(0,PERIOD_CURRENT),time(0,PERIOD_CURRENT),1,2,2,PERIOD_CURRENT);}
                  break;}
                  break;
         }
         
         
         //
         if(lastboxdown <  close(2) && activeTrend == 2 && (lastboxdown+((lastboxup-lastboxdown)*0.35)) > close(1) && open(1) > close(1) && (Epending[1] > 0 || Epending[3] > 0)){clearPending(1);clearPending(3);Print("iclea pending 1&3");
         }else if(lastboxup >  close(2) && activeTrend == 1 && (lastboxup-((lastboxup-lastboxdown)*0.35)) < close(1) && open(1) < close(1) && (Epending[1] > 0 || Epending[3] > 0)){clearPending(1);clearPending(3);Print("iclea pending 1&3");
         }
         
         
         if(Epending[1] > 0 && bag[2]==1 && activeTrend == 2){clearPending(1);
         }else if(Epending[1] > 0 && bag[12]==1 && activeTrend == 1){clearPending(1);
         }
         //--
         //if(Epending[1] > 0 && pendingPosi > 1) adj_stop(Epending[1]);
         //if(EEE[1] > 0 && entryPosi > 1) adj_sl(EEE[1],1);//start adj after 2candle from entry.
         //if(EEE[2] > 0 && entryPosi > 1) adj_sl(EEE[2],2);
         
         //enter check
         if(atr_val(1)*2.5 > (minTP)*point){check[1]=1;}else{ check[1]=0;}
         if(check[4] != trendOn){check[4]=trendOn;}
         
         
         
         
         
         if(posi1Chg > 0 && low(posi1Chg) > lastboxdown && low(1) < (lastboxdown+(lastboxup-lastboxdown)*0.2)){posi1Chg=0;clearPending(1);}
         if(posi2Chg > 0  && high(posi2Chg) < lastboxup && high(1) > (lastboxup-(lastboxup-lastboxdown)*0.2)){posi2Chg=0;clearPending(2);}
         
         
         
          ////////////////////////////////   
         if(MrkOpen){
         
          if(Ask-Bid <= MaxSpread*point){//check[1] == 1
            
               //---
               /*
               datetime expiration = TimeCurrent()+ExpireSec*2;
               if(EEE[1] == 0){
               //Print("expir: ",expiration);
               //unused && valid definition of EEE[1] && trend is buy on down look
               if(bagStat[12] == 1 && bagVal[12] > bagVal[32]-((bagVal[32]-bagVal[52])*.38) && bagPE[52]==1 && (check[2] == 1 || check[3] == 1 )){//|| trendOn == 1
                            bagStat[12]=2;    
                  //---buy EEE[1] (maxsl 1.2)
                  double entry = bagVal[61]+550*point,
                         sl=entry-(maxSL*point),
                         tp=0.0;
                  trade.BuyStop(Lots,entry,_Symbol,sl,tp,ORDER_TIME_SPECIFIED,expiration,"EEE[1]");
               
               }else if(bagStat[2] == 1 && bagVal[2] < bagVal[42]+((bagVal[22]-bagVal[42])*.38) && bagPE[42]==2 && (check[2] == 2 || check[3] == 1 )){//|| trendOn == 2
                           bagStat[2]=2;
                    //---sell EEE[1] (maxsl 1.2)
                  double entry = bagVal[71]-550*point;//low(1)+20*point
                  
                  double sl=entry+(maxSL*point),
                         tp=0.0;
                  trade.SellStop(Lots,entry,_Symbol,sl,tp,ORDER_TIME_SPECIFIED,expiration,"EEE[1]");
               
               }
               }
               
               
               if(EEE[2] == 0){
                expiration = TimeCurrent()+ExpireSec;
               //---EEE[2] entering with trend
               if(bagStat[12] == 1 && bagVal[12] < bagVal[32]-((bagVal[32]-bagVal[52])*.48) && bagPE[52]==2 && (check[2] == 2 || check[3] == 1 )){
                            bagStat[12]=2;    
                    //---sell EEE[2] (maxsl 0.7)
                  double entry = bagVal[12]-10*point;
                  if(Ask > entry) entry = Ask+50*point;
                  if((entry+maxSL*point) < bagVal[61] && entry < ma_vall(1)){entry=bagVal[61]-maxSL*point;}
                  //entry=entry+100*point;
                  double sl=entry+(maxSL*point),
                         tp=entry-minTP*point;
                         //final chck if passed box end && checkes if EEE[2] sar been taken out. 
                   if(entry+30*point < bagVal[22] &&  lolo(1,bag[12]) > bagVal[72]){
                        trade.SellLimit(Lots,entry,_Symbol,sl,tp,ORDER_TIME_SPECIFIED,expiration,"EEE[2]");}
                  //&& && && && extra/external validation
               }else if(bagStat[2] == 1 && bagVal[2] > bagVal[42]+((bagVal[22]-bagVal[42])*.48) && bagPE[42]==1  && (check[2] == 1 || check[3] == 1 )){
                           bagStat[2]=2;
                  //---buy EEE[2] (maxsl 0.7)
                  double entry = bagVal[2]+10*point;
                  if(Bid < entry) entry = Bid-50*point;
                  if((entry-maxSL*point) > bagVal[71] && entry > ma_vall(1)){entry=bagVal[71]+maxSL*point;}
                  entry=entry-50*point;
                  double sl=entry-(maxSL*point),
                         tp=entry+minTP*point;
                         //final chck if passed box end && checkes if EEE[2] sar been taken out. 
                  if(entry-30*point > bagVal[52] && hihi(1,bag[2]) < bagVal[62]){
                      trade.BuyLimit(Lots,entry,_Symbol,sl,tp,ORDER_TIME_SPECIFIED,expiration,"EEE[2]");}
               
               
               }}*/
               
               
               //----EEE[2] entering against trend
               /*
               
               */
               /*
               datetime expiration = TimeCurrent()+ExpireSec*6;
               if(EEE[1] == 0 && EEE[2] == 0){
                  if(bagStat[3] == 2  && trendIs == 1 && bag[1] > 3  && bagVal[62] > hihi(1,bagPE[2]) && (check[2] == 1 || check[3] == 1 )){bagStat[3]=4; //&& bagPE[52]==1
                     double entry=bagVal[72] - ((bagVal[12]-bagVal[72])*0.4);
                     if(bagPE[13]-(bagPE[12]+bag[12]) < 4){entry = bagVal[73] - ((bagVal[12]-bagVal[73])*0.5);}
                     if(Ask < entry){entry = Ask-20*point;}
                     double sl=entry-(maxSL*point),
                           tp=entry+atr_val(1)*2.5;
                       //  trade.BuyLimit(Lots,entry,_Symbol,sl,tp,ORDER_TIME_SPECIFIED,expiration,"EEE[1]");
                         block("buylimit EEE[1] "+string(entry+" "+time(1,PERIOD_CURRENT)),entry,entry,1,1,1,PERIOD_CURRENT,1,8);clearPending(1);clearPending(2);Print("cleared by 9");
                  }else if(bagStat[13] == 3  && trendIs == 2 && bag[11] > 3  && bagVal[72] < lolo(1,bagPE[12]) && (check[2] == 2 || check[3] == 1 )){bagStat[13]=4;// && bagPE[42]==2
                       
                     double entry=bagVal[62] + ((bagVal[62]-bagVal[2])*0.4);
                     if(bagPE[3]-(bagPE[2]+bag[2]) < 4){entry = bagVal[63] + ((bagVal[63]-bagVal[2])*0.5);}
                     if(Bid > entry){entry = Bid+20*point;}
                     double sl=entry+(maxSL*point),
                            tp=entry-atr_val(1)*2.5;
                        trade.SellLimit(Lots,entry,_Symbol,sl,tp,ORDER_TIME_SPECIFIED,expiration,"EEE[1]");
                         block("selllimit EEE[1] "+string(entry+" "+time(1,PERIOD_CURRENT)),entry,entry,1,1,1,PERIOD_CURRENT,1,8);clearPending(1);clearPending(2);Print("cleared by 10");
                    }
               }*/
               
               
               
               
            /*   
                if(EEE[2] <= 0 && EEE[1] <= 0){
                
               // if(bagStat[12] < 2 ){Print("isok 1");}
               // if(bagVal[63] < hihi(1,bagPE[3]+1)  ){Print("isok 2");}
                //if(trendIs == 2  ){Print("isok 3");}
                //if((check[2] == 2 || check[3] == 1 || bagPE[52]==2 )){Print("isok 4");}
                  if(bagStat[2] < 2 && trendIs == 1){// && (check[2] == 1 || check[3] == 1 || check[1] == 1 || bagPE[42]==1 )){
                  bagStat[2]=2; //&& bagPE[42]==1 //&& ((ma_vall(1)-bagVal[2]) > 50*point || (ma_vall(1)-bagVal[2])  < point)
                  
                     double entry=NormalizeDouble(bagVal[2] - ((bagVal[2] - bagVal[71])*0.45),_Digits);
                     if(Ask < entry){entry = Ask-20*point;}
                     double sl=entry-(maxSL*point),
                           tp=entry+atr_val(1)*2.5;
                           
                       if(bagVal[63] < hihi(1,bagPE[3]+1)){
                        // trade.BuyLimit(Lots,entry,_Symbol,sl,tp,ORDER_TIME_SPECIFIED,expiration,"EEE[2]");
                         
                         block("buylimit EEE[2] "+string(entry+" "+time(1,PERIOD_CURRENT)),entry,entry,1,1,1,PERIOD_CURRENT,1,8);
                         
                         if(close(bag[11]) > bagVal[2] && close(bag[11]) < bagVal[62]){
                           entry = high(bag[11])+40*point;
                           if(Ask > entry){entry = Ask+20*point;}
                           sl=entry-(maxSL*point);
                           tp=entry+atr_val(1)*2.5;expiration = TimeCurrent()+500;
                           //trade.BuyStop(Lots,entry,_Symbol,sl,tp,ORDER_TIME_SPECIFIED,expiration,"EEE[2]");
                         block("buystop EEE[2] "+string(entry+" "+time(1,PERIOD_CURRENT)),entry,entry,1,1,1,PERIOD_CURRENT,1,8);}}else{bagStat[2]=5;}
                  }else if(bagStat[12] < 2  && trendIs == 2 && (bag[12] > 7 || bag[1] > 1)){// && (check[2] == 2 || check[3] == 1 || check[1] == 1 || bagPE[52]==2 )){
                  bagStat[12]=3; // && bagPE[52]==2 
                       
                     double entry=NormalizeDouble(bagVal[12] + ((bagVal[61]-bagVal[12])*0.45),_Digits);
                     if(Bid > entry){entry = Bid+20*point;}
                     double sl=entry+(maxSL*point),
                            tp=entry-atr_val(1)*2.5;
                            
                        if(bagVal[73] > lolo(1,bagPE[13]+1)){
                           trade.SellLimit(Lots,entry,_Symbol,sl,tp,ORDER_TIME_SPECIFIED,expiration,"EEE[2]");
                           
                            block("selllimit EEE[2] "+string(entry+" "+time(1,PERIOD_CURRENT)),entry,entry,1,1,1,PERIOD_CURRENT,1,8);
                            
                        if(close(bag[1]) < bagVal[12] && close(bag[1]) > bagVal[72]){
                           entry = low(bag[1])-40*point;
                           if(Bid < entry){entry = Bid-20*point;}
                           sl=entry+(maxSL*point);
                            tp=entry-atr_val(1)*2.5;expiration = TimeCurrent()+500;
                           //trade.SellStop(Lots,entry,_Symbol,sl,tp,ORDER_TIME_SPECIFIED,expiration,"EEE[2]");
                         block("sellstop EEE[2] "+string(entry+" "+time(1,PERIOD_CURRENT)),entry,entry,1,1,1,PERIOD_CURRENT,1,8);}}else{bagStat[12]=5;}
                    }
               }else if(EEE[2]+EEE[2] > 0 && bagStat[12] < 2  && trendIs == 2){bagStat[12]=5;
               }else if(EEE[2]+EEE[2] > 0 && bagStat[2] < 2  && trendIs == 1){bagStat[2]=5;}
            
            */
          
          
          
          
          
          
          
          
          
          ////
          datetime expiration = TimeCurrent()+ExpireSec*2.3;
               
               //stop
          /* if(bagPE[12] < 17 && (bagPE[12]-1) > 1) Print("isok 1");
           if(close(1) > (bagVal[12]+15*point) && loloC(bagPE[12]-3,bagPE[12]-1) < bagVal[12]) Print("isok 2");
           if( activeTrend == 1 ) Print("isok 3");
           if( bagStat[12] < 2) Print("isok 4 : ",bagPE[53]);
           if(bagPE[53] == 1 ||  bagVal[72] > ma_vall(1)) Print("isok 5 : ",bagPE[53]);
           */
          if(bagPE[12] < 17  && bag[11] <= 1 && (bagPE[12]-1) > 1 && close(1) > (bagVal[12]+15*point) && loloC(bagPE[12]-3,bagPE[12]-1) < bagVal[12] && activeTrend == 1 && bagStat[12] < 2 && ((bagPE[43] == 1 && bagPE[42] == 1) ||  bagVal[72] > ma_vall(1)) ){//hihiC(1,bagPE[12]-2)bagVal[72] > ma_vall(1)
            bagStat[12] = 2;
            double entry=NormalizeDouble(lolo(1,bagPE[12])-60*point,_Digits),
                   sl=hihi(1,9)+50*point,//entry+((maxSL+80)*point),
                   tp=entry-((minTP*1.2)*point);//atr_val(1)*2.5;
                   if(entry > ma_vall(1)){//adj_sl(EEE[3],3,entry);
                   stopline=entry;
                   if((sl-entry) > (maxSL+80*point)){sl=entry+(maxSL+80*point);}
                   
                       block("sellStop EEE[1] "+string(entry+" "+time(1,PERIOD_CURRENT)),entry,entry,1,1,1,PERIOD_CURRENT,1,8);
                       entryType[2]=2;entryP[2]=entry;entrySL[2]=sl;entryTP[2]=tp;entryExp[2]=expiration;entryCom[2]="E1";
                     }clearPending(2);
                        
          }else if(bagPE[2] < 17 && bag[1] <= 1 && (bagPE[2]-1) > 1 && hihiC(bagPE[2]-3,bagPE[2]-1) > bagVal[2] && close(1) < (bagVal[2]-15*point) && activeTrend == 2 && bagStat[2] < 2 && ((bagPE[53] == 2 && bagPE[52] == 2) || bagVal[62] < ma_vall(1)) ){//bagPE[2] < 7 //loloC(1,bagPE[2]-2)//bagVal[62] < ma_vall(1)
            bagStat[2] = 2;
            double entry=NormalizeDouble(hihi(1,bagPE[2])+60*point ,_Digits),
                   sl=lolo(1,9)-40*point,//entry-((maxSL+80)*point),
                   tp=entry+((minTP*1.2)*point);//atr_val(1)*2.5;
                     if(entry < ma_vall(1)){//adj_sl(EEE[3],3,entry);
                     stopline=entry;
                   if((entry-sl) > (maxSL+80*point)){sl=entry-(maxSL+80*point);}
                   
                       block("buyStop EEE[1] "+string(entry+" "+time(1,PERIOD_CURRENT)),entry,entry,1,1,1,PERIOD_CURRENT,1,8);
                      entryType[2]=1;entryP[2]=entry;entrySL[2]=sl;entryTP[2]=tp;entryExp[2]=expiration;entryCom[2]="E1";
                      }clearPending(2);
          }
      
      
               //limit
          // if( close(1) < bagVal[62] && bagStat[2]  < 2){bagStat[2] = 2;}else if( close(1) > bagVal[72] && bagStat[12] < 2){bagStat[12] = 2;}
          
          ////
        /*   expiration = TimeCurrent()+ExpireSec*3;
        if(newbox < 3){       
           if(bagStat[12] < 2  && activeTrend == 2 && bag[1] > 1 && bag[1] < 4 && EEE[1] < 1 && trendOn == 2){
           bagStat[12] = 2;
           double entry=NormalizeDouble(bagVal[3]-40*point,_Digits);
           if(bagVal[61] > bagVal[3] || bagVal[62] < bagVal[63]){entry=bagVal[61]-((bagVal[61]-bagVal[12])*0.35);}
           
           if(bagVal[73] > lolo(1,bagPE[13]+1)){  
           int coll=1;double per20=(lastboxup-lastboxdown)*0.3,per40=(lastboxup-lastboxdown)*0.4;
           if(entry < lastboxup-per40 && entry > lastboxdown+per20){entry=(lastboxup-per40)+10*point;coll=3;}
           if(entry > lastboxup-per40 || entry < lastboxdown+per20){ 
                 if(entry > ma_vall(1) && (entry - ma_vall(1)) < (100*point)){entry=ma_vall(1)-20*point;}
                 if(Bid > entry){entry = Bid+20*point;}
                 double sl=entry+(maxSL*point),
                         tp=entry-minTP*point;//atr_val(1)*2.5;                          
                           
                           //Print("lastboxdown ",lastboxdown," lastboxup", lastboxup);
                             
                             entryType[1]=2;entryP[1]=entry;entrySL[1]=sl;entryTP[1]=tp;entryExp[1]=expiration;entryCom[1]="EEE[2]";}
                       block("selllimit EEE[2] "+string(entry+" "+time(1,PERIOD_CURRENT)),entry,entry,1,1,coll,PERIOD_CURRENT,1,8);
                    }
           }else if(bagStat[2] < 2  && activeTrend == 1 && bag[11] > 1 && bag[11] < 4 && EEE[1] < 1 && trendOn == 1){
            bagStat[2] = 2;
            double entry=NormalizeDouble(bagVal[13]+40*point,_Digits);
            if(bagVal[71] < bagVal[13] || bagVal[72] > bagVal[73]){entry=bagVal[71]+((bagVal[2]-bagVal[71])*0.35);}
               
                   if(bagVal[63] < hihi(1,bagPE[3]+1)){
                   int coll=1;double per20=(lastboxup-lastboxdown)*0.3,per40=(lastboxup-lastboxdown)*0.4;
                   if(entry < lastboxup-per20 && entry > lastboxdown+per40){entry=(lastboxdown+per40)-10*point;coll=3;}
                   if(entry > lastboxup-per20 || entry < lastboxdown+per40){ 
                          if(entry < ma_vall(1) && (ma_vall(1) - entry) < (100*point)){entry=ma_vall(1)+20*point;}
                           if(Ask < entry){entry = Ask-20*point;}
                           double sl=entry-(maxSL*point),
                                  tp=entry+minTP*point;//atr_val(1)*2.5;
                                  
                                      entryType[1]=1;entryP[1]=entry;entrySL[1]=sl;entryTP[1]=tp;entryExp[1]=expiration;entryCom[1]="EEE[2]";}
                         block("buylimit EEE[2] "+string(entry+" "+time(1,PERIOD_CURRENT)),entry,entry,1,1,coll,PERIOD_CURRENT,1,8);
                }
            }
           }
            */
            
            //entry on activetrend and stop set... stop
           if( EEE[3] < 1 && (posi1Chg > 0 || posi2Chg > 0)){
           
           expiration = TimeCurrent()+ExpireSec*6;
            double per50=(lastboxup-lastboxdown)*0.5;
      if(bagStat[12] < 3 && activeTrend == 1 && close(1) > open(1) && close(1) > lastboxdown && posi2Chg < 9 && posi2Chg > 1){//&& ((high(1) > (lastboxup-per50) && activeTrend == 2)
      bagStat[12] = 3;
          double entry=NormalizeDouble(lolo(1,posi2Chg),_Digits),//Bid-900*point
                   sl=hihi(1,posi2Chg),//0.0,//entry+((maxSL+80)*point),
                   tp=entry-(minTP*1.5)*point;//atr_val(1)*2.5;
                   if(EEE[1] < 1){//entry > ma_vall(1)
                   stopline=entry;
                       entryType[2]=2;entryP[2]=entry;entrySL[2]=sl;entryTP[2]=tp;entryExp[2]=expiration;entryCom[2]="E3";}
                       block("sellStop EEE[3] "+string(entry+" "+time(1,PERIOD_CURRENT)),entry,entry,1,1,1,PERIOD_CURRENT,1,8);
                      //  }else if(Eis[1] == 2){EEE[3]=EEE[1];EEE[1]=0;Eis[3]=Eis[1];Eis[1]=0;entryEPosi[3]=entryEPosi[1];entryEPosi[1]=0;adj_tp(EEE[3],1);}//clearPending(2);
                     // if(EEE[1] > 0){adj_tp(EEE[1],1);}
      }else if(bagStat[2] < 3 && activeTrend == 2 && close(1) < open(1) && close(1) < lastboxup && posi1Chg < 9 && posi1Chg > 1){
      bagStat[2] = 3;
         double entry=NormalizeDouble(hihi(1,posi1Chg) ,_Digits),//Ask+900*point
                   sl=lolo(1,posi1Chg),//0.0,//entry-((maxSL+80)*point),
                   tp=entry+(minTP*1.5)*point;//atr_val(1)*2.5;
                    if(EEE[1] < 1){//entry < ma_vall(1)
                     stopline=entry;
                       entryType[2]=1;entryP[2]=entry;entrySL[2]=sl;entryTP[2]=tp;entryExp[2]=expiration;entryCom[2]="E3";}
                       block("buyStop EEE[3] "+string(entry+" "+time(1,PERIOD_CURRENT)),entry,entry,1,1,1,PERIOD_CURRENT,1,8);
                     
                     // }else if(Eis[1] == 1){EEE[3]=EEE[1];EEE[1]=0;Eis[3]=Eis[1];Eis[1]=0;entryEPosi[3]=entryEPosi[1];entryEPosi[1]=0;adj_tp(EEE[3],1);}//clearPending(2);
                     //if(EEE[1] > 0){adj_tp(EEE[1],1);}
       }
      
      
       }
       
       
       
       
       //
       if(newbox <= 2 && usedbox == 0){
       firsttbox=0;
         expiration = TimeCurrent()+ExpireSec*5;
         
            double  per30=(lastboxup-lastboxdown)*sellerBoxPercent,per40=(lastboxup-lastboxdown)*buyerBoxPercent;
            
         if(activeTrend == 1 && (lastboxup > (lastboxup2-10*point) && lastboxdown <= lastboxup2)  && lastboxdown < (ma_vall(1)+20*point) && ( EEE[1] == 0 ||  EEE[1] > 0 && Eis[1] == 1)){
        usedbox=1;
            double entry=NormalizeDouble(lastboxup-per40,_Digits);
            int byask =0;
             if(Ask < entry){entry = Ask-10*point;byask=1;}
             
             double sl=lastboxdown;//0.0;if(lastboxdown < ma_vall(1)){sl=lastboxdown;}
             if(entry > ma_vall(1)){sl=entry-maxSL*point;}
             if(entry > (ma_vall(1)-10*point) && sl < ma_vall(1) && byask == 0){entry=ma_vall(1)-5*point;sl=entry-(maxSL*0.9)*point;}
             double tp=entry+minTP*point;//atr_val(1)*2.5;
              if(isFirst == 1){tp=entry+((minTP*2)*point);}
                            clearPending(2);      
                        //else{
                        entryType[1]=1;entryP[1]=entry;entrySL[1]=sl;entryTP[1]=tp;entryExp[1]=expiration;entryCom[1]="E2";//}
                         block("buylimit EEE[2] "+string(entry+" "+time(1,PERIOD_CURRENT)),entry,entry,1,1,1,PERIOD_CURRENT,1,8);
            
         }else if(activeTrend == 2 && ((lastboxdown2+10*point) > lastboxdown && lastboxup >= lastboxdown2)  && lastboxup > (ma_vall(1)-20*point) && ( EEE[1] == 0 ||  EEE[1] > 0 && Eis[1] == 2)){//|| (lastboxdown > lastboxup2)
           usedbox=1;
           double entry=NormalizeDouble(lastboxup-per30,_Digits);
           int bybid=0;
             if(Bid > entry){entry = Bid+10*point;bybid=1;}
                 double sl=lastboxup;//0.0;
                 //if(lastboxup > ma_vall(1)){sl=lastboxup;}
                 if(lastboxup > ma_vall(1) && (sl-entry) < ((maxSL*0.8)*point)){sl=entry+((maxSL*0.8)*point);}//sl=lastboxup;}
                 if(entry < ma_vall(1)){sl=entry+maxSL*point;}
                 if(entry < (ma_vall(1)+10*point) && sl > ma_vall(1) && bybid == 0){entry =ma_vall(1)+5*point;sl=entry+(maxSL*0.9)*point;}
                 double tp=entry-minTP*point;
                 if(isFirst == 1){tp=entry-((minTP*2)*point);}
                             clearPending(2);
                         
                         //else{
                         entryType[1]=2;entryP[1]=entry;entrySL[1]=sl;entryTP[1]=tp;entryExp[1]=expiration;entryCom[1]="E2";//}
                       block("selllimit EEE[2] "+string(entry+" "+time(1,PERIOD_CURRENT)),entry,entry,1,1,1,PERIOD_CURRENT,1,8);
         }

       }
       
       
       }//end of spread max reached
   }//end of if mrkopen 
      
      //---
       //double cot = sar_val(1);
       //block("zone "+string(cot+" "+time(1,PERIOD_CURRENT)),cot,cot,1,1,1,PERIOD_CURRENT,1,8);
        //line(0,"sar_val : "+sraa+" or "+CalculateParabolicSAR(0)+" : MA_val : "+ma_val(0,PERIOD_CURRENT)+" "+time(0,PERIOD_CURRENT),time(0,PERIOD_CURRENT),0,9,2,PERIOD_CURRENT);
       
                
            
   }//end for bar check in 30hr timeframe   
   
   
   
   //---
   //---
   
entires();
   //---
   //---
   
   
   
    //ot=OrdersTotal();pt=PositionsTotal();
   
  //Comment("\ntrend: ",trendIs," EEE[1] :: ",EEE[1], " EEE[2] :: ",EEE[2]," EEE[3] :: ",EEE[3], " ot ",ot," pt ",pt);
  
  
   if(PositionsTotal() != pt){
      //Print("ot : ",ot);
        //---active positions
        for (int pos_0 = PositionsTotal() -1; pos_0 >= 0; pos_0--) {
               ulong positionTicket = PositionGetTicket(pos_0);
               //trade.PositionClose(positionTicket);
               //Print("i exist ",pos_0," ticket: ",positionTicket);
               //--
               if(PositionGetSymbol(POSITION_SYMBOL) != _Symbol){ continue;}
               if(PositionGetInteger(POSITION_MAGIC) != Magic){ continue;}
               
               //Print("i still exist ",pos_0," ticket: ",positionTicket);
               //---
               if(EEE[1] == 0 && PositionGetString(POSITION_COMMENT) == "E1"){
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){//Eis[1]=1;closeall(2);Print("i closed all 1");
                  //adj_sl(EEE[1],99,lolo(1,9));
                  }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){//Eis[1]=2;closeall(1);
                  //adj_sl(EEE[1],99,hihi(1,9));
                  }
                  Print("this is EEE[1] position :: ",positionTicket);
                 //EEE[1]=positionTicket;entryEPosi[1]=1;clearPending(1);clearPending(2);Print("cleared by 1");
              }else if(EEE[2] == 0 && PositionGetString(POSITION_COMMENT) == "E2"){
                  //if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){Eis[2]=1;}else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){Eis[2]=2;}
                  //EEE[2]=positionTicket;entryEPosi[2]=1;clearPending(1);clearPending(2);
                  Print("this is EEE[2] position :: ",positionTicket);
               }else if(EEE[3] == 0 && PositionGetString(POSITION_COMMENT) == "E3"){
                  //if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){Eis[3]=1;closeall(2);Print("i closed all 2");}else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){Eis[3]=2;closeall(1);}
                  //EEE[3]=positionTicket;entryEPosi[3]=1;clearPending(1);clearPending(2);Print("cleared by 19");
               }
               
               //---
               //if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
               //}else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
               //}
        }
       pt=PositionsTotal();
        }

   if(OrdersTotal() != ot){
   ot=OrdersTotal();
     //---
     for (int pos_0 = OrdersTotal()-1; pos_0 >= 0; pos_0--) {
               ulong orderTicket = OrderGetTicket(pos_0);
               //---
               if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
               if(OrderGetInteger(ORDER_MAGIC) != Magic) continue;
               
               //---
               for(int in=0;in < 10;in++){
                    if(Epending[in] != orderTicket && OrderGetString(ORDER_COMMENT) == (string)("E"+in)){Epending[in]=orderTicket;pendingEPosi[in]=1;if(in == 3){adj_stop(Epending[in]);}}
               }         
         }
      }
    
//gold standard.
   equity = NormalizeDouble(((double)initialBal * (double)PercentEquityUseable/100),2);
   initialBal=NormalizeDouble(initialBal,2);
   int sprd = (Ask-Bid)/point;
   //update panel
   //Print("valll9090909090: ", equity," ", Ask-Bid," ",_Digits," ", point);
   panel.Update(Lots,initialBal,PercentEquityUseable,equity,TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES),sprd,(int)EEE[1],(int)EEE[2],avZ[3],avZ[4],volOverall,volINST[1],volINST[2],dayOverall);
}
//+------------------------------------------------------------------+



void entires(){
   //entries
   //to limit
   if(entryType[1] == 1 && noentry != 1){           
      trade.BuyLimit(Lots,entryP[1],_Symbol,entrySL[1],entryTP[1],ORDER_TIME_SPECIFIED,entryExp[1],entryCom[1]);
   }else if(entryType[1] == 2 && noentry != 2){           
      trade.SellLimit(Lots,entryP[1],_Symbol,entrySL[1],entryTP[1],ORDER_TIME_SPECIFIED,entryExp[1],entryCom[1]);
   }   
      entryType[1]=0;entryP[1]=0.0;entrySL[1]=0.0;entryTP[1]=0.0;entryExp[1]=0;entryCom[1]="";
   
   //to stop
   if(entryType[2] == 1 && noentry != 1){           
      trade.BuyStop(Lots,entryP[2],_Symbol,entrySL[2],entryTP[2],ORDER_TIME_SPECIFIED,entryExp[2],entryCom[2]);
   }else if(entryType[2] == 2 && noentry != 2){           
      trade.SellStop(Lots,entryP[2],_Symbol,entrySL[2],entryTP[2],ORDER_TIME_SPECIFIED,entryExp[2],entryCom[2]);
   }
       entryType[2]=0;entryP[2]=0.0;entrySL[2]=0.0;entryTP[2]=0.0;entryExp[2]=0;entryCom[2]="";
   
   //mrk entry
   if(entryType[3] == 1 && noentry != 1){           
      trade.Buy(Lots,_Symbol,Ask,entrySL[3],entryTP[3],entryCom[3]);
   }else if(entryType[3] == 2 && noentry != 2){           
      trade.Sell(Lots,_Symbol,Bid,entrySL[3],entryTP[3],entryCom[3]);
   }
      entryType[3]=0;entryP[3]=0.0;entrySL[3]=0.0;entryTP[3]=0.0;entryExp[3]=0;entryCom[3]="";
 } 
 
 
//---
void clearPending(int type){

      //----pending orders
        for (int pos_0 = 0; pos_0 < OrdersTotal(); pos_0++) {
               ulong orderTicket = OrderGetTicket(pos_0);               
               //---
               if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
               if(OrderGetInteger(ORDER_MAGIC) != Magic) continue;
               
               //---
              if(OrderGetString(ORDER_COMMENT) == (string)("E"+type)){
                  trade.OrderDelete(orderTicket);
                }
                /*if(type == 1 && OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_LIMIT){
                  trade.OrderDelete(orderTicket);
                }*/
         }
         Epending[type]=0;
}


//---
void adj_stop(int ticket){
    //----
      if(OrderSelect(ticket)){
               
               //--- adjusting my solid.
               //Print(" open stop price current : "+OrderGetDouble(ORDER_PRICE_CURRENT)+ " : open stop price open : "+OrderGetDouble(ORDER_PRICE_OPEN));
               if(OrderGetString(ORDER_COMMENT) == "E3"){//Print("fooooorund EEE[1] #",orderTicket);&& bagVal[22] > open(1)+100*point
                  if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP && ( ( (close(1)-5*point > high(2)) && open(1) > OrderGetDouble(ORDER_PRICE_OPEN)))){//&& close(2) > high(3) //(is_solid(2) && open(2) < Bid && open(2) > OrderGetDouble(ORDER_PRICE_OPEN)) || 
                     double ent = 0.0;
                     if( close(1)-5*point > high(2)){ent=low(1)-20*point;}//open(1)
                     trade.OrderModify(ticket,ent,ent+(maxSL*point),ent-((minTP*2)*point),ORDER_TIME_SPECIFIED,TimeCurrent()+ExpireSec*2);
                  }else if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP && ( ( (close(1)+5*point < low(2)) && open(1) < OrderGetDouble(ORDER_PRICE_OPEN)))){// && close(2) < low(3) //(is_solid(2) && open(2) > Ask  && open(2) < OrderGetDouble(ORDER_PRICE_OPEN)) ||
                     double ent = 0.0;//open(2);
                     if( close(1)+5*point < low(2)){ent=high(1)+20*point;}//is_solid(1) &&
                     trade.OrderModify(ticket,ent,ent-(maxSL*point),ent+((minTP*2)*point),ORDER_TIME_SPECIFIED,TimeCurrent()+ExpireSec*2);
                  }
               }
         }//else{Epending[3]=0;}
}



//---trailing sl for EEE[1]
bool adj_sl(int ticket,int ticketType,double entr=0.0){
    //---active positions
    if(PositionSelectByTicket(ticket)){
            
            if(ticketType == 1){
               
               //---trailing
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && is_solid(2) && (open(2)-20*point) > PositionGetDouble(POSITION_SL) && open(2)-20*point > PositionGetDouble(POSITION_PRICE_OPEN)){
                      double newSL = open(2)-20*point;
                      if(PositionGetDouble(POSITION_SL) > newSL) newSL = PositionGetDouble(POSITION_SL);
                      newSL=NormalizeDouble(newSL,_Digits);
                      if(newSL != PositionGetDouble(POSITION_SL)) trade.PositionModify(ticket,newSL,PositionGetDouble(POSITION_TP));
               }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && is_solid(2) && (open(2)+20*point) < PositionGetDouble(POSITION_SL)&& open(2)+20*point < PositionGetDouble(POSITION_PRICE_OPEN)){
                      double newSL = open(2)+20*point;
                      if(PositionGetDouble(POSITION_SL) < newSL) newSL = PositionGetDouble(POSITION_SL);
                      newSL=NormalizeDouble(newSL,_Digits);
                      if(newSL != PositionGetDouble(POSITION_SL)) trade.PositionModify(ticket,newSL,PositionGetDouble(POSITION_TP));
               }
            }else if(ticketType == 2){
            //EEE[2]  to void
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                     double newSL = PositionGetDouble(POSITION_PRICE_OPEN)+(Ask-Bid);
                      if(PositionGetDouble(POSITION_SL) > newSL || Bid < newSL) newSL = PositionGetDouble(POSITION_SL);
                      newSL=NormalizeDouble(newSL,_Digits);
                      if(newSL != PositionGetDouble(POSITION_SL)){trade.PositionModify(ticket,newSL,PositionGetDouble(POSITION_TP));return true;}
                     
               }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                      double newSL = PositionGetDouble(POSITION_PRICE_OPEN)-(Ask-Bid);
                      if(PositionGetDouble(POSITION_SL) < newSL || Ask > newSL) newSL = PositionGetDouble(POSITION_SL);
                     newSL=NormalizeDouble(newSL,_Digits);
                     if(newSL != PositionGetDouble(POSITION_SL)){trade.PositionModify(ticket,newSL,PositionGetDouble(POSITION_TP)); return true;}
               }
            }else if(ticketType == 3){
            //EEE[2]  to void
               double newSL=NormalizeDouble(entr,_Digits);
                      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && entr < PositionGetDouble(POSITION_SL)){ newSL = PositionGetDouble(POSITION_SL);
                      }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && entr > PositionGetDouble(POSITION_SL)){ newSL = PositionGetDouble(POSITION_SL);}
                      newSL=NormalizeDouble(newSL,_Digits);
                      if(newSL != PositionGetDouble(POSITION_SL)){
                        trade.PositionModify(ticket,newSL,PositionGetDouble(POSITION_TP));
                      }
                 
              }else if(ticketType == 99){
            //EEE[2]  to void
               double newSL=NormalizeDouble(entr,_Digits);
                      //if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && entr < PositionGetDouble(POSITION_SL)){ newSL = PositionGetDouble(POSITION_SL);
                      //}else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && entr > PositionGetDouble(POSITION_SL)){ newSL = PositionGetDouble(POSITION_SL);}
                      if(newSL != PositionGetDouble(POSITION_SL)){
                        trade.PositionModify(ticket,newSL,PositionGetDouble(POSITION_TP));
                      }
                 
             }else if(ticketType == 4){
            //EEE[1]  to reduce sl
               double newSL=PositionGetDouble(POSITION_SL);
                      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY &&  PositionGetDouble(POSITION_SL) <  (PositionGetDouble(POSITION_PRICE_OPEN)-maxSL*point)){
                       newSL = PositionGetDouble(POSITION_SL)+85*point; if(Bid < newSL ){newSL=Bid-25*point;}
                      if(PositionGetDouble(POSITION_SL) > newSL) newSL = PositionGetDouble(POSITION_SL);
                      }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && PositionGetDouble(POSITION_SL) >  (PositionGetDouble(POSITION_PRICE_OPEN)+maxSL*point)){
                       newSL = PositionGetDouble(POSITION_SL)-85*point; if(Ask > newSL ){newSL=Ask+25*point;}
                      if(PositionGetDouble(POSITION_SL) < newSL) newSL = PositionGetDouble(POSITION_SL);}
                      
                      newSL=NormalizeDouble(newSL,_Digits);
                      if(newSL != PositionGetDouble(POSITION_SL)){
                        trade.PositionModify(ticket,newSL,PositionGetDouble(POSITION_TP));
                      }
                 
            }else if(ticketType == 9){
               //---trailing
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && is_solid(2) && (open(2)-20*point) > PositionGetDouble(POSITION_SL) && open(2)-20*point > PositionGetDouble(POSITION_PRICE_OPEN)){
                      double newSL = open(2)-20*point;
                      if(PositionGetDouble(POSITION_SL) > newSL) newSL = PositionGetDouble(POSITION_SL);
                     newSL=NormalizeDouble(newSL,_Digits);
                      if(newSL != PositionGetDouble(POSITION_SL)) trade.PositionModify(ticket,newSL,PositionGetDouble(POSITION_TP));
               }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && is_solid(2) && (open(2)+20*point) < PositionGetDouble(POSITION_SL)&& open(2)+20*point < PositionGetDouble(POSITION_PRICE_OPEN)){
                      double newSL = open(2)+20*point;
                      if(PositionGetDouble(POSITION_SL) < newSL) newSL = PositionGetDouble(POSITION_SL);
                     newSL=NormalizeDouble(newSL,_Digits);
                     if(newSL != PositionGetDouble(POSITION_SL)) trade.PositionModify(ticket,newSL,PositionGetDouble(POSITION_TP));
               }
                 
            }
            
     }else{}
     return false;

}
//
bool adj_tp(int ticket,int ticketType,double entr=0.0){
    //---active positions
    if(PositionSelectByTicket(ticket)){
            
            if(ticketType == 1){
               double newtp=PositionGetDouble(POSITION_TP);
                      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && PositionGetDouble(POSITION_TP) < (PositionGetDouble(POSITION_PRICE_OPEN)+(minTP*2)*point)){ newtp = (PositionGetDouble(POSITION_PRICE_OPEN)+(minTP*2)*point);
                      }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && PositionGetDouble(POSITION_TP) > (PositionGetDouble(POSITION_PRICE_OPEN)-(minTP*2)*point)){ newtp = (PositionGetDouble(POSITION_PRICE_OPEN)-(minTP*2)*point);}
                      newtp=NormalizeDouble(newtp,_Digits);
                      if(newtp != PositionGetDouble(POSITION_TP)){
                        trade.PositionModify(ticket,PositionGetDouble(POSITION_SL),newtp);
                      }
            }else if(ticketType == 9){
               double newtp=PositionGetDouble(POSITION_TP);
                      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && PositionGetDouble(POSITION_TP) < (PositionGetDouble(POSITION_PRICE_OPEN)+(minTP*3)*point)){ 
                        newtp = (PositionGetDouble(POSITION_PRICE_OPEN)+(minTP*3)*point);
                      }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && PositionGetDouble(POSITION_TP) > (PositionGetDouble(POSITION_PRICE_OPEN)-(minTP*3)*point)){ 
                        newtp = (PositionGetDouble(POSITION_PRICE_OPEN)-(minTP*3)*point);}
                      newtp=NormalizeDouble(newtp,_Digits);
                      if(newtp != PositionGetDouble(POSITION_TP)){
                        trade.PositionModify(ticket,PositionGetDouble(POSITION_SL),newtp);
                      }
            }
     }
     
     return false;
 }



void closeall(int typee){
Print("calledout");
    for (int pos_0 = PositionsTotal()-1; pos_0 >=0 ; pos_0--) {
            ulong positionTicket = PositionGetTicket(pos_0);             
               //---
               //if(PositionGetSymbol(POSITION_SYMBOL) != _Symbol) continue;
               //if(PositionGetInteger(POSITION_MAGIC) != Magic) continue;
               Print("found ",positionTicket);
               //---
               if(typee == 1 && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                trade.PositionClose(positionTicket);//Print("tryed cloes");
               }else if(typee == 2 && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                trade.PositionClose(positionTicket);
               }
               /*if(PositionGetString(ORDER_COMMENT) == "EEE[1]" && type == 1){
                  trade.PositionClose(positionTicket);
                }else if(PositionGetString(ORDER_COMMENT) == "EEE[2]" && type == 2){
                  trade.PositionClose(positionTicket);
                }*/
         }
         //if(type == 1){EEE[2]=0;}else if(type == 2){Epending[2]=0;}
}



//---
double tick(string val="bid"){

    if(val == "bid"){
      return NormalizeDouble((double)SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
    }else if(val == "ask"){
      return NormalizeDouble((double)SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
    }else{ return 0.0;}
}



//+------------------------------------------------------------------+
//| Volume Spike Detection Function                                  |
//+------------------------------------------------------------------+
bool IsVolumeSpike(int barsToCheck, double spikeThreshold) {
   /*
   * barsToCheck: Number of bars to evaluate for volume spikes
   * spikeThreshold: Multiplier for average volume (e.g., 1.5 for 50% increase)
   * Returns: True if a volume spike is detected
   */

   double averageVolume = 0.0;
   int i;

   // Calculate average volume over the last 'barsToCheck' bars
   for (i = 1; i <= barsToCheck; i++) {
      averageVolume += iVolume(_Symbol, _Period, i);
   }
   averageVolume /= barsToCheck;

   // Check if the current bar's volume is a spike
   double currentVolume = iVolume(_Symbol, _Period, 0);
   if (currentVolume > averageVolume * spikeThreshold) {
      //Print("Volume spike detected! Current Volume: ", currentVolume," | Average Volume: ", averageVolume);
      return true;
   }
   return false;
}






long vol(int posi=1,ENUM_TIMEFRAMES frame=PERIOD_CURRENT){
   return iVolume(_Symbol,frame,posi);
}
double sar_val(int posi = 0, ENUM_TIMEFRAMES frame = PERIOD_CURRENT){
 
    double slowSar[99999];
   CopyBuffer(sar,0,1,2,slowSar);
   ArraySetAsSeries(slowSar,true);
   return NormalizeDouble(slowSar[posi], _Digits);
}
double ma_vall(int posi = 0, ENUM_TIMEFRAMES frame = PERIOD_CURRENT){
   
   double slowMa[99999];
   CopyBuffer(ma,0,1,2,slowMa);
   ArraySetAsSeries(slowMa,true);
   return NormalizeDouble(slowMa[posi], _Digits);
}
double atr_val(int posi = 0, ENUM_TIMEFRAMES frame = PERIOD_CURRENT){
   
   double slowAtr[99999];
   CopyBuffer(atr,0,1,2,slowAtr);
   ArraySetAsSeries(slowAtr,true);
   return NormalizeDouble(slowAtr[posi], _Digits);
}
double high(int posi = 0, ENUM_TIMEFRAMES frame = PERIOD_CURRENT){
   return NormalizeDouble(iHigh(NULL, frame, posi), _Digits);
}
double low(int posi = 0, ENUM_TIMEFRAMES frame = PERIOD_CURRENT){
   return NormalizeDouble(iLow(NULL, frame, posi), _Digits);
}
double close(int posi = 0, ENUM_TIMEFRAMES frame = PERIOD_CURRENT){
   return NormalizeDouble(iClose(NULL, frame, posi), _Digits);
}
double open(int posi = 0, ENUM_TIMEFRAMES frame = PERIOD_CURRENT){
   return NormalizeDouble(iOpen(NULL, frame, posi), _Digits);
}
datetime time(int posi = 0, ENUM_TIMEFRAMES frame = PERIOD_CURRENT){
   return iTime(NULL, frame, posi);
}



void line (int type=1, string name="line",double place=0.0, int shift=0,int col =1, int style=0, ENUM_TIMEFRAMES tim=PERIOD_CURRENT){
    //1 = OBJ_HLINE, 0 = OBJ_VLINE
    //1 = STYLE_DASH, 2 = STYLE_DOT,0 solid, 3 mixture of dot and dash
     if(type == 1){ObjectCreate(0,name,OBJ_HLINE, 0,time(shift, tim),place);
     }else{ObjectCreate(0,name,OBJ_VLINE, 0,time(shift, tim),place);}
    needObj(name,col,style);
  }

void block(string name="box",double xPricE1 = 0.0, double xPricE2 = 0.0,int yPosition1 = 0,int yPosition2 = 0, int col=1,ENUM_TIMEFRAMES tim=PERIOD_CURRENT,int style=0,int width=1){
   ObjectCreate(0,name, OBJ_RECTANGLE, 0, time(yPosition1,tim), xPricE1, time(yPosition2,tim), xPricE2);
   needObj(name,col,style,width);
  }
  
void trendL(string name="trendL",double xPricE1 = 0.0, double xPricE2 = 0.0,int yPosition1 = 0,int yPosition2 = 0, int col=1,ENUM_TIMEFRAMES tim=PERIOD_CURRENT,int style=0,int width=1){
   ObjectCreate(0,name, OBJ_TREND, 0, time(yPosition1,tim), xPricE1, time(yPosition2,tim), xPricE2);
   needObj(name,col,style,width);
  }
  
  
void needObj(string name,int col,int style,int width=1){
if(col == 1){ObjectSetInteger(0,name,OBJPROP_COLOR,Blue);
    }else if(col == 2){ObjectSetInteger(0,name,OBJPROP_COLOR,LightBlue);
    }else if(col == 3){ObjectSetInteger(0,name,OBJPROP_COLOR,Pink);
    }else if(col == 4){ObjectSetInteger(0,name,OBJPROP_COLOR,Red);
    }else if(col == 5){ObjectSetInteger(0,name,OBJPROP_COLOR,DeepPink);
    }else if(col == 6){ObjectSetInteger(0,name,OBJPROP_COLOR,Yellow);
    }else if(col == 7){ObjectSetInteger(0,name,OBJPROP_COLOR,Green);
    }else if(col == 8){ObjectSetInteger(0,name,OBJPROP_COLOR,LightGreen);
    }else if(col == 9){ObjectSetInteger(0,name,OBJPROP_COLOR,White);
    }else if(col == 10){ObjectSetInteger(0,name,OBJPROP_COLOR,Purple);
    }else if(col == 11){ObjectSetInteger(0,name,OBJPROP_COLOR,Gray);
    }else if(col == 12){ObjectSetInteger(0,name,OBJPROP_COLOR,PowderBlue);
    }else if(col == 13){ObjectSetInteger(0,name,OBJPROP_COLOR,DarkOliveGreen);
    }else if(col == 14){ObjectSetInteger(0,name,OBJPROP_COLOR,Black);
    }else{ ObjectSetInteger(0,name,OBJPROP_COLOR,Black);}
     ObjectSetInteger(0,name,OBJPROP_STYLE,style);
     ObjectSetInteger(0,name,OBJPROP_WIDTH,width);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////

//---


 double hihi(int from, int to, int viewby=0, ENUM_TIMEFRAMES perio=PERIOD_CURRENT)
 { double kk = high(from, perio);
 int okh = to - from,
     got = 0,jj = from;
 for(int i = 0; i < okh; i++)
 {
  got = to - i;
   if(high(got, perio) > kk)
   { kk = high(got, perio);jj=got;}  
 }
 if(viewby == 1) kk=jj;
 return kk;
 }
 
  
   double lolo(int from, int to, int viewby=0, ENUM_TIMEFRAMES perio=PERIOD_CURRENT)
 {double kk = low(from, perio);
 int okh = to - from,
     got = 0,jj=from;;
 for(int i = 0; i < okh; i++)
 { got = to - i;
   if(low(got, perio) < kk)
   { kk = low(got, perio);jj=got;}
 }
 if(viewby == 1) kk=jj;
 return kk;
 } 
 
 
 //---
 
 double hihiC(int from, int to, int viewby=0, ENUM_TIMEFRAMES perio=PERIOD_CURRENT)
 { double kk = open(from, perio);
 int okh = to - from,
     got = 0,jj = from;
 for(int i = 0; i < okh; i++)
 {
  got = to - i;
   if(open(got, perio) > kk)
   { kk = open(got, perio);jj=got;}  
 }
 if(viewby == 1) kk=jj;
 return kk;
 }
 
  
   double loloC(int from, int to, int viewby=0, ENUM_TIMEFRAMES perio=PERIOD_CURRENT)
 {double kk = close(from, perio);
 int okh = to - from,
     got = 0,jj=from;;
 for(int i = 0; i < okh; i++)
 { got = to - i;
   if(close(got, perio) < kk)
   { kk = close(got, perio);jj=got;}
 }
 if(viewby == 1) kk=jj;
 return kk;
 } 
 
 //---
 
 bool is_solid(int position){
   if(close(position) > open(position)){//is buy candle
      if((((high(position)-low(position))/point) - ((close(position) - open(position))/point)) < ((close(position) - open(position))/point)+5) return true;
   }else if(close(position) < open(position)){//is sell candle
      if((((high(position)-low(position))/point) - ((open(position) - close(position))/point)) < ((open(position) - close(position))/point)+5) return true;
   }
 return false;
 }
 
 
 //---
 
 int strategy(double sar_val,double ma_val,int i=1){
      //---
      //--- sar doc 1current,2,3,4
      
      int cler=0;
      //---
      if(close(i) > (ma_val+20*point) && trendOn != 1){trendOn=1;trending1=0.0;trending2=0.0;
      }else if(close(i) < (ma_val-20*point)  && trendOn != 2){trendOn=2;trending1=0.0;trending2=0.0;}
      
      
      //
      for(int ii=39;ii>=1;ii--){if(bagPE[ii] >= 1){bagPE[ii]+=1;}}
            
         if(sar_val > open(i) && wilup != 1){wilup=1;
         }else if(sar_val < open(i) && wilup != 2){wilup=2;}
          //Print("i: "+i+" sar: "+sar_val(i)+" open: "+open(i));
            if(wilup==1){
             if(action != 1 ){action=1;swit=1;}
            }else if(wilup==2){
              if(action != 2 ){action=2;swit=1;}}
              
             /* if(close(1) > bagVal[1] && trendOn == 2){action=1;swit=1;
              }else if(close(1) < bagVal[11] && trendOn == 1){action=2;swit=1;}
            */
            if((action == 2 ) && swit == 1){ if( bag[1]>3){//  bag[11]>3 &&|| (close(i) > bagVal[1])
            //up looking sar
               if(action == 2){bagPE[1]=i+1; }else{if(bag[11]==0){bagPE[1]=bag[12]+1;}else{bagPE[1]=bag[11]+1;} }
               
               bagPE[41]=trendOn;
               if(sar_val > ma_val && activeTrend == 1){bagPE[41]=1;}else{bagPE[41]=2;}//bagVal[1]
               for(int ii=9;ii>1;ii--){
                  bag[ii]=bag[ii-1];
                  bagPE[ii]=bagPE[ii-1];
                  bagPE[ii+20]=bagPE[(ii+20)-1];
                  bagPE[ii+40]=bagPE[(ii+40)-1];
                  bagVal[ii]=bagVal[ii-1];
                  bagVal[ii+20]=bagVal[(ii+20)-1];
                  bagVal[ii+40]=bagVal[(ii+40)-1];
                  bagVal[ii+60]=bagVal[(ii+60)-1];
                  bagStat[ii]=bagStat[ii-1];}    }cler=1;}//action=1;}
            if((action == 1 ) && swit == 1){if( bag[11]>3){ //|| (close(1) < bagVal[11])  bag[1]>3 &&|| (close(i) < bagVal[11])
            //down looking sar
               //bagPE[11]=bag[11]+1; 
                if(action == 1){bagPE[11]=i+1; }else{if(bag[1]==0){bagPE[11]=bag[2]+1;}else{bagPE[11]=bag[1]+1;} }
               
               bagPE[51]=trendOn;
               if(sar_val < ma_val  && activeTrend == 2){bagPE[51]=2;}else{bagPE[51]=1;}//bagVal[11]
               for(int ii=19;ii>11;ii--){
                  bag[ii]=bag[ii-1];
                  bagPE[ii]=bagPE[ii-1];
                  bagPE[ii+20]=bagPE[(ii+20)-1];
                  bagPE[ii+40]=bagPE[(ii+40)-1];
                  bagVal[ii]=bagVal[ii-1];
                  bagVal[ii+20]=bagVal[(ii+20)-1];
                  bagVal[ii+40]=bagVal[(ii+40)-1];
                  bagVal[ii+60]=bagVal[(ii+60)-1];
                  bagStat[ii]=bagStat[ii-1];}     }bagVal[11]=0.0;bag[11]=0;bagVal[71]=0.0;}//action=2;}
            //
            if(cler == 1){bagVal[1]=0.0;bag[1]=0;bagVal[61]=0.0;cler=0;}
            //
            if(wilup==1){   bag[1]+=1;  bagVal[1]=sar_val; if(bag[1] == 1){bagVal[61]=sar_val;}
            }else if(wilup==2){  bag[11]+=1;  bagVal[11]=sar_val;   if(bag[11] == 1){bagVal[71]=sar_val;}}
            
            
            
            
            
            //---
            if(trending1 != 0.0 && (high(i)-15*point) > trending1 ){trendIs=1;if(activeTrend==2){activeTrend=1;firsttbox=2;isFirst=1;noentry =0; posiLine=1;line(0,"new trend : 1 :: "+time(0,PERIOD_CURRENT),time(0,PERIOD_CURRENT),1,9,0,PERIOD_CURRENT);}
            yesbrk=0;trending1=0.0;trending2=0.0;needbrk=0.0;//clearPending(1);
            //   Print("cleared by 3");line(0,"new trend : 1 :: "+time(0,PERIOD_CURRENT),time(0,PERIOD_CURRENT),1,9,0,PERIOD_CURRENT);
            }else if(trending2 != 0.0 && (low(i)+15*point) < trending2){trendIs=2;if(activeTrend == 1){activeTrend=2;firsttbox=1;isFirst=1;noentry =0; posiLine=1;line(0,"new trend : 2 :: "+time(0,PERIOD_CURRENT),time(0,PERIOD_CURRENT),1,9,0,PERIOD_CURRENT);}
            yesbrk=0;trending1=0.0;trending2=0.0;needbrk=0.0;//clearPending(1);
             //  Print("cleared by 4");line(0,"new trend : 2 :: "+time(0,PERIOD_CURRENT),time(0,PERIOD_CURRENT),1,9,0,PERIOD_CURRENT);
             }
            
            if(trendOn != trendIs && (trending1+trending2) == 0.0){
               if(trendOn == 1 &&  bag[1] > 3){trending1=bagVal[61];
               }else if(trendOn == 2 &&  bag[11] > 3){trending2=bagVal[71];}
            }
            
           //---
            //if(high(i) > bagVal[61] && trendIs ==1 && Epending[1] > 0){clearPending(1);Print("cleared by 5");
            //}else if(low(i) < bagVal[71] && trendIs ==2 && Epending[1] > 0){clearPending(1);Print("cleared by 6");}
            
            //62
            //Print("this is: Epending[2] ",Epending[2]," bagVal[62]: ",bagVal[62]," bagVal[61]: ",bagVal[61]," activeTrend ",activeTrend," close(i+1) ",close(i+1));
            //if(((close(i+1) > bagVal[61]+10*point && bagVal[61] > point) || (bagVal[61] < 10*point && close(i+1) > bagVal[62]+10*point)) && activeTrend ==1 && Epending[2] > 0){clearPending(2);Print("cleared by 7");
            //}else if(((close(i+1) < bagVal[71]-10*point && bagVal[71] > point) || (bagVal[71] < 10*point && close(i+1) < bagVal[72]-10*point)) && activeTrend ==2 && Epending[2] > 0){clearPending(2);Print("cleared by 8");}
            
      //up ###### down
     //Print(" ##### bag1: "+bag[1]+" Bag2: "+bag[2]+":Posi: "+bagPE[2]+" bag3: "+bag[3]+":Posi: "+bagPE[3]+"\n ###### bag11: "+bag[11]+" Bag12: "+bag[12]+":Posi: "+bagPE[12]+" bag13: "+bag[13]+":Posi: "+bagPE[13]+" ");
      
      //--- trend on sar
     // for(int ox=2;ox<10;ox++){
       if(true){int ox=2;
         
         
         if(activeTrend == 1 && bagStat[12] < 1 && swit == 1){bagStat[12]=1;
               if( (bagPE[ox+11]-(bag[10+ox]+1)) > 5){//4 3dots
                     double hihii = hihi(bagPE[10+ox]+1,(bagPE[ox]));
                     double loloi = lolo(bagPE[10+ox]+3,(bagPE[11+ox]));
                     bagVal[20+ox]=hihii;
                     bagVal[40+ox]=loloi;
                     int colo=2;newbox=1;if(bagPE[10+ox] < posiLine){usedbox=0;}
                     if(hihii < bagVal[2]){colo=5;}
                              block("hhgg"+string(" "+time(bagPE[10+ox],PERIOD_CURRENT)),hihii,loloi,bagPE[10+ox],(bagPE[11+ox]),colo,PERIOD_CURRENT,0,1);
                             // trendL("trendL"+string(time((int)i,PERIOD_CURRENT)),bagVal[10+ox],close(i),bagPE[10+ox],i,9,PERIOD_CURRENT,2);
         }else{clearPending(1);}}
         if(activeTrend == 2 && bagStat[2] < 1 && swit == 1){bagStat[2]=1;
            if((bagPE[ox+1]-(bag[ox]+1)) > 5){
               double hihii = hihi(bagPE[ox]+3,(bagPE[ox+1]));
               double loloi = lolo(bagPE[ox]+1,(bagPE[ox+10]));
               bagVal[30+ox]=hihii;
               bagVal[50+ox]=loloi;
               int colo=2;newbox=1;if(bagPE[ox] < posiLine){usedbox=0;}
               if(loloi > bagVal[12]){colo=5;}
                        block("hh"+string(" "+time(bagPE[ox],PERIOD_CURRENT)),hihii,loloi,bagPE[ox],(bagPE[ox+1]),colo,PERIOD_CURRENT,0,1);
                       // trendL("trendL"+string(time((int)i,PERIOD_CURRENT)),bagVal[ox],close(i),bagPE[ox],i,9,PERIOD_CURRENT,2);
         }else{clearPending(1);}}
         
      }
     //---
     
      swit=0;
      
   return 0;
 }
 

 
 //---
 int sendMessage(string text, string chatID, string botToken){
   string baseUrl = "https://api.telegram.org";
   string header = "Content-Type:application/x-www-form-urlencoded\r";
   string requestUrl = "";
   string requestHeaders = "";
   char resultData[];
   char posData[];
   int timeout = 2000;
   
   requestUrl = StringFormat("%s/bot%s/sendmessage?chat_id=%s&text=%s",baseUrl,botToken,chatID,text);
   int response = WebRequest("POST", requestUrl,header,timeout,posData,resultData,requestHeaders);
   
   string resultMessage = CharArrayToString(resultData);
   Print(__FUNCTION__,"",resultMessage);
   
   return response;
 } 
 
 
 
 /////////////// chart event handler
 void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam){
   panel.PanelChartEvent(id,lparam,dparam,sparam);
 }
 