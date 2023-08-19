#!/usr/bin/env nu

def main [] {
  let targets = [
    x86_64-apple-darwin
    aarch64-apple-darwin
    i686-unknown-linux-gnu

    # Fails in:
    # cargo-zigbuild: 0.17.0
    # Rust: 1.71.0
    # Zig: 0.11.0

    # i686-unknown-linux-musl

    x86_64-unknown-linux-gnu

    # Fails in:
    # cargo-zigbuild: 0.17.0
    # Rust: 1.71.0
    # Zig: 0.11.0

    # x86_64-unknown-linux-musl

    aarch64-unknown-linux-gnu

    # Fails in:
    # cargo-zigbuild: 0.17.0
    # Rust: 1.71.0
    # Zig: 0.11.0

    # aarch64-unknown-linux-musl

    i686-pc-windows-gnu

    # Not supported
    # i686-pc-windows-msvc

    x86_64-pc-windows-gnu

    # Not supported
    # x86_64-pc-windows-msvc

    # Not supported
    # aarch64-pc-windows-msvc
  ]

  add-target $targets
  build-binaries $targets
  package-binaries $targets
  release-binaries $targets

  print 'Build completed!'

  return
}

def add-target [targets: list<string>] {
  print 'Adding targets...'

  $targets | each {|target|
    rustup -q target add $target
  }
}

def build-binaries [targets: list<string>] {
  print 'Building binaries...'

  $targets | each {|target|
    cargo zigbuild --target $target -qr
  }
}

def get-ref-name [] {
  let ref_name = (git rev-parse --short HEAD)

  if 'GITHUB_REF_NAME' in $env {
    return $ref_name
  }

  git diff --quiet

  if $env.LAST_EXIT_CODE != 0 {
    return $"($ref_name)-dirty"
  }

  return $ref_name
}

def is-windows [target: string] {
  let triplet = ($target | split row -)

  let os = $triplet.2

  $os == 'windows'
}

def package-binaries [targets: list<string>] {
  print 'Packaging binaries...'

  $targets | each {|target|
    let package_name: string = (open Cargo.toml).package.name
    let ref_name = get-ref-name

    let dir = $"target/($target)/release"

    let ext = "tar.gz"
    let archive = $"($package_name)-($ref_name)-($target).($ext)"
    let file = $package_name

    let file = if (is-windows $target) {
      $"($file).exe"
    } else {
      $file
    }

    tar -acC $dir -f $archive $file
  }
}

def release-binaries [targets: list<string>] {
  let archives: list<string> = ($targets | each {|target|
    let package_name: string = (open Cargo.toml).package.name
    let ext = "tar.gz"
    let archive = $"($package_name)-($target).($ext)"
    $archive
  })

  gh release create $env.GITHUB_REF_NAME $archives
}
