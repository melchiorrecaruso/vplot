{
  Description: vPlot main form.

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

unit mainfrm;

{$mode objfpc}

interface

uses
  classes, forms, controls, graphics, dialogs, extctrls, stdctrls, comctrls,
  buttons, menus, spin, vpcommon, vpcoder, vpsetting, vpdriver, fpvectorial;

type
  { tmainform }

  tmainform = class(tform)
    aboutbtn: tbitbtn;
    layoutbtn: tbitbtn;
    progressbar: TProgressBar;
    rightedit: tspinedit;
    startbtn: tbitbtn;
    stopbtn: tbitbtn;
    killbtn: tbitbtn;
    controlgb: tgroupbox;
    loadbtn: tbitbtn;
    clearbtn: tbitbtn;
    reloadbtn: tbitbtn;
    leftdownbtn: tbitbtn;
    formatcb: tcombobox;
    formatl: tlabel;
    gohomebtn: tbitbtn;
    loadgb: tgroupbox;
    heightl: tlabel;
    heightse: tspinedit;
    image: timage;
    label1: tlabel;
    label2: tlabel;
    rightdownbtn: tbitbtn;
    imagepanel: tpanel;
    manualdrivinggb: tgroupbox;
    leftedit: tspinedit;
    offsetxse: tspinedit;
    offsetyse: tspinedit;
    pagesizegb: tgroupbox;
    pendownbtn: tbitbtn;
    penupbtn: tbitbtn;
    rightupbtn: tbitbtn;
    opendialog: topendialog;
    leftupbtn: tbitbtn;
    verticalcb: tcheckbox;
    widthl: tlabel;
    widthse: tspinedit;

    procedure formcreate(sender: tobject);
    procedure formdestroy(sender: tobject);
    procedure formclose(sender: tobject; var closeaction: tcloseaction);
    procedure formatcbchange(sender: tobject);

    procedure leftupbtnclick(sender: tobject);
    procedure leftdownbtnclick(sender: tobject);
    procedure rightupbtnclick(sender: tobject);
    procedure rightdownbtnclick(sender: tobject);
    procedure penupbtnclick(sender: tobject);
    procedure pendownbtnclick(sender: tobject);
    procedure gohomebtnclick(sender: tobject);

    procedure heightseeditingdone(sender: tobject);
    procedure widthseeditingdone(sender: tobject);
    procedure verticalcbeditingdone(sender: tobject);

    procedure openbtnclick(sender: tobject);
    procedure reloadmiclick(sender: tobject);
    procedure clearmiclick(sender: tobject);

    procedure startmiclick(sender: tobject);
    procedure stopmiclick(sender: tobject);
    procedure killmiclick(sender: tobject);

    procedure layoutmiclick(sender: tobject);
    procedure aboutmiclick(sender: tobject);

    procedure imagemouseup  (sender: tobject; button: tmousebutton; shift: tshiftstate; x, y: integer);
    procedure imagemousedown(sender: tobject; button: tmousebutton; shift: tshiftstate; x, y: integer);
    procedure imagemousemove(sender: tobject; shift: tshiftstate; x, y: integer);

  private
      bitmap: tbitmap;
       paths: tvppaths;
 mouseisdown: boolean;
          px: longint;
          py: longint;

    procedure onloadstart;
    procedure onloadend;
    // ---
    procedure onplotterstart;
    procedure onplotterstop;
    procedure onplottertick;
    // ---
    procedure lock1(value: boolean);
    procedure lock2(value: boolean);
  end;

  tloader = class(tthread)
  private
    fonloadstart: tthreadmethod;
    fonloadend:   tthreadmethod;
  protected
    procedure execute; override;
  public
    constructor create;
    destructor destroy; override;
  end;

var
  mainform: tmainform;
  loader:   tloader;

implementation

{$R *.lfm}

uses
  math, sysutils, dxfvectorialreader, aboutfrm, vpmath, vpwave;

// LOADER THREAD

constructor tloader.create;
begin
  freeonterminate := true;
  inherited create(true);
end;

destructor tloader.destroy;
begin
  inherited destroy;
end;

procedure tloader.execute;
begin
  synchronize(fonloadstart);
  synchronize(fonloadend);
end;

// FORM EVENTS

procedure tmainform.formcreate(sender: tobject);
var
  m0: longint = 0;
  m1: longint = 0;
begin
  progressbar.visible := false;
  // load setting
  setting := tvpsetting.create;
  setting.load(changefileext(paramstr(0), '.ini'));
  // create plotter driver
  driver        := tvpdriver.create;
  driver.mode   := setting.mode;
  driver.delaym := setting.delaym;
  driver.delayz := setting.delayz;
  driver.countz := setting.srvup;
  // create preview and empty paths
  bitmap := tbitmap.create;
   paths := tvppaths.create;
  // update preview
  formatcbchange (nil);
  // show toolbars
  manualdrivinggb.enabled := true;
  pagesizegb     .enabled := true;
  // init wave
  wave := twave.create(setting.wavemaxdx,
                       setting.wavemaxdy,
                       setting.wave);
  wave.enabled := false;
  wave.test;
  // initialize driver
  optimize(setting.layout09, m0, m1);
  driver.init(m0, m1);
end;

procedure tmainform.formdestroy(sender: tobject);
begin
  gohomebtnclick(nil);
  wave.destroy;
  paths.destroy;
  bitmap.destroy;
  driver.destroy;
  setting.destroy;
end;

procedure tmainform.formclose(sender: tobject; var closeaction: tcloseaction);
begin
  if assigned(driverthread) then
  begin
    messagedlg('vPlotter Error', 'There is an active process!', mterror, [mbok], 0);
    closeaction := canone;
  end else
    closeaction := cafree;
end;

// CALIBRATION EVENTS

procedure tmainform.rightdownbtnclick(sender: tobject);
begin
  leftupbtnclick(rightdownbtn);
end;

procedure tmainform.leftdownbtnclick(sender: tobject);
begin
  leftupbtnclick(leftdownbtn);
end;

procedure tmainform.rightupbtnclick(sender: tobject);
begin
  leftupbtnclick(rightupbtn);
end;

procedure tmainform.leftupbtnclick(sender: tobject);
var
  m0: longint = 0;
  m1: longint = 0;
begin
  lock2(false);
  driver.enabled := true;
  driver.zoff    := false;
  driver.countz  := setting.srvup;
  driver.zoff    := true;

  if sender = leftupbtn    then driver.count0 := driver.count0 - leftedit .value;
  if sender = leftdownbtn  then driver.count0 := driver.count0 + leftedit .value;
  if sender = rightupbtn   then driver.count1 := driver.count1 - rightedit.value;
  if sender = rightdownbtn then driver.count1 := driver.count1 + rightedit.value;

  optimize(setting.layout09, m0, m1);
  driver.init(m0, m1);
  lock2(true);
end;

procedure tmainform.pendownbtnclick(Sender: TObject);
begin
  lock2(false);
  driver.enabled := true;
  driver.zoff    := false;
  driver.countz  := setting.srvdown;
  lock2(true);
end;

procedure tmainform.penupbtnclick(sender: tobject);
begin
  lock2(false);
  driver.enabled := true;
  driver.zoff    := false;
  driver.countz  := setting.srvup;
  lock2(true);
end;

procedure tmainform.gohomebtnclick(sender: tobject);
var
  m0: longint = 0;
  m1: longint = 0;
begin
  lock2(false);
  driver.enabled := true;
  driver.zoff    := false;
  driver.countz  := setting.srvup;
  driver.zoff    := true;

  optimize(setting.layout09, m0, m1);
  driver.move(m0, m1);
  lock2(true);
end;

// PREVIEW EVENTS

procedure tmainform.imagemousedown(sender: tobject;
  button: tmousebutton; shift: tshiftstate; x, y: integer);
begin
  if button = mbleft then
  begin
    mouseisdown := true;
    px := x;
    py := y;
  end;
end;

procedure tmainform.imagemousemove(sender: tobject;
  shift: tshiftstate; x, y: integer);
var
  nleft: longint;
  ntop:  longint;
begin
  if mouseisdown then
  begin
    nleft := image.left + (x - px);
    ntop  := image.top  + (y - py);

    if nleft                >  width - 150 then nleft :=  width - 150;
    if ntop                 > height - 150 then ntop  := height - 150;
    if nleft + image. width <          150 then nleft :=          150 - image.width;
    if ntop  + image.height <          150 then ntop  :=          150 - image.height;

    image.left := nleft;
    image.top  := ntop;
  end;
end;

procedure tmainform.imagemouseup(sender: tobject;
  button: tmousebutton; shift: tshiftstate; x, y: integer);
begin
  mouseisdown := false;
end;

// LOAD EVENTS

procedure tmainform.openbtnclick(sender: tobject);
var
  vec: tvvectorialdocument;
begin
  opendialog.filter := 'dxf files (*.dxf)|*.dxf';
  if opendialog.execute then
  begin
    lock2(false);
    paths.clear;
    caption := 'vPlotter - ' + opendialog.filename;
    // ---
    vec := tvvectorialdocument.create;
    try
      vec.readfromfile(opendialog.filename,
        vec.getformatfromextension(opendialog.filename));
      vec2paths(vec, paths);
    except
    end;
    freeandnil(vec);
    // ---
    lock2(true);
    reloadmiclick(nil);
  end;
end;

procedure tmainform.reloadmiclick(sender: tobject);
begin
  loader              := tloader.create;
  loader.fonloadstart := @onloadstart;
  loader.fonloadend   := @onloadend;
  loader.start;
end;

procedure tmainform.clearmiclick(sender: tobject);
begin
  lock2(false);
  // ---
  bitmap.canvas.pen  .color := clltgray;
  bitmap.canvas.brush.color := clltgray;
  bitmap.canvas.brush.style := bssolid;
  bitmap.setsize(
     widthse.value + 2,
    heightse.value + 2);
  bitmap.canvas.fillrect(0, 0,
     widthse.value + 2,
    heightse.value + 2);
  // ---
  image.canvas.pen  .color := clltgray;
  image.canvas.brush.color := clltgray;
  image.canvas.brush.style := bssolid;
  image.picture.bitmap.setsize(
     widthse.value + 2,
    heightse.value + 2);
  image.canvas.fillrect(0, 0,
     widthse.value + 2,
    heightse.value + 2);
  // ---
  image.align             := alnone;
  image.anchors           := [aktop, akleft, akright, akbottom];
  image.anchors           := [];
  image.center            := true;
  image.proportional      := false;
  image.stretchinenabled  := false;
  image.stretchoutenabled := false;
  image.stretch           := false;
  // ---
  lock2(true);
end;

// PLOT EVENTS

procedure tmainform.startmiclick(sender: tobject);
begin
  driver.enabled := true;
  driver.zoff    := false;
  if assigned(driverthread) then
  begin
    driverthread.enabled := true;
  end else
  begin
    driverthread         := tvpdriverthread.create(paths);
    driverthread.midx    := setting.layout08.x;
    driverthread.midy    := setting.layout08.y+heightse.value/2;
    driverthread.maxdx   := widthse.value/2;
    driverthread.maxdy   := heightse.value/2;
    driverthread.offsetx := offsetxse.value;
    driverthread.offsety := offsetyse.value;
    driverthread.onstart := @onplotterstart;
    driverthread.onstop  := @onplotterstop;
    driverthread.ontick  := @onplottertick;
    driverthread.start;
  end;
end;

procedure tmainform.stopmiclick(sender: tobject);
begin
  if assigned(driverthread) then
  begin
    driverthread.enabled := false;
  end;
  driver.enabled := true;
  driver.zoff    := false;
  driver.countz  := setting.srvup;
end;

procedure tmainform.killmiclick(sender: tobject);
begin
  if assigned(driverthread) then
  begin
    driverthread.enabled := true;
    driverthread.terminate;
  end;
end;

// SETTING EVENTS

procedure tmainform.layoutmiclick(Sender: TObject);
var
  m0: longint = 0;
  m1: longint = 0;
begin
  gohomebtnclick(nil);
  // load configuration
  setting.clear;
  setting.load(changefileext(paramstr(0), '.ini'));
  // update plotter driver
  driver.mode   := setting.mode;
  driver.delaym := setting.delaym;
  driver.delayz := setting.delayz;

  optimize(setting.layout09, m0, m1);
  driver.init(m0, m1);
end;

// INFO EVENTS

procedure tmainform.aboutmiclick(sender: tobject);
var
  about: taboutform;
begin
  about := taboutform.create(nil);
  about.showmodal;
  about.destroy;
end;

// PAGE SIZE EVENTS

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

procedure tmainform.heightseeditingdone(sender: tobject);
begin
  formatcbchange(nil);
end;

procedure tmainform.widthseeditingdone(sender: tobject);
begin
  formatcbchange(nil);
end;

procedure tmainform.verticalcbeditingdone(sender: tobject);
var
  amin: longint;
  amax: longint;
begin
  if verticalcb.enabled then
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
  (*
  if (heightse.value > (2*setting.waveymax)) or
     (widthse .value > (2*setting.wavexmax)) then
  begin
    messagedlg('vPlotter Error', 'Selected page size is bigger than work area !', mterror, [mbok], 0);

    formatcb.itemindex := formatcb.items.count - 2;
    formatcbchange (nil);
  end;
  *)
  clearmiclick(verticalcb);
  reloadmiclick(verticalcb);
end;

// LOCK/UNLOCK EVENTS

procedure tmainform.lock1(value: boolean);
begin
  // main menu
  loadbtn      .enabled := value;
  reloadbtn    .enabled := value;
  clearbtn     .enabled := value;
  startbtn     .enabled := true;
  stopbtn      .enabled := true;
  killbtn      .enabled := true;
  layoutbtn    .enabled := value;
  aboutbtn     .enabled := value;
  // calibration
  leftupbtn    .enabled := value;
  leftdownbtn  .enabled := value;
  leftedit     .enabled := value;
  rightupbtn   .enabled := value;
  rightdownbtn .enabled := value;
  rightedit    .enabled := value;
  penupbtn     .enabled := value;
  pendownbtn   .enabled := value;
  gohomebtn    .enabled := value;
  // page format
  formatcb     .enabled := value;
  heightse     .enabled := value;
  widthse      .enabled := value;
  offsetxse    .enabled := value;
  offsetyse    .enabled := value;
  verticalcb   .enabled := value;
  application  .processmessages;
end;

procedure tmainform.lock2(value: boolean);
begin
  // main menu
  loadbtn      .enabled := value;
  reloadbtn    .enabled := value;
  clearbtn     .enabled := value;
  startbtn     .enabled := value;
  stopbtn      .enabled := value;
  killbtn      .enabled := value;
  layoutbtn    .enabled := value;
  aboutbtn     .enabled := value;
  // calibration
  leftupbtn    .enabled := value;
  leftdownbtn  .enabled := value;
  leftedit     .enabled := value;
  rightupbtn   .enabled := value;
  rightdownbtn .enabled := value;
  rightedit    .enabled := value;
  penupbtn     .enabled := value;
  pendownbtn   .enabled := value;
  gohomebtn    .enabled := value;
  // page format
  formatcb     .enabled := value;
  heightse     .enabled := value;
  widthse      .enabled := value;
  offsetxse    .enabled := value;
  offsetyse    .enabled := value;
  verticalcb   .enabled := value;
  application  .processmessages;
end;

// LOADER/PLOTTER THREAD EVENTS

procedure tmainform.onloadstart;
begin
  lock2(false);
end;

procedure tmainform.onloadend;
var
  i, j: longint;
  path: tvppath;
   pos: tvpposition;
begin
  // updtare preview ...
  for i := 0 to paths.count - 1 do
  begin
    path := paths.item[i];
    for j := 0 to path.count - 1 do
    begin
      pos := path.item[j];
      bitmap.canvas.pixels[
        trunc(( widthse.value div 2) + pos.x + offsetxse.value + 1),
        trunc((heightse.value div 2) - pos.y - offsetyse.value + 1)] := clblack;
    end;
  end;
  image.canvas.draw(0, 0, bitmap);
  lock2(true);
end;

procedure tmainform.onplotterstart;
begin
  lock1(false);

  progressbar.visible:= true;
  application.processmessages;
end;

procedure tmainform.onplotterstop;
begin
  driverthread := nil;
  penupbtnclick(nil);

  lock1(true);
  progressbar.visible:= false;
  application.processmessages;
end;

procedure tmainform.onplottertick;
begin
  progressbar.position := driverthread.progress;
  application.processmessages;
end;

end.

