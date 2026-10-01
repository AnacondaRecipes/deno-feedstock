@echo on
@setlocal EnableDelayedExpansion

set CMAKE_POLICY_VERSION_MINIMUM=3.5
set RUSTFLAGS=-C target-feature=-crt-static

REM bindgen (via libsqlite3-sys) needs libclang. libclang is a build dep, so it
REM lives in %BUILD_PREFIX% (not the host %PREFIX%). defaults ships it as a
REM versioned DLL (libclang-*.dll), but bindgen/clang-sys look for the
REM unversioned "libclang.dll", so copy it under that name.
set "LIBCLANG_PATH=%BUILD_PREFIX%\Library\bin"
if exist "%BUILD_PREFIX%\Library\bin\libclang-*.dll" (
  for %%f in ("%BUILD_PREFIX%\Library\bin\libclang-*.dll") do copy /y "%%f" "%BUILD_PREFIX%\Library\bin\libclang.dll"
)

REM check licenses
cargo-bundle-licenses --format yaml --output THIRDPARTY.yml || goto :error

REM build with Deno's upstream release-lite profile (thin LTO, codegen-units=128)
REM to avoid rustc-LLVM OOM during final link on hosted Windows runners.
cargo install --profile release-lite --bins --no-track --locked --root "%LIBRARY_PREFIX%" --path .\cli || goto :error

mkdir %PREFIX:/=\%\etc\conda\activate.d
echo SET "DENO_INSTALL_ROOT=%LIBRARY_PREFIX:/=\%" > "%PREFIX:/=\%\etc\conda\activate.d\deno.bat"

mkdir %PREFIX:/=\%\etc\conda\deactivate.d
echo SET "DENO_INSTALL_ROOT=" > "%PREFIX:/=\%\etc\conda\deactivate.d\deno.bat"

goto :EOF

:error
echo Failed with error #%errorlevel%.
exit 1
