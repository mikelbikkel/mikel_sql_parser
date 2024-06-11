program mk_sql_parser;

uses
  Vcl.Forms,
  pg_driver in '..\..\source\pg_driver.pas',
  pg_lexer in '..\..\source\pg_lexer.pas',
  frm_main in '..\..\source\frm_main.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
