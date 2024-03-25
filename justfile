set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

default:
  just --list

export RUSTFLAGS := "-Ctarget-cpu=native -Cprefer-dynamic=no"

[private]
[no-exit-message]
@probe-7zip:
    7z | out-null

# Installs ripgrep find llvm just mpv-install
install-all: ripgrep find oxipng mpv-install helix llvm

# Updates ripgrep find mpv rust
update-all: ripgrep find oxipng just llvm rust mpv

nvim-data := env_var("LOCALAPPDATA") + "/nvim-data"

# Updates rust toolchain(s)
rust:
    rustup update

# Installs & updates just
just:
    -git.exe clone https://github.com/casey/just.git {{data_directory()}}/just
    git -C {{data_directory()}}/just pull
    # Just cannot install itself :(
    echo "cargo +nightly install --locked --path {{data_directory()}}/just"

# Installs & updates ripgrep
ripgrep:
    -git.exe clone https://github.com/BurntSushi/ripgrep.git {{data_directory()}}/ripgrep
    git -C {{data_directory()}}/ripgrep pull
    -cargo +nightly install --locked --features "pcre2" --path {{data_directory()}}/ripgrep

# Installs & updates Helix
helix:
    -git.exe clone https://github.com/helix-editor/helix.git {{data_directory()}}/helix
    git -C {{data_directory()}}/helix pull
    -cargo +nightly install --locked --features "unicode-lines" --path {{data_directory()}}/helix/helix-term

# Installs & updates find
find:
    -git clone https://github.com/sharkdp/fd.git {{data_directory()}}/fd
    git -C {{data_directory()}}/fd pull
    cargo +nightly install --locked --path {{data_directory()}}/fd

mpv_latest := "https://api.github.com/repos/shinchiro/mpv-winbuild-cmake/releases/latest"
mpv_dir := data_directory() + "/mpv"

oxipng:
    -git clone https://github.com/shssoichiro/oxipng.git {{data_directory()}}/oxipng
    git -C {{data_directory()}}/oxipng pull
    cargo +nightly install --locked --path {{data_directory()}}/oxipng

# Install mpv
mpv-install:
    mkdir {{mpv_dir}}
    $ProgressPreference = 'SilentlyContinue'; \
    $url = (Invoke-RestMethod {{mpv_latest}}).assets.Where( {$_.name -like "mpv-x86_64-v3*"} ).browser_download_url; \
    Invoke-WebRequest $url -OutFile {{mpv_dir}}/mpv.7z
    7z x {{mpv_dir}}/mpv.7z -o{{data_directory()}}/mpv

    git clone https://github.com/RossSmyth/mpv_config.git {{mpv_dir}}/portable_config

# Updates mpv & config
mpv:
    {{mpv_dir}}/updater.bat
    git -C {{mpv_dir}}/portable_config pull


llvm_latest := "https://api.github.com/repos/llvm/llvm-project/releases/latest"

# Installs & updates LLVM
llvm: probe-7zip
    $ProgressPreference = 'SilentlyContinue'; \
    $json = $json = curl.exe "https://api.github.com/repos/llvm/llvm-project/releases/latest" | ConvertFrom-Json; \
    $url = $json.assets.Where( {$_.name -like "*windows*"} ).browser_download_url; \
    Write-Output $url; \
    curl.exe -L --output "{{data_directory()}}/llvm.tar.xz" "$url"
    7z e {{data_directory()}}/llvm.tar.xz -o"{{data_directory()}}/llvm_tar" *.tar
    7z x {{data_directory()}}/llvm_tar/llvm.tar -o"{{data_directory()}}/llvm_new"
    rm {{data_directory()}}/llvm.tar.xz
    rm -R {{data_directory()}}/llvm_tar
    rm -R {{data_directory()}}/llvm
    mv "{{data_directory()}}/llvm_new/clang*" "{{data_directory()}}/llvm"