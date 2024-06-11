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

type
  TLexeme = class
  private
    FLine: integer;
    FColumn: integer;
    FText: string;

  public
    constructor Create(const ln, col: integer);
    property Line: integer read FLine;
    property Column: integer read FColumn;
    property Text: string read FText;
    procedure Add(const c: Char);
  end;

  LexerState = (lsStart, lsCollect);

  // TODO: var???
  TLexemeEvent = procedure( { var } lex: string { TLexeme } ) of object;

  TLexer = class
  private
    FLexemeFound: TLexemeEvent;
    FLine: integer;
    FColumn: integer;
    FState: LexerState;
    function StartProcessChar(const c: Char): LexerState;
    function CollectProcessChar(const c: Char): LexerState;
    // Virtual and dynamic methods can be overridden in descendent classes.
    procedure DoLexemeFound( { var } lex: string { TLexeme } );

  public
    constructor Create;
    procedure NextChar(const c: Char);
    procedure NextLine;

    property OnLexemeFound: TLexemeEvent read FLexemeFound write FLexemeFound;
  end;

implementation

uses System.Character, System.SysUtils;

{ ----------------------------------------------------------------------------- }
{ TLexeme }
{$REGION TLexeme }

procedure TLexeme.Add(const c: Char);
begin
  FText := FText + c;
end;

constructor TLexeme.Create(const ln, col: integer);
begin
  FLine := ln;
  FColumn := col;
end;
{$ENDREGION}
{ ----------------------------------------------------------------------------- }
{ TLexer }
{$REGION TLexer }

constructor TLexer.Create;
begin
  FLine := 1;
  FColumn := 1;
  FState := lsStart;
end;
{$ENDREGION}

procedure TLexer.NextChar(const c: Char);
begin
  Inc(FColumn);
  case FState of
    lsStart:
      FState := StartProcessChar(c);
    lsCollect:
      FState := CollectProcessChar(c);
  else
    ;
  end;
end;

procedure TLexer.NextLine;
begin
  Inc(FLine);
  FColumn := 1;
end;

function TLexer.StartProcessChar(const c: Char): LexerState;
begin
  if FState <> lsStart then
    raise Exception.Create('Not in state: Start');

  if IsWhiteSpace(c) then
    Exit(lsStart) // no-op
  else // if IsLetter(c) then
    // Create a new lexeme
    FState := lsCollect;
end;

procedure TLexer.DoLexemeFound( { var } lex: string { TLexeme } );
begin
  if Assigned(FLexemeFound) then
    FLexemeFound(lex);
end;

function TLexer.CollectProcessChar(const c: Char): LexerState;
begin
  if FState <> lsCollect then
    raise Exception.Create('Not in state: Collect');

  if IsWhiteSpace(c) then
  begin
    // finish lexeme
    DoLexemeFound('pruttel');
    Exit(lsStart);
  end // ;
  else
  // if IsLetter(c) then
  begin
    // Add to lexeme
    Exit(lsCollect);
  end;

end;

end.
