{
  stdenvNoCC,
  lib,
  writers,
}:

let
  sortListByPos = builtins.sort (
    a: b:
    let
      aPos = a.pos or 1;
      bPos = b.pos or 9999999;
    in
    aPos < bPos
  );

  navs = [
    {
      pos = 1;
      href = "/";
      text = "Home";
    }
  ];
  navbar =
    let
      links = lib.strings.concatMapStringsSep "\n" (elem: ''
        <li class="nav-${lib.strings.toLower elem.text}">
        <a href="${elem.href}">
        ${elem.text}
        </a>
        </li>
      '') (sortListByPos navs);
    in
    ''
      <nav>
      <ul>
      ${links}
      </ul>
      </nav>
    '';

  thingsList = [
    {
      pos = 1;
      text = "I do weird stuff";
    }
    {
      pos = 2;
      text = "I like old stuff";
    }
    {
      pos = 3;
      text = "I'm not a graphical designer";
    }
    {
      pos = 4;
      text = "I'm not super serious about things";
    }
    {
      pos = 5;
      text = "Light mode rulez";
    }
    {
      pos = 6;
      text = "Fuck AIs/LLMs";
    }
    {
      pos = 7;
      text = "Fuck SEO";
    }
    {
      pos = 8;
      text = "&#x1F986; (duck)";
    }
  ];
  thingsListHtml =
    let
      things = lib.strings.concatMapStringsSep "\n" (elem: "<li>${elem.text}</li>") (
        sortListByPos thingsList
      );
    in
    ''
      <ul>
      ${things}
      </ul>
    '';
  thingsListOpenGraph = lib.strings.concatMapStringsSep " | " (elem: elem.text) (
    sortListByPos thingsList
  );

in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "website-full";
  version = "0-unstable-${finalAttrs.passthru.date}";

  srcs = builtins.map (x: x.src) finalAttrs.passthru.parts;

  dontUnpack = true;
  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    mkdir -p $out

  ''

  + (lib.strings.concatMapStringsSep "\n" (x: ''
    cp -vr --no-preserve=all ${x.src} $out/${x.filename}
  '') finalAttrs.passthru.parts)

  + ''

    runHook postBuild
  '';

  passthru = {
    date = "YYYY-MM-DD";
    parts =
      builtins.map
        (
          data:
          let
            nameToPath = lib.path.append ./.;
          in
          if builtins.typeOf data == "set" then
            {
              src =
                if data ? "transforms" then
                  writers.writeText data.filename (
                    lib.lists.foldl (prev: entry: entry prev) (builtins.readFile (
                      nameToPath data.filename + ".in"
                    )) data.transforms
                  )
                else
                  nameToPath data.filename;
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
            transforms = [
              (lib.strings.replaceString "PAGE_TITLE" "Home") # TODO make more generic
              (lib.strings.replaceString "<nix-generate-nav />" navbar)
              (lib.strings.replaceString "THINGS_LIST_OPENGRAPH" thingsListOpenGraph)
              (lib.strings.replaceString "<nix-generate-things-list />" thingsListHtml)
              (lib.strings.replaceString "CURRENT_YEAR" (
                builtins.head (lib.strings.splitString "-" finalAttrs.passthru.date)
              ))
            ];
          }
          "assets"
        ];
  };
})
