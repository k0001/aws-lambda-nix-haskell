let

pkg =
  { patchelf, stdenv, writeText, zip, exe }:
  let
  jsMain= writeText "run-exe.js" ''
    var spawn = require('child_process').spawn;
    process.env['PATH'] =
      process.env['PATH'] + ':' + process.env['LAMBDA_TASK_ROOT'];
    process.env['LD_LIBRARY_PATH'] = process.env['LAMBDA_TASK_ROOT'];
    exports.handler = function(input, context) {
      var child = spawn("./exe", []);
      child.stdin.write(JSON.stringify(input));
      child.stdin.end();
      child.on('close', function (code) {
        if (code !== 0) { context.done(code, 'Error in process'); }
        context.done(null, 'Process complete!');
      });
      child.on('error', function (err) {
        context.done(err, 'Error in process');
      });
      // Log process stdout and stderr
      child.stdout.on('data', function(buf) { console.log(buf.toString()); });
      child.stderr.on('data', function(buf) { console.error(buf.toString()); });
    };
  '';
  in
  stdenv.mkDerivation {
    name = "lambda-zip";
    buildCommand = ''
      pushd `mktemp -d`
      cp ${jsMain} main.js
      cp ${exe} exe


      mkdir lib
      # copy libraries
      cp `ldd exe | grep -F '=> /' | awk '{print $3}'` lib/
      # copy interpreter
      cp `${patchelf}/bin/patchelf --print-interpreter exe` lib/ld.so

      chmod +w exe
      ${patchelf}/bin/patchelf --set-interpreter lib/ld.so exe
      ${patchelf}/bin/patchelf --set-rpath lib exe
      chmod -w exe

      ${zip}/bin/zip -r -9 out.zip ./
      mv out.zip $out

      popd
    '';
  };

in

{ pkgs ? import <nixpkgs> {} }:

let
hs = pkgs.haskell.packages.ghc802;
hsLib = pkgs.haskell.lib;
foo = hsLib.overrideCabal (hs.callPackage ./foo/pkg.nix {}) (old: {
  isLibrary = false;
  enableSharedLibraries = false;
  enableSharedExecutables = false;
});

in
pkgs.callPackage pkg { exe = "${foo}/bin/foo"; }
