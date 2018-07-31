Program Ultra(input,output,Param,Data);
{-----------------------------------------------------------------------------}
{                                                                             }
{     Title:         LICVD Process                                            }
{                                                                             }
{     Author:        Chris Harris                                             }
{                    John Flint                                               }
{                    Tom Kramer                                               }
{                                                                             }
{     Date:          Written 4/10/86             Revised 2/12/87              }
{                                                                             }
{     Purpose:       This program was developed specifically for data         }
{                    acquisition and process control of the laser-induced     }
{                    chemical vapor deposition(LICVD) apparatus.  However,    }
{                    the software was written in a modular form so that       }
{                    subroutines could be added, deleted, or modified to      }
{                    fulfill a wide range of laboratory automation schemes.   }
{                                                                             }
{     Equipment:     Compaq Portable Computer w/8087 microprocessor           }
{                    Data Translation DT2805 data acquisition board           }
{                    Data Translation DT707-T screw panel                     }
{                                                                             }
{     Language:      Turbo Pascal; TURBO-87, version 3.0                      }
{                                                                             }
{-----------------------------------------------------------------------------}
{                                                                             }
{     Variable                                   Description                  }
  const
    BaseAdd  = $2EC;              { board address                             }
    ComWait  =   $4;              { command wait                              }
    WritWait =   $2;              { write wait                                }
    ReadWait =   $5;              { read wait                                 }
    CStop    =   $F;              { command stop                              }
    CClear   =   $1;              { command clear                             }
    CErr     =   $2;              { command read error                        }
    CTest    =   $B;              { command test                              }
    CAD      =   $C;              { command A/D(analog input)                 }
    CDA      =   $8;              { command D/A(analog output)                }
    CSIn     =   $4;              { command set digital port for input        }
    CSOut    =   $5;              { command set digital port for output       }
    CDIn     =   $6;              { command digital input                     }
    CDOut    =   $7;              { command digital output                    }
    NOC      = 4096;              { number of counts(resolution)              }
    HighV    =   10;              { high voltage for board                    }
    LowV     =  -10;              { low voltage for board                     }
  type
    intdim      = array[0..7] of integer;
    bytedim     = array[0..7] of byte;
    realdim     = array[0..7] of real;
    datadim     = array[0..7,0..500] of real;
    longstring  = array[0..7] of string[20];
    shortstring = array[0..7] of string[10];
    timestring  = string[11];
  var
    Color        : integer;       { screen color number                       }
    InnerChoice  : char;          { screen options                            }
    OuterChoice  : integer;       { option number for run choice              }
    i            : integer;       { channel index                             }
    j            : integer;       { display index                             }
    k            : integer;       { bit index                                 }
    m            : integer;       { averaging index                           }
    n            : integer;       { number of channels to be monitored        }
    q            : integer;       { number of data points used in average     }
    ErrCnt       : integer;       { error count during board test             }
    ComReg       : integer;       { command register                          }
    StatReg      : integer;       { status register                           }
    DataReg      : integer;       { data register                             }
    AnalogVal    : integer;       { value from A/D conversion(digital form)   }
    Range        : integer;       { voltage range(HighV-LowV)                 }
    DACPort      : byte;          { analog output port                        }
    PortIn       : byte;          { digital input port                        }
    PortOut      : byte;          { digital output port                       }
    Junk         : byte;          { variable for clearing data register       }
    Loop         : byte;          { test loop index                           }
    DataVal      : byte;          { data value from digital input             }
    DigitalVal   : byte;          { digital value for digital output          }
    LowByte      : byte;          { low byte to/from data register            }
    HighByte     : byte;          { high byte to/from data register           }
    Status       : byte;          { status from status register               }
    Err1         : byte;          { low byte from error routine               }
    Err2         : byte;          { high byte from error routine              }
    Direction    : integer;       { controller direction relative to laser    }
                                  {   peak                                    }
    DesiredVolts : real;          { desired volts for analog output           }
    NewE         : real;          { error feedback that is sent to controller }
    OldE         : real;          { one point before NewE                     }
    dR           : real;          { set-point specified by user               }
    dM           : real;          { voltage output from controller            }
    dt           : real;          { time between measurements                 }
    t            : real;          { accumulated time                          }
    Kc           : real;          { proportional control constant             }
    SqrIntegral  : real;          { error squared sum(controller performance) }
    FringeNum    : real;          { number of fringes                         }
    NewPoint     : real;          { most recent data point in CountFringe     }
    OldPoint     : real;          { one point before NewPoint                 }
    NewMax       : real;          { most recent data point in Maximize        }
    OldMax       : real;          { one point before NewMax                   }
    NewSign      : boolean;       { most recent slope in CountFringe          }
                                  {   ( true: + / false: - )                  }
    OldSign      : boolean;       { one sign before NewSign                   }
    StopFlag     : boolean;       { flag variable to stop program             }
    FringeFlag   : boolean;       { flag variable to initialize OldSign       }
    BreakFlag    : boolean;       { flag variable to break program            }
    GraphFlag    : boolean;       { flag variable to update graph             }
    Gain         : intdim;        { gain for A/D conversion                   }
    Ch           : bytedim;       { channel for A/D conversion                }
    Code         : bytedim;       { code[0,1,2,3] for gain setting            }
    bit          : bytedim;       { bits used in board error diagnostics      }
    Voltage      : realdim;       { voltage from A/D conversion               }
    MF           : realdim;       { multiplying factor for voltage to unit    }
                                  {   conversion                              }
    UnitVal      : datadim;       { unit value for parameter                  }
    P            : longstring;    { parameter                                 }
    U            : shortstring;   { unit dimensions                           }
    TimeChar     : timestring;    { character representation of time          }
    TimeVal      : real;          { real representation of time               }
    RunTime      : integer;       { time length for run                       }
    OldTime      : real;          { time comparison variable in Update        }
    LastTime     : real;          { time comparison variable in Control       }
    Answer       : char;          { answer to filename question               }
    ParamName    : string[14];    { filename for Param file                   }
    DataName     : string[14];    { filename for Data file                    }
    Param        : text;          { file conaining data acquisition           }
                                  {   parameters                              }
    Data         : text;          { data file generated during run            }
{                                                                             }
{-----------------------------------------------------------------------------}
{                                                                             }
{     PWait:  Performs the port waiting function before the computer can      }
{             read or write information to/from data acquisition board.       }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure PWait(PNumb:integer; PData1,PData2:byte);
    begin
      while((port[PNumb] xor PData2) and PData1)=0 do;
    end; { PWait }
{-----------------------------------------------------------------------------}
{                                                                             }
{     Clock:  Reads the DOS system clock.                                     }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure Clock;
    type
      regpack    = record
                     AX,BX,CX,DX,BP,SI,DI,DS,ES,Flags:integer;
                   end;
      twochar    = string[2];
    var
      Regs      : regpack;
      Hour      : integer;
      Min       : integer;
      Sec       : integer;
      Hund      : integer;
      ClockFlag : boolean;
    function Character(TwoDigit:integer) : twochar;
      begin
        Character:=chr(trunc(TwoDigit div 10)+ord('0')) +
                   chr(TwoDigit mod 10 + ord('0'));
      end; { Character }
    begin
      with Regs do
        begin
          AX:=$2C00;
          MsDos(Regs);
          Hour:=hi(CX);
          Min:=lo(CX);
          Sec:=hi(DX);
          Hund:=lo(DX);
        end; { with }
      TimeChar:=Character(Hour)+':'+Character(Min)+':'+Character(Sec)+'.'+
                Character(Hund);
      TimeVal:=Hour*3600.+Min*60.+Sec/1+Hund/100;
    end; { Clock }
{-----------------------------------------------------------------------------}
{                                                                             }
{     Graph:  Plots data on screen.                                           }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure Graph(i,j :integer);
    const
      xleft   =  40;
      xright  = 620;
      ytop    =  20;
      ybottom = 180;
      ylabel  = 'Full Scale Fraction';
    var
      x      : real;
      y      : real;
      index  : integer;
      xscale : integer;
      yscale : integer;
    procedure PlotPoint(index :integer);
      begin
        x:=index/60/RunTime;
        y:=UnitVal[Ch[i],index]/MF[Ch[i]]*Gain[Ch[i]]/10;
        xscale:=xleft+round(x*(xright-xleft));
        yscale:=ybottom-round(y*(ybottom-ytop));
        plot(xscale,yscale,1);
        plot(xscale-1,yscale,1);
        plot(xscale+1,yscale,1);
        plot(xscale,yscale-1,1);
        plot(xscale,yscale+1,1);
      end; { PlotPoint }
    begin
      if i in [1..n] then
        begin
          if not GraphFlag
            then
              begin
                hires;
                hirescolor(Color);
                gotoxy(30,1);
                write('Channel',i:2,' vs. Time');
                gotoxy(70,1);
                write(copy(TimeChar,1,8));
                gotoxy(5,2);
                write('1');
                for index:=1 to length(ylabel) do
                  begin
                    gotoxy(2,index+3);
                    write(copy(ylabel,index,1));
                  end; { for }
                gotoxy(5,24);
                write('0');
                gotoxy(78,24);
                write(RunTime:2);
                gotoxy(35,25);
                write('Time, hr');
                draw(xleft,ytop,xright,ytop,1);
                draw(xleft,ytop,xleft,ybottom,1);
                draw(xright,ytop,xright,ybottom,1);
                draw(xleft,ybottom,xright,ybottom,1);
                for index:=0 to j do PlotPoint(index);
              end { then }
            else
              begin
                gotoxy(70,1);
                write(copy(TimeChar,1,8));
                PlotPoint(j);
              end; { else }
        end; { if }
    end; { Graph }
{-----------------------------------------------------------------------------}
{                                                                             }
{     Menu:  Displays screen options in a menu format.                        }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure Menu;
    begin
      textmode;
      textcolor(Color);
      clrscr;
      gotoxy(10,5);
      writeln('MENU:     Time = ',copy(TimeChar,1,8));
      write('==================================================');
      gotoxy(10,8);
      write('1     Channel 1 Plot');
      gotoxy(10,9);
      write('2     Channel 2 Plot');
      gotoxy(10,10);
      write('3     Channel 3 Plot');
      gotoxy(10,11);
      write('4     Channel 4 Plot');
      gotoxy(10,12);
      write('5     Channel 5 Plot');
      gotoxy(10,13);
      write('6     Channel 6 Plot');
      gotoxy(10,14);
      write('7     Channel 7 Plot');
      gotoxy(10,15);
      write('B     Break Program');
      gotoxy(10,16);
      write('C     Clear Screen');
      gotoxy(10,17);
      write('M     Menu');
      gotoxy(10,18);
      writeln('V     Tabulated Values');
      writeln;
    end; { Menu }
{-----------------------------------------------------------------------------}
{                                                                             }
{     Values:  Displays current parameter values from analog input.           }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure Values;
    begin
      textmode;
      textcolor(Color);
      writeln;
      writeln('Parameter':12,'Reading @':22,copy(TimeChar,1,8),'Unit':14);
      writeln('============================================================');
      for i:=1 to n do
        writeln(P[Ch[i]]:20,UnitVal[Ch[i],j]:14:1,U[Ch[i]]:27);
      writeln;
      case OuterChoice of
        2  : writeln('Fringe count =':19,FringeNum:15:1);
        3,4: writeln('Control voltage = ':20,DesiredVolts:16:3);
      end; { case }
    end; { Values }
{-----------------------------------------------------------------------------}
{                                                                             }
{     ClearBoard:  Clears the data acquisition board registers.               }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure ClearBoard;
    begin
      port[ComReg]:=CStop;
      Junk:=port[DataReg];
      PWait(StatReg,ComWait,0);
      port[ComReg]:=CClear;
    end; { ClearBoard }
{-----------------------------------------------------------------------------}
{                                                                             }
{     TestBoard:  Tests the data acquisition board operating system.          }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure TestBoard;
    begin
      ErrCnt:=0;
      PWait(StatReg,ComWait,0);
      port[ComReg]:=CTest;
      for Loop:=1 to 255 do
        begin
          PWait(StatReg,ReadWait,0);
          DataVal:=port[DataReg];
          if DataVal <> Loop then
            begin
              ErrCnt:=ErrCnt+1;
              writeln('Actual test value is ',DataVal,', should be ',Loop);
            end; { if }
        end; { for }
      if ErrCnt=0
        then writeln('No sequence errors.')
        else writeln(ErrCnt,' errors.');
      port[ComReg]:=CStop;
      Junk:=port[DataReg];
      PWait(StatReg,ComWait,0);
      port[ComReg]:=CClear;
    end; { TestBoard }
{-----------------------------------------------------------------------------}
{                                                                             }
{     BoardError:  Determines the data acquisition board error, then resets   }
{                  the board for continued use.                               }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure BoardError;
    begin
      port[ComReg]:=CStop;
      Junk:=port[DataReg];
      PWait(StatReg,ComWait,0);
      port[ComReg]:=CErr;
      PWait(StatReg,ReadWait,0);
      Err1:=port[DataReg];
      PWait(StatReg,ReadWait,0);
      Err2:=port[DataReg];
      PWait(StatReg,ComWait,0);
      port[ComReg]:=CClear;
      for k:=7 downto 0 do
        begin
          if Err1-bit[k]>=0 then
            begin
              Err1:=Err1-bit[k];
              case k of
                0: writeln('Error  0: Reserved');
                1: writeln('Error  1: Command Overwrite');
                2: writeln('Error  2: Clock Set');
                3: writeln('Error  3: Digital Port Select');
                4: writeln('Error  4: Digital Port Set');
                5: writeln('Error  5: DAC Select');
                6: writeln('Error  6: DAC Clock');
                7: writeln('Error  7: DAC # Conversions');
              end; { case }
            end; { if }
        end; { for }
      for k:=7 downto 0 do
        begin
          if Err2-bit[k]>=0 then
            begin
              Err2:=Err2-bit[k];
              case k of
                0: writeln('Error  8: A/D Channel');
                1: writeln('Error  9: A/D Gain');
                2: writeln('Error 10: A/D Clock');
                3: writeln('Error 11: A/D Multiplexer');
                4: writeln('Error 12: A/D # Conversions');
                5: writeln('Error 13: Data where Command Expected');
                6: writeln('Error 14: Reserved');
                7: writeln('Error 15: Reserved');
              end; { case }
            end; { if }
        end; { for }
    end; { BoardError }
{-----------------------------------------------------------------------------}
{                                                                             }
{     AnalogIn:  Reads data from analog input.                                }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure AnalogIn;
    begin
      for i:=1 to n do UnitVal[Ch[i],j]:=0;
      for m:=1 to q do
        begin
          for i:=1 to n do
            begin
              PWait(StatReg,ComWait,0);
              port[ComReg]:=CAD;
              PWait(StatReg,WritWait,WritWait);
              port[DataReg]:=Code[Ch[i]];
              PWait(StatReg,WritWait,WritWait);
              port[DataReg]:=Ch[i];
              PWait(StatReg,ReadWait,0);
              LowByte:=port[DataReg];
              PWait(StatReg,ReadWait,0);
              HighByte:=port[DataReg];
              AnalogVal:=HighByte*256+LowByte;
              PWait(StatReg,ComWait,0);
              Status:=port[StatReg];
              if Status-bit[7]>=0 then BoardError;
              Voltage[Ch[i]]:=(1.*AnalogVal*Range/NOC+LowV)/Gain[Ch[i]];
              UnitVal[Ch[i],j]:=UnitVal[Ch[i],j]+Voltage[Ch[i]]*MF[Ch[i]]/q;
            end; { for }
        end; { for }
    end; { AnalogIn }
{-----------------------------------------------------------------------------}
{                                                                             }
{     AnalogOut:  Sends out analog voltages to control devices.               }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure AnalogOut;
    begin
      AnalogVal:=round(DesiredVolts*NOC/Range+NOC/2);
      PWait(StatReg,ComWait,0);
      port[ComReg]:=CDA;
      PWait(StatReg,WritWait,WritWait);
      port[DataReg]:=DACPort;
      HighByte:=AnalogVal div 256;
      LowByte:=AnalogVal mod 256;
      PWait(StatReg,WritWait,WritWait);
      port[DataReg]:=LowByte;
      PWait(StatReg,WritWait,WritWait);
      port[DataReg]:=HighByte;
      PWait(StatReg,ComWait,0);
      Status:=port[StatReg];
      if Status-bit[7]>=0 then BoardError;
    end; { AnalogOut }
(*
{-----------------------------------------------------------------------------}
{                                                                             }
{     Note:  These procedures are not used in this program, but have been     }
{            included for other potential applications involving digital      }
{            input/output.                                                    }
{                                                                             }
{-----------------------------------------------------------------------------}
{                                                                             }
{     SetInDigital:  Tells digital ports that they will receive digital       }
{                    input.                                                   }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure SetInDigital;
    begin
      PWait(StatReg,ComWait,0);
      port[ComReg]:=CSIn;
      PWait(StatReg,WritWait,WritWait);
      port[DataReg]:=PortIn;
      PWait(StatReg,ComWait,0);
      Status:=port[StatReg];
      if Status-bit[7]>=0 then BoardError;
    end; { SetInDigital }
{-----------------------------------------------------------------------------}
{                                                                             }
{     DigitalIn:  Reads digital input.                                        }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure DigitalIn;
    begin
      PWait(StatReg,ComWait,0);
      port[ComReg]:=CDIn;
      PWait(StatReg,WritWait,WritWait);
      port[DataReg]:=PortIn;
      PWait(StatReg,ReadWait,0);
      DataVal:=port[DataReg];
      PWait(StatReg,ComWait,0);
      Status:=port[StatReg];
      if Status-bit[7]>=0 then BoardError;
    end; { Digital In }
{-----------------------------------------------------------------------------}
{                                                                             }
{     SetOutDigital:  Tells digital ports that they will send digital output. }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure SetOutDigital;
    begin
      PWait(StatReg,ComWait,0);
      port[ComReg]:=CSOut;
      PWait(StatReg,WritWait,WritWait);
      port[DataReg]:=PortOut;
      PWait(StatReg,ComWait,0);
      Status:=port[StatReg];
      if Status-bit[7]>=0 then BoardError;
    end; { SetOutDigital }
{-----------------------------------------------------------------------------}
{                                                                             }
{     DigitalOut:  Sends out digital messages.                                }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure DigitalOut;
    begin
      PWait(StatReg,ComWait,0);
      port[ComReg]:=CDOut;
      PWait(StatReg,WritWait,WritWait);
      port[DataReg]:=PortOut;
      PWait(StatReg,WritWait,WritWait);
      port[DataReg]:=DigitalVal;
      PWait(StatReg,ComWait,0);
      Status:=port[StatReg];
      if Status-bit[7]>=0 then BoardError;
    end; { DigitalOut }
*)
{-----------------------------------------------------------------------------}
{                                                                             }
{     Control:  Contains a standard proportional(P) control algorithm with    }
{               directionality to control on both sides of laser peak.        }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure Control;
    begin
      OldE:=dR-UnitVal[Ch[2],j-1];
      NewE:=dR-UnitVal[Ch[2],j];
      dM:=Kc*NewE;
      if abs(NewE)>abs(OldE) then
        begin
          Direction:=-Direction;
          if dM<0 then dM:=-Kc*100 else dM:=Kc*100;
        end; { if }
      DesiredVolts:=DesiredVolts+Direction*dM;
      if DesiredVolts>=0   then DesiredVolts:=-6;
      if DesiredVolts<=-10 then DesiredVolts:=-3;
      dt:=TimeVal-LastTime;
      SqrIntegral:=SqrIntegral+NewE*NewE*dt;
      t:=t+dt;
      LastTime:=TimeVal;
    end; { Control }
{-----------------------------------------------------------------------------}
{                                                                             }
{     Maximize:  Attempts to maximize laser power.                            }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure Maximize;
    begin
      Control;
      if UnitVal[Ch[2],j]>dR then dR:=UnitVal[Ch[2],j];
    end; { Maximize }
{-----------------------------------------------------------------------------}
{                                                                             }
{     CountFringe:  Counts fringes based on interferometer signal.            }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure CountFringe;
    begin
      OldPoint:=UnitVal[Ch[6],j-1];
      NewPoint:=UnitVal[Ch[6],j];
      NewSign:=round(abs(NewPoint-OldPoint))=round(NewPoint-OldPoint);
      if FringeFlag then
        begin
          OldSign:=NewSign;
          FringeFlag:=false;
        end; { if }
      if NewSign<>OldSign then FringeNum:=FringeNum+0.5;
      OldSign:=NewSign;
    end; { CountFringe }
{-----------------------------------------------------------------------------}
{                                                                             }
{     Initialize:  Sets all variables to initial values.                      }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure Initialize;
    begin
      Color:=13;
      textmode;
      textcolor(Color);
      clrscr;
      StopFlag:=false;
      GraphFlag:=false;
      q:=50;
      Direction:=1;
      DACPort:=0;
      PortIn:=1;
      PortOut:=0;
      Range:=HighV-LowV;
      ComReg:=BaseAdd+1;
      StatReg:=BaseAdd+1;
      DataReg:=BaseAdd;
      bit[0]:=1;
      for i:=1 to 7 do bit[i]:=2*bit[i-1];
    end; { Initialize }
{-----------------------------------------------------------------------------}
{                                                                             }
{     SetUp:  Obtains the necessary information about channels, parameters,   }
{             gains, units, and multiplying factors to read analog input.     }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure SetUp;
    begin
      n:=0;
      write('What is the approximate run time(hr) ? ');
      readln(RunTime);
      write('What file contains the acquisition parameters? ');
      readln(ParamName);
      assign(Param,ParamName);
      reset(Param);
      while not eof(Param) do
        begin
          n:=n+1;
          Ch[n]:=n;
          readln(Param,P[n],Gain[n],U[n],MF[n]);
          case Gain[n] of
            1  : Code[n]:=0;
            10 : Code[n]:=1;
            100: Code[n]:=2;
            500: Code[n]:=3;
          end; { case }
        end; { while }
      write('Name the file that should store the data: ');
      readln(DataName);
      assign(Data,DataName);
      rewrite(Data);
    end; { SetUp }
{-----------------------------------------------------------------------------}
{                                                                             }
{     Keys:  Handles data acquisition key requests.                           }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure Keys;
    begin
      if KeyPressed then
        begin
          read(Kbd,InnerChoice);
          case InnerChoice of
            '1'    : Graph(1,j-1);
            '2'    : Graph(2,j-1);
            '3'    : Graph(3,j-1);
            '4'    : Graph(4,j-1);
            '5'    : Graph(5,j-1);
            '6'    : Graph(6,j-1);
            '7'    : Graph(7,j-1);
            'B','b': BreakFlag:=true;
            'C','c': begin
                       textmode;
                       textcolor(Color);
                       clrscr;
                     end;
            'M','m': Menu;
            'V','v': Values;
          end; { case }
        end; { if }
    end; { Keys }
{-----------------------------------------------------------------------------}
{                                                                             }
{     Update:  Keeps track of time and adds new data points to Graph          }
{              procedure.                                                     }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure Update;
    begin
      Clock;
      if TimeVal-OldTime >= 60 then
        begin
          if InnerChoice in ['1'..'7'] then
            begin
              GraphFlag:=true;
              Graph(ord(InnerChoice)-ord('0'),j);
              GraphFlag:=false;
            end; { if }
          j:=j+1;
          OldTime:=TimeVal;
        end; { if }
    end; { Update }
{-----------------------------------------------------------------------------}
{                                                                             }
{     Files:  Provides file maintenance for data storage.                     }
{                                                                             }
{-----------------------------------------------------------------------------}
  Procedure Files;
    begin
      textmode;
      textcolor(Color);
      for k:=0 to j do
        for i:=1 to n do
          writeln(Data,k:10,',',P[Ch[i]]:20,',',UnitVal[Ch[i],k]:14:1,',',U[Ch[i]]:17);
      close(Data);
      writeln('Current data was stored in ',DataName,'--Enter:');
      writeln('  P     to pick a new file name');
      writeln('  W     to write over this file');
      write('  S     if you want to stop...        ');
      readln(Answer);
      case Answer of
        'P','p': begin
                   write('Filename ? ');
                   readln(DataName);
                   assign(Data,DataName);
                   rewrite(Data);
                 end; { E,e }
        'W','w': begin
                   assign(Data,DataName);
                   rewrite(Data);
                 end; { W,w }
        'S','s': StopFlag:=true;
      end; { case }
    end; { Files }
{-----------------------------------------------------------------------------}
{                                                                             }
{     Main:  Allows the user to choose from                                   }
{              1) Data acquistion                                             }
{              2) Control loop tuning                                         }
{              3) Maximize laser power                                        }
{              4) Process control                                             }
{              5) Stop program                                                }
{            then implements that request.  After finishing one               }
{            subprogram, the user can continue with any of the five           }
{            original subprogram choices.                                     }
{                                                                             }
{-----------------------------------------------------------------------------}
  begin
    Initialize;
    ClearBoard;
    TestBoard;
    SetUp;
    while not StopFlag do
      begin
        writeln('Choose a run strategy:');
        writeln('  1     Data acquisition');
        writeln('  2     Control loop tuning');
        writeln('  3     Maximize laser power');
        writeln('  4     Process control');
        writeln('  5     Stop program');
        write('Enter option number > ');
        readln(OuterChoice);
        case OuterChoice of
          1: begin
               Clock;
               OldTime:=TimeVal;
               Menu;
               j:=0;
               AnalogIn;
               j:=j+1;
               BreakFlag:=false;
               while not BreakFlag do
                 begin
                   AnalogIn;
                   Keys;
                   Update;
                 end; { while }
               Files;
             end; { 1 }
          2: begin
               writeln('Specify loop tuning values: ');
               write('  set-point             = ');
               readln(dR);
               write('  proportional constant = ');
               readln(Kc);
               SqrIntegral:=0;
               t:=0;
               Clock;
               OldTime:=TimeVal;
               LastTime:=TimeVal;
               Menu;
               j:=0;
               AnalogIn;
               j:=j+1;
               DesiredVolts:=-10*Voltage[Ch[1]];
               BreakFlag:=false;
               while not BreakFlag do
                 begin
                   AnalogIn;
                   Control;
                   AnalogOut;
                   Keys;
                   Update;
                 end; { while }
               textmode;
               textcolor(Color);
               writeln('Control performance = ',SqrIntegral:10:1);
               writeln('Time increment      = ',dt:10:2);
               writeln('Total time          = ',t:10:1);
               Files;
             end; { 2 }
          3: begin
               write('What is the initial set-point? ');
               readln(dR);
               Kc:=0.001;
               SqrIntegral:=0;
               t:=0;
               Clock;
               OldTime:=TimeVal;
               LastTime:=TimeVal;
               Menu;
               j:=0;
               AnalogIn;
               j:=j+1;
               DesiredVolts:=-10*Voltage[Ch[1]];
               FringeFlag:=true;
               BreakFlag:=false;
               while not BreakFlag do
                 begin
                   AnalogIn;
                   Maximize;
                   AnalogOut;
                   Keys;
                   Update;
                 end; { while }
               Files;
             end; { 3 }
          4: begin
               write('What is the optimum set-point? ');
               readln(dR);
               write('How many fringes? ');
               readln(FringeNum);
               Kc:=0.001;
               SqrIntegral:=0;
               t:=0;
               Clock;
               OldTime:=TimeVal;
               LastTime:=TimeVal;
               Menu;
               j:=0;
               AnalogIn;
               j:=j+1;
               DesiredVolts:=-10*Voltage[Ch[1]];
               FringeFlag:=true;
               BreakFlag:=false;
               while not BreakFlag do
                 begin
                   AnalogIn;
                   Control;
                   AnalogOut;
                   CountFringe;
                   Keys;
                   Update;
                 end; { while }
               Files;
             end; { 4 }
          5: StopFlag:=true;
        end; { case }
      end; { while }
  end. { Ultra }

