{
  description = "PE's Neovim (penvim) Configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (self: super: {
            inherit (super) vimPlugins;
          })
        ];
      };

      recursiveMerge = attrList: let
        f = attrPath:
          builtins.zipAttrsWith (n: values:
            if pkgs.lib.tail values == []
            then pkgs.lib.head values
            else if pkgs.lib.all pkgs.lib.isList values
            then pkgs.lib.unique (pkgs.lib.concatLists values)
            else if pkgs.lib.all pkgs.lib.isAttrs values
            then f (attrPath ++ [n]) values
            else pkgs.lib.last values);
      in
        f [] attrList;
    in rec {
      dependencies = with pkgs;
        [
          nodejs
          ripgrep
          fzf
          fish
          git
          curl
          luaformatter
          nil # nix lsp
          alejandra
          statix
          shellcheck
          lua-language-server
          nodePackages.prettier
          nodePackages.vscode-langservers-extracted
          nodePackages.svelte-language-server
          nodePackages.diagnostic-languageserver
          nodePackages.typescript-language-server
          nodePackages.bash-language-server
          rust-analyzer
          # rust-analyzer is currently in a partially broken state as it cannot find rust sources so can't
          # help with native language things, which sucks. Here are some issues to track:
          # https://github.com/rust-lang/rust/issues/95736
          # https://github.com/rust-lang/rust-analyzer/issues/13393
          # https://github.com/mozilla/nixpkgs-mozilla/issues/238
          # https://github.com/rust-lang/cargo/issues/10096
          rustfmt
          cargo
          gcc
          rustc
          clang-tools
          #llvm # for debugging rust
          #lldb # for debugging rust
          #vscode-extensions.vadimcn.vscode-lldb # for debugging rust
        ]
        ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
          wl-clipboard # needed by vim clipboard-image plugin
        ]
        ++ pkgs.lib.optionals pkgs.stdenv.isDarwin
        []; # needed by vim clipboard-image plugin
      neovim-augmented = recursiveMerge [
        pkgs.neovim-unwrapped
        {buildInputs = dependencies;}
      ];
      packages.penvim = pkgs.wrapNeovim neovim-augmented {
        viAlias = true;
        vimAlias = true;
        withNodeJs = false;
        withPython3 = false;
        withRuby = false;
        extraPython3Packages = false;
        extraMakeWrapperArgs = ''--prefix PATH : "${pkgs.lib.makeBinPath dependencies}"'';
        # make sure impatient is loaded before everything else to speed things up
        configure = {
          customRC =
            ''
              lua << EOF
                package.path = "${self}/?.lua;" .. package.path
                rustsrc_path = "${pkgs.rustPlatform.rustLibSrc}/core/Cargo.toml"
                vim.env.RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}"
                vim.env.RA_LOG = "info,salsa::derived::slot=warn,chalk_recursive=warn,hir_ty::traits=warn,flycheck=trace,rust_analyzer::main_loop=warn,ide_db::apply_change=warn,project_model=debug,proc_macro_api=debug,hir_expand::db=error,ide_assists=debug,ide=debug"
                rustanalyzer_path = "${pkgs.rust-analyzer}/bin/rust-analyzer"
            ''
            + pkgs.lib.readFile ./init.lua
            + ''
              EOF
            '';

          packages.myPlugins = with pkgs.vimPlugins; {
            start = with pkgs.vimPlugins; [
              plenary-nvim
              telescope-nvim
              fidget-nvim # show lsp status in bottom right but not status line
              SchemaStore-nvim # json schemas

              crates-nvim # inline intelligence for Cargo.toml
              rust-tools-nvim
              null-ls-nvim # formatting and linting via lsp system
              lsp-format-nvim # still needed?
              lspsaga-nvim # maybe not?
              nvim-lspconfig

              trouble-nvim
              nvim-treesitter
              undotree
              vim-fugitive
              copilot-vim
              nui-nvim
              rose-pine # color-scheme

              #nvim-dap # debugging functionality used by rust-tools-nvim
              #nvim-dap-ui # ui for debugging

              (nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars))
              playground
              nvim-treesitter-textobjects
              nvim-treesitter-context

              vim-abolish
              comment-nvim
              # Autocompletion
              nvim-cmp # generic autocompleter
              nvim-lspconfig
              cmp-treesitter
              cmp-clippy
              cmp-copilot
              cmp-nvim-lsp # use lsp as source for completions
              cmp-nvim-lua # makes vim config editing better with completions
              cmp-buffer # any text in open buffers
              cmp-path # complete paths
              cmp-cmdline # completing in :commands
              cmp-emoji # complete :emojis:
              cmp-nvim-lsp-signature-help # help complete function call by showing args
              cmp-npm # complete node packages in package.json
              luasnip # snippets driver
              cmp_luasnip # snippets completion
              friendly-snippets # actual library of snippets used by luasnip

              impatient-nvim # speeds startup times by caching lua bytecode
            ];
            opt = with pkgs.vimPlugins; [
            ];
          };
        };
      };
      apps.penvim = flake-utils.lib.mkApp {
        drv = packages.penvim;
        name = "penvim";
        exePath = "/bin/nvim";
      };
      packages.default = packages.penvim;
      apps.default = apps.penvim;
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [packages.penvim] ++ dependencies;
      };
    });
}
