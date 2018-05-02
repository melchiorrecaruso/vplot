{
  Description: vPlot driver library.

  Copyright (C) 2017-2018 Melchiorre Caruso <melchiorrecaruso@gmail.com>

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}

unit vpdriver;

{$mode objfpc}

interface

uses
  classes, {$ifdef cpuarm} pca9685, wiringpi, {$endif} sysutils, vpcommon;

type
  tvpdriver = class
  private
    fcnt0:    longint;
    fcnt1:    longint;
    fdelay1:  longint;
    fdelay2:  longint;
    fdelay3:  longint;
    fenabled: boolean;
    fmode:    longint;
    fpen:     boolean;
    fpenoff:  boolean;
    procedure setmode(value: longint);
    procedure setpen(value: boolean);
    procedure setpenoff(value: boolean);
    procedure largedisplacements(cnt0, cnt1: longint);
    procedure smalldisplacements(cnt0, cnt1: longint);
  public
    constructor create;
    destructor  destroy; override;
    procedure   init (cnt0, cnt1: longint);
    procedure   move2(cnt0, cnt1: longint);
    procedure   move4(cnt0, cnt1: longint);
  published
    property cnt0:    longint read fcnt0;
    property cnt1:    longint read fcnt1;
    property delay1:  longint read fdelay1  write fdelay1;
    property delay2:  longint read fdelay2  write fdelay2;
    property delay3:  longint read fdelay3  write fdelay3;
    property enabled: boolean read fenabled write fenabled;
    property mode:    longint read fmode    write setmode;
    property pen:     boolean read fpen     write setpen;
    property penoff:  boolean read fpenoff  write setpenoff;
  end;


implementation


{$ifdef cpuarm}
const
  mot0_step     = P38;
  mot0_dir      = P40;
  mot1_step     = P29;
  mot1_dir      = P31;

  motx_mod0     = P15;
  motx_mod1     = P13;
  motx_mod2     = P11;

  motz_up       = 1.80;
  motz_low      = 2.50;
  motz_freq     = 50;

  vplotmatrix : array [0..10, 0..18] of longint = (
    (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),  //  0
    (0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0),  //  1
    (0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0),  //  2
    (0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0),  //  3
    (1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1),  //  4
    (1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1),  //  5
    (0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0),  //  6
    (1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1),  //  7
    (1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1),  //  8
    (0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0),  //  9
    (1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1)); // 10
{$endif}

constructor tvpdriver.create;
begin
  inherited create;
  fenabled := false;
  fmode    := 1;
  fpen     := false;
  fpenoff  := false;
  {$ifdef cpuarm}
  // setup wiringpi library
  wiringpisetup;
  // setup pca9685 library
  pca9685setup(PCA9685_PIN_BASE, PCA9685_ADDRESS, motz_freq);
  // init servo
  pwmwrite(PCA9685_PIN_BASE + 0, calcticks(motz_up, motz_freq));
  delaymicroseconds(fdelay3);
  // init mode = 1
  pinmode(motx_mod0, OUTPUT);
  pinmode(motx_mod1, OUTPUT);
  pinmode(motx_mod2, OUTPUT);
  digitalwrite(motx_mod0,  LOW);
  digitalwrite(motx_mod1,  LOW);
  digitalwrite(motx_mod2,  LOW);
  // init step motor0
  pinmode(mot0_dir,    OUTPUT);
  pinmode(mot0_step,   OUTPUT);
  digitalwrite(mot0_dir,  LOW);
  digitalwrite(mot0_step, LOW);
  // init step motor1
  pinmode(mot1_dir,    OUTPUT);
  pinmode(mot1_step,   OUTPUT);
  digitalwrite(mot1_dir,  LOW);
  digitalwrite(mot1_step, LOW);
  {$endif}
end;

destructor tvpdriver.destroy;
begin
  inherited destroy;
end;

procedure  tvpdriver.init(cnt0, cnt1: longint);
begin
  fcnt0 := cnt0;
  fcnt1 := cnt1;
end;

procedure tvpdriver.largedisplacements(cnt0, cnt1: longint);
begin
  setpen(false);
  inc(fcnt0, cnt0);
  inc(fcnt1, cnt1);
  {$ifdef cpuarm}
  if cnt0 > 0 then
    digitalwrite(mot0_dir, HIGH)
  else
    digitalwrite(mot0_dir,  LOW);

  if cnt1 > 0 then
    digitalwrite(mot1_dir,  LOW)
  else
    digitalwrite(mot1_dir, HIGH);

  // move step motor0 and motor1
  cnt0 := abs(cnt0);
  cnt1 := abs(cnt1);
  repeat
    if cnt0 > 0 then
    begin
      digitalwrite(mot0_step, HIGH); delaymicroseconds(fdelay1);
      digitalwrite(mot0_step,  LOW); delaymicroseconds(fdelay1);
      dec(cnt0);
    end;

    if cnt1 > 0 then
    begin
      digitalwrite(mot1_step, HIGH); delaymicroseconds(fdelay1);
      digitalwrite(mot1_step,  LOW); delaymicroseconds(fdelay1);
      dec(cnt1);
    end;

  until ((cnt0 = 0) and (cnt1 = 0)) or (not fenabled);
  {$endif}
end;

procedure tvpdriver.smalldisplacements(cnt0, cnt1: longint);
{$ifdef cpuarm}
var
  i: longint;
{$endif}
begin
  setpen(true);
  inc(fcnt0, cnt0);
  inc(fcnt1, cnt1);
  {$ifdef cpuarm}
  if cnt0 > 0 then
    digitalwrite(mot0_dir, HIGH)
  else
    digitalwrite(mot0_dir,  LOW);

  if cnt1 > 0 then
    digitalwrite(mot1_dir,  LOW)
  else
    digitalwrite(mot1_dir, HIGH);

  // move step motor0 and motor1
  cnt0 := abs(cnt0);
  cnt1 := abs(cnt1);
  for i := 0 to 18 do
  begin
    if vplotmatrix[cnt0, i] = 1 then
    begin
      digitalwrite(mot0_step, HIGH); delaymicroseconds(fdelay2);
      digitalwrite(mot0_step,  LOW); delaymicroseconds(fdelay2);
    end;

    if vplotmatrix[cnt1, i] = 1 then
    begin
      digitalwrite(mot1_step, HIGH); delaymicroseconds(fdelay2);
      digitalwrite(mot1_step,  LOW); delaymicroseconds(fdelay2);
    end;
  end;
  {$endif}
end;

procedure tvpdriver.setpen(value: boolean);
begin
  if not fpenoff then
    if fpen <> value then
    begin
      fpen := value;
      {$ifdef cpuarm}
      if fpen then
        pwmwrite(PCA9685_PIN_BASE + 0, calcticks(motz_low, motz_freq))
      else
        pwmwrite(PCA9685_PIN_BASE + 0, calcticks(motz_up,  motz_freq));
      delaymicroseconds(fdelay3);
      {$endif}
    end;
end;

procedure tvpdriver.setpenoff(value: boolean);
begin
  fpenoff := value;
  if fpenoff then
    if fpen then
    begin
      fpen := false;
      {$ifdef cpuarm}
      pwmwrite(PCA9685_PIN_BASE + 0, calcticks(motz_up, motz_freq));
      delaymicroseconds(fdelay3);
      {$endif}
    end;
end;

procedure tvpdriver.setmode(value: longint);
begin
  if value <> fmode then
  begin
    {$ifdef cpuarm}
    if mode = 1 then
    begin
      digitalwrite(motx_mod0,  LOW);
      digitalwrite(motx_mod1,  LOW);
      digitalwrite(motx_mod2,  LOW);
      fmode := value;
    end else
    if mode = 2 then
    begin
      digitalwrite(motx_mod0, HIGH);
      digitalwrite(motx_mod1,  LOW);
      digitalwrite(motx_mod2,  LOW);
      fmode := value;
    end else
    if fmode = 4 then
    begin
      digitalwrite(motx_mod0,  LOW);
      digitalwrite(motx_mod1, HIGH);
      digitalwrite(motx_mod2,  LOW);
      fmode := value;
    end;
    {$endif}
  end;
end;

procedure tvpdriver.move2(cnt0, cnt1: longint);
begin
  move4(cnt0 - fcnt0, cnt1 - fcnt1);
end;

procedure tvpdriver.move4(cnt0, cnt1: longint);
begin
  if fenabled then
    if (cnt0 <> 0) or
       (cnt1 <> 0) then
    begin
      if (not fpenoff) then
      begin
        if (abs(cnt0) < 11) and
           (abs(cnt1) < 11) then
          smalldisplacements(cnt0, cnt1)
        else
          largedisplacements(cnt0, cnt1);

      end else
        largedisplacements(cnt0, cnt1);
    end;

  if enabledebug then
  begin
    writeln(format('  DRIVER::CNT.0  = %12.5u', [fcnt0]));
    writeln(format('  DRIVER::CNT.1  = %12.5u', [fcnt1]));
  end;
end;

end.

