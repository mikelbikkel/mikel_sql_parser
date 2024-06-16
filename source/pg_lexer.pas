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
unit pg_lexer;

interface

uses System.SysUtils, System.Classes;

type
  TTokenType = (ttEOF, ttEOL);

  TToken = class
  private
    FLine: integer;
    FColumn: integer;
    FText: string;
    FType: TTokenType;

  public
    constructor Create(const ln, col: integer);
    property Line: integer read FLine;
    property Column: integer read FColumn;
    property Text: string read FText;
    property TokenType: TTokenType read FType;

    procedure Add(const c: Char);
  end;

  LexerState = (lsStart, lsCollect);

  // TODO: var???
  TTokenEvent = procedure( { var } lex: TToken) of object;

  TLexer = class
  private
    FToken: TToken;
    FTokenFound: TTokenEvent;
    FReader: TStreamReader;
    FLine: integer;
    FColumn: integer;
    FState: LexerState;
    function StartProcessChar(const c: Char): LexerState;
    function CollectProcessChar(const c: Char): LexerState;
    // Virtual and dynamic methods can be overridden in descendent classes.
    procedure DoTokenFound;

  public
    constructor Create(const fname: string; const enc: TEncoding);
    destructor Destroy; override;
    procedure NextChar(const c: Char);
    procedure NextLine;

    function GetNextToken(): TToken;

    property OnTokenFound: TTokenEvent read FTokenFound write FTokenFound;
  end;

implementation

uses System.Character;

{ ----------------------------------------------------------------------------- }
{ TToken }
{$REGION TToken }

procedure TToken.Add(const c: Char);
begin
  FText := FText + c;
end;

constructor TToken.Create(const ln, col: integer);
begin
  FLine := ln;
  FColumn := col;
end;
{$ENDREGION}
{ ----------------------------------------------------------------------------- }
{ TLexer }
{$REGION TLexer }

constructor TLexer.Create(const fname: string; const enc: TEncoding);
begin
  FReader := TStreamReader.Create(fname, enc);
  FLine := 1;
  FColumn := 0;
  FState := lsStart;
end;

procedure TLexer.NextChar(const c: Char);
begin
  Inc(FColumn);
  case FState of
    lsStart:
      FState := StartProcessChar(c);
    lsCollect:
      FState := CollectProcessChar(c);
  else
    raise Exception.Create('unknown state');
  end;
end;

procedure TLexer.NextLine;
begin
  // TODO: return lexeme if collecting. Reset state to Start-state.
  Inc(FLine);
  FColumn := 1;
end;

function TLexer.StartProcessChar(const c: Char): LexerState;
begin
  if FState <> lsStart then
    raise Exception.Create('Not in state: Start');

  if IsWhiteSpace(c) then
    Exit(lsStart); // no-op

  // if IsLetter(c) then
  FToken := TToken.Create(FLine, FColumn);
  FToken.Add(c);
  Result := lsCollect;
end;

destructor TLexer.Destroy;
begin
  if Assigned(FReader) then
  begin
    FReader.Close;
    FReader.Free;
    FReader := nil;
  end;

  inherited;
end;

procedure TLexer.DoTokenFound;
begin
  if Assigned(FTokenFound) then
    FTokenFound(FToken);
end;

function TLexer.GetNextToken: TToken;
var
  i: integer;
  iNext: integer;
  c: Char;
  t: TToken;
begin

  while FReader.Peek >= 0 do
  begin
    i := FReader.Read;
    c := Chr(i);
    Inc(FColumn);
    if (i = $000D) or (i = $000A) or (i = $02AA) then
    begin
      // Handle EOL.
      // $02AA is Unicode LS (LineSeparator), code point: U+02AA
      Result := TToken.Create(FLine, FColumn);
      Result.FType := ttEOL;
      Inc(FLine);
      FColumn := 0;
      iNext := FReader.Peek;
      if iNext = $000A then
        FReader.Read;
      Exit(Result);
    end;

  end;

  Result := TToken.Create(FLine, FColumn);
  Result.FType := ttEOF;
end;

function TLexer.CollectProcessChar(const c: Char): LexerState;
begin
  if FState <> lsCollect then
    raise Exception.Create('Not in state: Collect');

  if IsWhiteSpace(c) then
  begin // Signal we found a lexeme and return to start state.
    DoTokenFound;
    Exit(lsStart);
  end; // ;

  // Add character to the lexeme and continue if IsLetter(c) then
  FToken.Add(c);
  Result := lsCollect;
end;

{$ENDREGION}

end.
