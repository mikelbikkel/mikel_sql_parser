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
  TTokenType = (ttUnkown, ttEOF, ttEOL, ttID, ttNumber, ttOperator);

  TTokenTypeHelper = record helper for TTokenType
    function GetName: string;
  end;

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
    function ToString: string; override;
  end;

  TTokenManager = class
  strict private
    FTokens: tObjectList<TToken>;
  public
    constructor Create;
    destructor Destroy; override;
    function NewToken: TToken;
  end;

  TLexerState = (lsStart, lsCollect, lsCommentLine);

  TLexer = class
  private
    FReader: TStreamReader;
    FLine: integer;
    FColumn: integer;

  public
    constructor Create(const fname: string; const enc: TEncoding);
    destructor Destroy; override;

    procedure GetNextToken(var tok: TToken);
    procedure GetNextToken2(var tok: TToken);

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

function TToken.ToString: string;
const
  fmt: string = '[%d, %d] - %s - <%s>';
begin
  Result := Format(fmt, [FLine, FColumn, FType.GetName, FText]);
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

// TODO: switch to FSM?? This gets too complicated.
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
    i := FReader.Peek;
    c := Chr(i);
    if (i = $000D) or (i = $000A) or (i = $02AA) then
    begin
      if state = lsCollect then
      begin
        Exit;
      end;
      Inc(FColumn);
      FReader.Read;
      // Handle EOL. CRLF, CR, LF and LS.
      // $02AA is Unicode LS (LineSeparator), code point: U+02AA
      tok.FLine := FLine;
      tok.FColumn := FColumn;
      tok.FType := ttEOL;
      tok.FText := 'newline';
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
      Inc(FColumn);
      FReader.Read;
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
      if state = lsCollect then
        if tok.FType = ttID then
        begin
          Inc(FColumn);
          FReader.Read;
          tok.Add(c);
        end
        else
          Exit;
    end
    else if c.IsDigit then
    begin
      if state = lsStart then
      begin
        tok.FLine := FLine;
        tok.FColumn := FColumn;
        tok.FType := ttNumber;
        state := lsCollect;
      end;
      if state = lsCollect then
        if tok.FType = ttNumber then
        begin
          Inc(FColumn);
          FReader.Read;
          tok.Add(c);
        end
        else
          Exit;
    end
    else
    begin
      if state = lsCollect then
        Exit;
      Inc(FColumn);
      FReader.Read;
      tok.FLine := FLine;
      tok.FColumn := FColumn;
      tok.FType := ttUnkown;
      tok.Add(c);
      Exit;
    end;
  end;

  if state = lsStart then
  begin
    tok.FLine := FLine;
    tok.FColumn := FColumn;
    tok.FType := ttEOF;
  end;
end;

procedure TLexer.GetNextToken2(var tok: TToken);
var
  i: integer;
  iNext: integer;
  c: Char;
  cNext: Char;
  state: TLexerState;
begin

  state := lsStart;
  while FReader.Peek >= 0 do
  begin
    i := FReader.Peek;
    c := Chr(i);
    begin
      case state of
        lsCommentLine: { eat until EOL }
          if (i = $000D) or (i = $000A) or (i = $02AA) then
            state := lsStart
          else
            FReader.Read;
        lsStart:
          begin
            if (i = $000D) or (i = $000A) or (i = $02AA) then
            begin // TODO: newline should not return a token.
              Inc(FColumn);
              FReader.Read;
              // Handle EOL. CRLF, CR, LF and LS.
              // $02AA is Unicode LS (LineSeparator), code point: U+02AA
              tok.FLine := FLine;
              tok.FColumn := FColumn;
              tok.FType := ttEOL;
              tok.FText := 'newline';
              Inc(FLine);
              FColumn := 0;
              iNext := FReader.Peek;
              if iNext = $000A then
                FReader.Read;
              Exit;
            end;
            if (i = $000C) then
              { ignore form feed };
            if c.IsWhiteSpace then
            begin { eat whitespace }
              Inc(FColumn);
              FReader.Read;
            end;
            if c.IsDigit then
            begin
              FReader.Read;
              Inc(FColumn);
              tok.FLine := FLine;
              tok.FColumn := FColumn;
              tok.FType := ttID;
              state := lsCollect;
            end;
            if c.IsLetter or (c = '_') then
            begin
              FReader.Read;
              Inc(FColumn);
              tok.FLine := FLine;
              tok.FColumn := FColumn;
              tok.FType := ttNumber;
              state := lsCollect;
            end;
            if (c = '-') then
            begin { this is either a - (minus) or a -- (start of comment until EOL) }
              FReader.Read;
              Inc(FColumn);
              iNext := FReader.Peek;
              cNext := Chr(iNext);
              if cNext = '-' then
              begin
                FReader.Read;
                state := lsCommentLine;
              end
              else
              begin
                tok.FLine := FLine;
                tok.FColumn := FColumn;
                tok.FType := ttOperator;
                Exit;
              end;
            end
          end;
        lsCollect:
          if (i = $000D) or (i = $000A) or (i = $02AA) or (i = $000C) or c.IsWhiteSpace
          then
            Exit;
      else
        raise Exception.Create('lexer state error');
      end;
    end;

    if state = lsStart then
    begin
      tok.FLine := FLine;
      tok.FColumn := FColumn;
      tok.FType := ttEOF;
    end;

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
{ TTokenTypeHelper }

function TTokenTypeHelper.GetName: string;
begin
  case self of
    ttUnkown:
      Result := 'ttUnkown';
    ttEOF:
      Result := 'ttEOF';
    ttEOL:
      Result := 'ttEOL';
    ttID:
      Result := 'ttID';
    ttNumber:
      Result := 'ttNumber';
  else
    Result := '?';
  end;
end;

end.
