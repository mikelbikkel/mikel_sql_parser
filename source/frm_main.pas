{ ******************************************************************************

  Copyright (c) 2024 M van Delft.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  ****************************************************************************** }
unit frm_main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  Vcl.StdCtrls, Vcl.ExtDlgs;

type
  TfrmMain = class(TForm)
    dlgOpenText: TOpenTextFileDialog;
    btnOpenFile: TButton;
    lstMain: TActionList;
    actOpen: TAction;
    memoFile: TMemo;
    memoBin: TMemo;
    procedure actOpenExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);

    procedure HandleDriverMsg(const msg: string);
  private
    procedure PrintBytes(const fname: string);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses System.Character, System.IOUtils, pg_driver;

{$R *.dfm}

procedure TfrmMain.actOpenExecute(Sender: TObject);
var
  fname: string;
  enc: string;
  idx: Integer;
  eb: TEncoding;
begin
  eb := nil;
  idx := -1;
  if dlgOpenText.Execute then
  begin
    memoBin.Clear;
    memoFile.Clear;
    fname := dlgOpenText.FileName;
    // PrintBytes(fname);
    idx := dlgOpenText.EncodingIndex;
    enc := dlgOpenText.Encodings[idx];
    if enc = 'ASCII' then
      eb := TEncoding.ASCII
    else if enc = 'ANSI' then
      eb := TEncoding.ANSI
    else if enc = 'UTF-7' then
      eb := TEncoding.UTF7
    else if enc = 'UTF-8' then
      eb := TEncoding.UTF8;

    var
      drvr: TPgDriver := TPgDriver.Create;
    drvr.OnMessageEvent := HandleDriverMsg;
    drvr.ProcessFile(fname, eb);
    drvr.Free;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  ReportMemoryLeaksOnShutdown := true;
end;

procedure TfrmMain.HandleDriverMsg(const msg: string);
begin
  memoFile.Lines.Add(msg);
end;

procedure TfrmMain.PrintBytes(const fname: string);
var
  b: TBytes;
  bt: Byte;
begin
  b := TFile.ReadAllBytes(fname);
  for bt in b do
    memoBin.Lines.Append(IntToHex(bt) + ' ');
end;

end.
