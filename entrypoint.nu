#!/usr/bin/env nu

def main [] {
  let targets = open /targets.txt
  | lines
  | where $it !~ '^#' and $it != ''

  add-targets $targets
  build-binaries $targets
  package-binaries $targets

  print 'Build completed!'

  if (in-github-actions) {
    release-binaries $targets
  }

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
    cargo zigbuild --target $target -r
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

def in-github-actions [] {
  return ('GITHUB_TOKEN' in $env)
}

def is-windows [target: string] {
  let triplet = ($target | split row -)

  let os = $triplet.2

  $os == 'windows'
}

def package-binaries [targets: list<string>] {
  print 'Packaging binaries...'

  let package_name: string = (open Cargo.toml).package.name
  let ref_name = get-ref-name
  let ext = "tar.gz"

  $targets | each {|target|
    let dir = $"target/($target)/release"

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
  print 'Releasing binaries...'

  let package_name: string = (open Cargo.toml).package.name
  let ref_name = get_ref_name
  let ext = "tar.gz"

  let archives: list<string> = ($targets | each {|target|
    let archive = $"($package_name)-($ref_name)-($target).($ext)"
    $archive
  })

  gh release create $ref_name $archives
}
