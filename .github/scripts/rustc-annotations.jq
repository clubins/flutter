# Turns `cargo --message-format=json-diagnostic-rendered-ansi` output into the
# usual rendered diagnostics for the log, each followed by a GitHub workflow
# command that shows it as an inline annotation.
# $dir is the crate directory relative to the repository root; rustc reports
# paths relative to the crate, annotations need them relative to the repo.

def esc: gsub("%"; "%25") | gsub("\r"; "%0D") | gsub("\n"; "%0A");
def prop: esc | gsub(":"; "%3A") | gsub(","; "%2C");

select(.reason == "compiler-message") | .message
| (.rendered // empty),
  ((.spans | map(select(.is_primary)) | first) as $s
   | select($s != null)
   | (if .level == "error" or .level == "warning" then .level else "notice" end) as $cmd
   | (if ($s.file_name | startswith("/")) then $s.file_name else "\($dir)/\($s.file_name)" end) as $file
   | "::\($cmd) file=\($file | prop),line=\($s.line_start),endLine=\($s.line_end),col=\($s.column_start),title=\(.code.code // .level | prop)::\(.message | esc)")
