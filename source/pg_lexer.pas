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

uses System.SysUtils, System.Classes, System.Generics.Collections;

type
  TTokenType = (ttUnkown, ttEOF, ttEOL, ttID);

  TToken = class
  private
    FLine: integer;
    FColumn: integer;
    FText: string;
    FType: TTokenType;

  public
    constructor Create;
    property Line: integer read FLine;
    property Column: integer read FColumn;
    property Text: string read FText;
    property TokenType: TTokenType read FType;

    procedure Add(const c: Char);
  end;

  TTokenManager = class
  strict private
    FTokens: tObjectList<TToken>;
  public
    constructor Create;
    destructor Destroy; override;
    function NewToken: TToken;
  end;

  TLexerState = (lsStart, lsCollect);

  TLexer = class
  private
    FReader: TStreamReader;
    FLine: integer;
    FColumn: integer;

  public
    constructor Create(const fname: string; const enc: TEncoding);
    destructor Destroy; override;

    procedure GetNextToken(var tok: TToken);

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

constructor TToken.Create;
begin
  FLine := 0;
  FColumn := 0;
end;
{$ENDREGION}
{ ----------------------------------------------------------------------------- }
{ TLexer }
{$REGION TLexer }

// TODO: should lexer manage the stream resource?
// Or add stream as a param to GetNextToken?
constructor TLexer.Create(const fname: string; const enc: TEncoding);
begin
  FReader := TStreamReader.Create(fname, enc);
  FLine := 1;
  FColumn := 0;
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

// TODO: Peek and Read...
procedure TLexer.GetNextToken(var tok: TToken);
var
  i: integer;
  iNext: integer;
  c: Char;
  state: TLexerState;
begin
  state := lsStart;
  while FReader.Peek >= 0 do
  begin
    i := FReader.Read;
    c := Chr(i);
    Inc(FColumn);
    if (i = $000D) or (i = $000A) or (i = $02AA) then
    begin
      // Handle EOL. CRLF, CR, LF and LS.
      // $02AA is Unicode LS (LineSeparator), code point: U+02AA
      tok.FLine := FLine;
      tok.FColumn := FColumn;
      tok.FType := ttEOL;
      Inc(FLine);
      FColumn := 0;
      iNext := FReader.Peek;
      if iNext = $000A then
        FReader.Read;
      Exit;
    end
    else if i = $000C then
      // Ignore form feed.
    else if c.IsWhiteSpace then
    begin
      // Zs category, or a tab ( U+0009 ), CR, LF or FF ( U+000C )
      if state = lsCollect then
        Exit;
    end
    else if c.IsLetter then
    begin
      if state = lsStart then
      begin
        tok.FLine := FLine;
        tok.FColumn := FColumn;
        tok.FType := ttID;
        state := lsCollect;
      end;
      tok.Add(c);
    end;
  end;

  if state = lsStart then
  begin
    tok.FLine := FLine;
    tok.FColumn := FColumn;
    tok.FType := ttEOF;
  end;
end;

{$ENDREGION}
{ ----------------------------------------------------------------------------- }
{ TTokenManager }
{$REGION TTokenManager }

constructor TTokenManager.Create;
begin
  FTokens := tObjectList<TToken>.Create;
end;

destructor TTokenManager.Destroy;
begin
  if Assigned(FTokens) then
  begin
    FTokens.Clear;
    FTokens.Free;
    FTokens := nil;
  end;
  inherited;
end;

function TTokenManager.NewToken: TToken;
begin
  Result := TToken.Create;
  FTokens.Add(Result);
end;
{$ENDREGION}

end.
