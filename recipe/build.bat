@echo on

rem -- get build datetime
for /f "tokens=*" %%a in (
'python -c "import datetime; print(datetime.datetime.now(datetime.UTC).strftime('%%Y-%%m-%%dT%%H:%%M:%%SZ'))"'
) do (
set BUILD_DATE=%%a
)

go generate ./...
if %ERRORLEVEL% neq 0 exit 1

set "CGO_ENABLED=0"
set "CLIENT_TAGS=forceposix,client"

set "CONFIG_PKG=github.com/pelicanplatform/pelican/version"
set "LDFLAGS=-w -s -X %CONFIG_PKG%.version=%PKG_VERSION% -X %CONFIG_PKG%.commit=v%PKG_VERSION% -X %CONFIG_PKG%.date=%BUILD_DATE% -X %CONFIG_PKG%.builtBy=conda-forge"

rem -- run the build
go build ^
  -a ^
  -ldflags "%LDFLAGS%" ^
  -tags "%CLIENT_TAGS%" ^
  -p "%CPU_COUNT%" ^
  -v ^
  -o "%LIBRARY_BIN%\pelican.exe" ^
  .\cmd
if %ERRORLEVEL% neq 0 exit 1

rem -- generate the license pack
set "GOFLAGS=-tags=%CLIENT_TAGS%"
go get ./...
go-licenses save ^
  --save_path license-files ^
  --ignore "modernc.org/mathutil" ^
  --ignore "github.com/jmespath/go-jmespath" ^
  --ignore "go.opentelemetry.io/otel/exporters/jaeger/internal/third_party/thrift/lib/go/thrift" ^
  .\cmd
if %ERRORLEVEL% neq 0 exit 1
