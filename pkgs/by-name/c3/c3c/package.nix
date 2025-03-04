{
  lib,
  fetchFromGitHub,
  llvmPackages,
  cmake,
  python3,
  curl,
  libxml2,
  libffi,
  xar,
  rev ? "unknown",
  debug ? false,
  checks ? false,
}: let 
  inherit (builtins) readFile elemAt;
  # inherit (lib.sources) cleanSourceWith cleanSource; 
  inherit (lib.lists) findFirst;
  inherit (lib.asserts) assertMsg;
  inherit (lib.strings) hasInfix splitString removeSuffix removePrefix optionalString;
in llvmPackages.stdenv.mkDerivation (finalAttrs: {

  pname = "c3c";
  version = "0.6.8";

  src = fetchFromGitHub {
    owner = "c3lang";
    repo = "c3c";
    tag = "v${finalAttrs.version}";
    hash = "sha256-CG/fG/QVuL5tKTK9xFXrwsC0riCJilE8BE+v+tmoTVI=";
  };
  
  cmakeBuildType = if debug then "Debug" else "Release";
  
  postPatch = ''
    substituteInPlace git_hash.cmake \
      --replace-fail "\''${GIT_HASH}" "${rev}"
  '';

  cmakeFlags = [
    "-DC3_ENABLE_CLANGD_LSP=${if debug then "ON" else "OFF"}"
    "-DC3_LLD_DIR=${llvmPackages.lld.lib}/lib"
    "-DLLVM_CRT_LIBRARY_DIR=${llvmPackages.compiler-rt}/lib/darwin"
  ];

  nativeBuildInputs = [ 
    cmake 
    llvmPackages.llvm
    llvmPackages.lld 
    llvmPackages.compiler-rt
  ];

  buildInputs = [
    curl
    libxml2
    libffi
  ] ++ lib.optionals llvmPackages.stdenv.hostPlatform.isDarwin [ xar ];

  nativeCheckInputs = [ python3 ];

  doCheck = llvmPackages.stdenv.system == "x86_64-linux" && checks;

  checkPhase = ''
    runHook preCheck
    ( cd ../resources/testproject; ../../build/c3c build --trust=full )
    ( cd ../test; ../build/c3c compile-run -O1 src/test_suite_runner.c3 -- ../build/c3c test_suite )
    runHook postCheck
  '';


  meta = with lib; {
    description = "Compiler for the C3 language";
    homepage = "https://github.com/c3lang/c3c";
    license = licenses.lgpl3Only;
    maintainers = with maintainers; [
      luc65r
      anas
      vssukharev
    ];
    platforms = platforms.all;
    mainProgram = "c3c";
  };
})
