# Managed by Home Manager — rustup
# 本体は Nix で導入。toolchain は ~/.rustup、proxy(cargo/rustc等)は ~/.cargo/bin。
export RUSTUP_HOME="$HOME/.rustup"
export CARGO_HOME="$HOME/.cargo"
path_prepend "$CARGO_HOME/bin"
