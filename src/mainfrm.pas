
{ Description: vPlot Main Form.

  Copyright (C) 2014-2018 Melchiorre Caruso <melchiorrecaruso@gmail.com>

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

unit mainfrm;

{$mode objfpc}{$H+}

interface

uses
  classes, forms, controls, graphics, dialogs, extctrls, stdctrls,
  comctrls, buttons, menus, spin, inifiles, libvplot;

type
  { tmainform }

  tmainform = class(tform)
    aboutbtn: TBitBtn;
    aboutgb: TGroupBox;
    leftedit: TSpinEdit;
    rightedit: TSpinEdit;
    verticalcb: TCheckBox;
    redrawbtn: TBitBtn;
    formatcb: TComboBox;
    papersizegb: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    heightl: TLabel;
    widthl: TLabel;
    formatl: TLabel;
    loadbtn: TBitBtn;
    offsetyse: TSpinEdit;
    offsetxse: TSpinEdit;
    heightse: TSpinEdit;
    widthse: TSpinEdit;
    startbtn: TBitBtn;
    stopbtn: TBitBtn;
    creativecontrolgb: TGroupBox;
    sethomebtn: TBitBtn;
    bordersbtn: TBitBtn;
    leftdownbtn: TBitBtn;
    rightdownbtn: TBitBtn;
    penupbtn: TBitBtn;
    pendownbtn: TBitBtn;
    leftupbtn: TBitBtn;
    rightupbtn: TBitBtn;
    gohomebtn: TBitBtn;
    manualdrivinggb: TGroupBox;
    drawingcontrolgb: TGroupBox;
    previewimage: TImage;
    opendialog: topendialog;

    procedure bordersbtnclick(sender: tobject);

    procedure formatcbchange(sender: tobject);
    procedure formcreate(sender: tobject);
    procedure formdestroy(sender: tobject);
    procedure formclose(sender: tobject; var closeaction: tcloseaction);
    procedure gohomebtnclick(sender: tobject);
    procedure leftdownbtnclick(sender: tobject);

    procedure leftupbtnclick(sender: tobject);
    procedure pendownbtnclick(sender: tobject);
    procedure penupbtnclick(sender: tobject);
    procedure reloadbtnclick(sender: tobject);
    procedure rightdownbtnclick(sender: tobject);
    procedure rightupbtnclick(sender: tobject);
    procedure sethomebtnclick(sender: tobject);

    procedure loadbtnclick(sender: tobject);
    procedure playorstopbtnclick(sender: tobject);

    procedure verticalcbeditingdone(sender: tobject);
  private
    ini:   tinifile;
    image: tbitmap;
    list:  tstringlist;
    procedure onstart;
    procedure onstop;
    procedure ontick;
  end;


var
  mainform: Tmainform;


implementation

{$R *.lfm}

uses
  math, sysutils;

// form events //

procedure tmainform.formcreate(sender: tobject);
begin
  manualdrivinggb  .enabled := true;
  creativecontrolgb.enabled := true;
  papersizegb      .enabled := false;
  drawingcontrolgb .enabled := false;
  // ---

  image := tbitmap.create;
  list  := tstringlist.create;
  ini   := tinifile.create(changefileext(paramstr(0), '.ini'));

  loadlayout(ini, vplayout);
  vpdriver := tvpdriver.create(vplayout.m);

  sethomebtnclick(nil);
  reloadbtnclick (nil);
end;

procedure tmainform.formdestroy(sender: tobject);
begin
  vpdriver.destroy;

  ini.destroy;
  list.destroy;

  image.destroy;
end;

procedure tmainform.formclose(sender: tobject; var closeaction: tcloseaction);
begin
  if assigned(vpcoder) then
  begin
    playorstopbtnclick(stopbtn);
    closeaction := canone;
  end else
  begin
    gohomebtnclick(sender);
    closeaction := cafree;
  end;
end;

//

procedure tmainform.formatcbchange(sender: tobject);
begin
  verticalcb.enabled := true;
  heightse  .enabled := false;
  widthse   .enabled := false;
  case formatcb.itemindex of
    0: begin heightse.value := 841; widthse .value := 1189; end;
    1: begin heightse.value := 594; widthse .value :=  841; end;
    2: begin heightse.value := 420; widthse .value :=  594; end;
    3: begin heightse.value := 297; widthse .value :=  420; end;
    4: begin heightse.value := 210; widthse .value :=  297; end;
    5: begin heightse.value := 148; widthse .value :=  210; end;
  else begin
         verticalcb.enabled := false;
         heightse  .enabled := true;
         widthse   .enabled := true;
       end;
  end;
  verticalcbeditingdone(formatcb);
end;


// manual driving //

procedure tmainform.leftupbtnclick(Sender: TObject);
begin
  vpdriver.enabled := true;
  vpdriver.move4(-leftedit.value, 0, 0);
end;

procedure tmainform.leftdownbtnclick(sender: tobject);
begin
  vpdriver.enabled := true;
  vpdriver.move4(+leftedit.value, 0, 0);
end;

procedure tmainform.pendownbtnclick(Sender: TObject);
begin
  vpdriver.enabled := true;
  vpdriver.move4(0, 0, -1);
end;

procedure tmainform.penupbtnclick(sender: tobject);
begin
  vpdriver.enabled := true;
  vpdriver.move4(0, 0, +1);
end;

procedure tmainform.rightupbtnclick(sender: tobject);
begin
  vpdriver.enabled := true;
  vpdriver.move4(0, -rightedit.value, 0);
end;

procedure tmainform.rightdownbtnclick(sender: tobject);
begin
  vpdriver.enabled := true;
  vpdriver.move4(0, +rightedit.value, 0);
end;

procedure tmainform.sethomebtnclick(sender: tobject);
var
  m0: longint;
  m1: longint;
begin
  optimize(vplayout.p09, vplayout, m0, m1);
  vpdriver.init(m0, m1, 1);
end;

procedure tmainform.bordersbtnclick(sender: tobject);
begin
  list.clear;
  with vplayout do
  begin
    list.add('begin');
    list.add(format('G00 X%5.4f Y%5.4f Z%5.4f ', [p09.x, p09.y, 0.0]));
    list.add(format('G00 X%5.4f Y%5.4f Z%5.4f ', [p10.x, p10.y, 0.0]));
    list.add(format('G01 X%5.4f Y%5.4f Z%5.4f ', [p11.x, p11.y,-1.0]));
    list.add(format('G01 X%5.4f Y%5.4f Z%5.4f ', [p12.x, p12.y,-1.0]));
    list.add(format('G01 X%5.4f Y%5.4f Z%5.4f ', [p13.x, p13.y,-1.0]));
    list.add(format('G01 X%5.4f Y%5.4f Z%5.4f ', [p10.x, p10.y,-1.0]));
    list.add(format('G00 X%5.4f Y%5.4f Z%5.4f ', [p09.x, p09.y, 0.0]));
    list.add('end');
  end;
  reloadbtnclick(loadbtn);
end;

procedure tmainform.gohomebtnclick(sender: tobject);
var
  m0: longint;
  m1: longint;
begin
  vpdriver.enabled := true;
  optimize(vplayout.p09, vplayout, m0, m1);
  vpdriver.move2(m0, m1, 1);
end;

// ---

procedure tmainform.loadbtnclick(sender: tobject);
begin
  if opendialog.execute then
  begin
    list.clear;
    list.loadfromfile(opendialog.filename);
    reloadbtnclick(sender);
  end;
end;

procedure tmainform.reloadbtnclick(sender: tobject);
begin
  verticalcbeditingdone(sender);
  // ---
  image.canvas.pen.color   := clltgray;
  image.canvas.brush.color := clltgray;
  image.canvas.brush.style := bssolid;
  image.setsize(
     widthse.value,
    heightse.value);
  image.canvas.fillrect(0,0,
     widthse.value,
    heightse.value);
  // ---
  previewimage.canvas.pen.color   := clltgray;
  previewimage.canvas.brush.color := clltgray;
  previewimage.canvas.brush.style := bssolid;
  previewimage.picture.bitmap.setsize(
     widthse.value,
    heightse.value);
  previewimage.canvas.fillrect(0, 0,
     widthse.value,
    heightse.value);

  previewimage.center            := true;
  previewimage.proportional      := true;
  previewimage.stretchinenabled  := true;
  previewimage.stretchoutenabled := false;
  previewimage.stretch           := true;
  // ---
  vpdriver.enabled := sender = startbtn;
  if vpdriver.enabled then
    gohomebtnclick(sender);

  if sender <> nil then
  begin
    vpcoder         := tvpcoder.create(list);
    vpcoder.onstart := @onstart;
    vpcoder.onstop  := @onstop;
    vpcoder.ontick  := @ontick;
    vpcoder.enabled := true;
    vpcoder.start;
  end;
end;

procedure tmainform.playorstopbtnclick(sender: tobject);
begin
  if assigned(vpcoder) then
  begin

    if sender = stopbtn then
    begin
      vpcoder.terminate;
      vpcoder.enabled := true;
    end else
    if sender = startbtn then
    begin
      vpcoder.enabled := not vpcoder.enabled;
      if vpcoder.enabled then
        startbtn.caption := 'Pause'
      else
        startbtn.caption := 'Play';
    end;

  end else
  begin

    if sender = startbtn then
    begin
      reloadbtnclick(startbtn);

    end;

  end;
end;


procedure tmainform.onstart;
begin
  startbtn.caption          := 'Pause';
  manualdrivinggb  .enabled := false;
  creativecontrolgb.enabled := false;
  papersizegb      .enabled := false;
  drawingcontrolgb .enabled := true;
  application.processmessages;
end;

procedure tmainform.onstop;
begin
  caption := 'VPlot Driver';
  previewimage.canvas.draw(0,0, image);

  startbtn.caption          := 'Play';
  manualdrivinggb  .enabled := true;
  creativecontrolgb.enabled := true;
  papersizegb      .enabled := true;
  drawingcontrolgb .enabled := true;
  application.processmessages;
end;

procedure tmainform.ontick;
var
   p: tvppoint;
  m0: longint;
  m1: longint;
begin
  p.x := ( widthse.value div 2) + offsetxse.value + (vpcoder.px);
  p.y := (heightse.value div 2) - offsetyse.value - (vpcoder.py);
  if vpcoder.pz < 0 then
    image.canvas.pixels[round(p.x), round(p.y)] := clblack
  else
    image.canvas.pixels[round(p.x), round(p.y)] := clred;

  if vpdriver.enabled then
  begin
    p.x := vplayout.p08.x + offsetxse.value + (vpcoder.px);
    p.y := vplayout.p08.y + offsetyse.value + (vpcoder.py);
    optimize(p, vplayout, m0, m1);

    vpdriver.move2(m0, m1, round(vpcoder.pz));
  end;

  if vpcoder.index mod 20 = 0 then
    caption := format('VPlot Driver - Drawing [%u / %u]',
      [vpcoder.index, vpcoder.count]);
  application.processmessages;
end;

procedure tmainform.verticalcbeditingdone(sender: tobject);
var
  amin, amax: longint;
begin
  amin := min(heightse.value, widthse.value);
  amax := max(heightse.value, widthse.value);
  if verticalcb.checked then
  begin
    heightse.value := amax;
    widthse .value := amin;
  end else
  begin
    heightse.value := amin;
    widthse .value := amax;
  end;
end;

end.

