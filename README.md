# Is a portable nix configuration for my neovim setup

It is heavily `inspired` by: https://github.com/zmre/pwnvim.

To run it: `nix run github:nichtsfrei/penvim`

To integrate it
```
{
  inputs = {
	nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
	# ...
	pwnvim.url = "github:nichtsfrei/penvim";
  }
  outputs = inputs@{ penvim, ... }: {
	pkgs = import nixpkgs {
	  inherit system;
	  overlays = [
		(final: prev: {
		  pwnvim = inputs.pwnvim.packages.${final.system}.pwnvim;
		})
	  ];
	};
  }
}
```
