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
    memoToken: TMemo;
    procedure actOpenExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);

    procedure HandleDriverMsg(const msg: string);
    procedure HandleToken(const msg: string);
  private
    function getFileEncoding: TEncoding;
    // procedure PrintBytes(const fname: string; const enc: TEncoding);
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
  eb: TEncoding;
  lst: TStrings;
begin
  eb := nil;
  lst := nil;
  if dlgOpenText.Execute then
  begin
    memoBin.Clear;
    memoFile.Clear;
    memoToken.Clear;
    fname := dlgOpenText.FileName;
    eb := getFileEncoding;
    var
      drvr: TPgDriver := TPgDriver.Create;
    drvr.OnMessageEvent := HandleDriverMsg;
    drvr.ProcessFile(fname, eb);

    lst := drvr.ByteShowFile(fname, eb);
    memoBin.Lines := lst;
    lst.Free;

    drvr.OnTokenEvent := HandleToken;
    drvr.ProcessFile2(fname, eb);

    drvr.Free;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  ReportMemoryLeaksOnShutdown := true;
end;

function TfrmMain.getFileEncoding: TEncoding;
var
  enc: string;
  idx: Integer;
begin
  idx := dlgOpenText.EncodingIndex;
  enc := dlgOpenText.Encodings[idx];
  if enc = 'ASCII' then
    Result := TEncoding.ASCII
  else if enc = 'ANSI' then
    Result := TEncoding.ANSI
  else if enc = 'UTF-7' then
    Result := TEncoding.UTF7
  else if enc = 'UTF-8' then
    Result := TEncoding.UTF8
  else
    raise Exception.Create('Unknown encoding: ' + enc);
end;

procedure TfrmMain.HandleDriverMsg(const msg: string);
begin
  memoFile.Lines.Add(msg);
end;

procedure TfrmMain.HandleToken(const msg: string);
begin
  memoToken.Lines.Add(msg);
end;

{
  procedure TfrmMain.PrintBytes(const fname: string; const enc: TEncoding);
  var
  b: TBytes;
  bt: Byte;
  begin
  b := TFile.ReadAllBytes(fname);
  for bt in b do
  memoBin.Lines.Append(IntToHex(bt) + ' ');
  end;
}
end.
