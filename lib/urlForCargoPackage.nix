{ crateRegistries
, lib
}:

{ name
, version
, source
, checksum
, ...
}:
let
  substr = builtins.substring;

  # https://doc.rust-lang.org/cargo/reference/registries.html
  nameLen = builtins.stringLength name;
  prefix =
    if nameLen == 1 then "1"
    else if nameLen == 2 then "2"
    else if nameLen == 3 then "3/${substr 0 1 name}"
    else "${substr 0 2 name}/${substr 2 4 name}";

  registry = crateRegistries.${source} or (throw ''
    not sure how to download crates from ${source}.
    for example, this can be resolved with:

    craneLib = crane.lib.''${system}.appendCrateRegistries [
      (lib.registryFromDownloadUrl {
        dl = "https://crates.io/api/v1/crates";
        indexUrl = "https://github.com/rust-lang/crates.io-index";
      })

      # Or, alternatively
      (lib.registryFromGitIndex {
        url = "https://github.com/Hirevo/alexandrie-index";
        rev = "90df25daf291d402d1ded8c32c23d5e1498c6725";
      })
    ];

    # Then use the new craneLib instance as you would normally
    craneLib.buildPackage {
      # ...
    }
  '');
in
{
  fetchurlExtraArgs = registry.fetchurlExtraArgs or { };
  url = builtins.replaceStrings
    [
      "{crate}"
      "{version}"
      "{prefix}"
      "{lowerprefix}"
      "{sha256-checksum}"
    ]
    [
      name
      version
      prefix
      (lib.toLower prefix)
      checksum
    ]
    registry.downloadUrl;
}
