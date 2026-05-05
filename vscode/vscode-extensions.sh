#!/usr/bin/env bash
set -euo pipefail

EDITOR_CLI="${EDITOR_CLI:-code}"

extensions=(
  dbaeumer.vscode-eslint
  enkia.tokyo-night
  eamodio.gitlens
  naumovs.color-highlight
  oderwat.indent-rainbow
  PKief.material-icon-theme
  steoates.autoimport
  HookyQR.beautify
  ecmel.vscode-html-css
  usernamehw.errorlens
  formulahendry.auto-close-tag
  formulahendry.auto-rename-tag
  editorconfig.editorconfig
  esbenp.prettier-vscode
  arcticicestudio.nord-visual-studio-code
  aliariff.auto-add-brackets
  emmanuelbeziat.vscode-great-icons
  miguelsolorio.fluent-icons
  expo.vscode-expo-tools
  davidanson.vscode-markdownlint
  ocamllabs.ocaml-platform
  redhat.vscode-yaml
)

for extension in "${extensions[@]}"; do
  "$EDITOR_CLI" --install-extension "$extension"
done
