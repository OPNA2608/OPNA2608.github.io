{
  stdenvNoCC,
  lib,
  writers,
}:

let
  navs = [
    {
      pos = 1;
      href = "/";
      text = "Home";
    }
  ];
  navbar =
    let
      links =
        lib.strings.concatMapStringsSep "\n"
          (elem: ''
            <li class="nav-${lib.strings.toLower elem.text}">
              <a href="${elem.href}">
                ${elem.text}
              </a>
            </li>
          '')
          (
            builtins.sort (
              a: b:
              let
                aPos = a.pos or 1;
                bPos = b.pos or 9999999;
              in
              aPos < bPos
            ) navs
          );
    in
    ''
      <nav>
        <ul>
      ${links}
        </ul>
      </nav>
    '';
  parts =
    builtins.map
      (
        data:
        let
          nameToPath = lib.path.append ./.;
        in
        if builtins.typeOf data == "set" then
          {
            src = nameToPath data.filename;
          }
          // data
        else if builtins.typeOf data == "string" then
          {
            filename = data;
            src = nameToPath data;
          }
        else
          throw "Invalid entry in parts: ${builtins.toString data} (${builtins.typeOf data})"
      )
      [
        {
          filename = "index.html";
          src = writers.writeText "index.html" (
            lib.strings.replaceString "<nix-generate-nav />" navbar (builtins.readFile ./index.html.in)
          );
        }
        "assets"
      ];
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "website-full";
  version = "0-unstable-${finalAttrs.passthru.date}";

  srcs = builtins.map (x: x.src) parts;

  dontUnpack = true;
  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    mkdir -p $out

  ''
  + (lib.strings.concatMapStringsSep "\n" (
    x: "cp -vr --no-preserve=all ${x.src} $out/${x.filename}"
  ) parts)
  + ''

    substituteInPlace $out/index.html \
      --replace-fail 'CURRENT_YEAR' '${builtins.head (lib.strings.splitString "-" finalAttrs.passthru.date)}'

    runHook postBuild
  '';

  passthru = {
    date = "YYYY-MM-DD";
  };
})
