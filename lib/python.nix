{ pkgs }:

# Centralized Python package management
#
# This module provides categorized Python package sets to avoid duplication
# across the codebase. All modules should import packages from here instead
# of declaring them individually.
#
# Usage in modules:
#   pythonPackages = (import ../lib/python.nix { inherit pkgs; }).datascience;

let
  py = pkgs.python313Packages;
in
{
  # Core Python tooling (package managers, build tools)
  core = with py; [
    pip
    virtualenv
    uv
    setuptools
    wheel
    pipx
    pip-tools
  ];

  # Data science and numerical computing
  datascience = with py; [
    numpy
    pandas
    scipy
    matplotlib
    seaborn
    plotly
    scikit-learn
    pillow
  ];

  # Machine Learning and AI
  ml = with py; [
    transformers
    litellm
    anthropic
    langchain-xai
    langchain-mistralai
    google-genai
    # crewai # Commented out if not stable
  ];

  # Jupyter ecosystem
  jupyter = with py; [
    ipykernel
    ipywidgets
    jupyter-core
    jupyterlab-git
    nbconvert
    nbformat
    jupyter-client
    jupyter-sphinx
    jupyter-server-terminals
    jupyter-server
    jupyter-repo2docker
  ];

  # Package development and publishing
  development = with py; [
    build
    twine
  ];

  # System utilities
  utilities = with py; [
    yt-dlp
    requests
    httpx
    pydantic
    rich
    pyyaml
    toml
    psutil
    mutagen
    pydub
  ];

  # NVIDIA/GPU related
  gpu = with py; [
    nvidia-ml-py
  ];

  # Create a complete Python environment with specified package categories
  # Usage: mkPythonEnv [ "core" "datascience" "ml" ]
  mkPythonEnv =
    categories:
    let
      pythonLib = import ./python.nix { inherit pkgs; };
      allPackages = {
        inherit (pythonLib)
          core
          datascience
          ml
          jupyter
          development
          utilities
          gpu
          ;
      };
      selectedPackages = pkgs.lib.lists.flatten (map (cat: allPackages.${cat} or [ ]) categories);
    in
    pkgs.python313.withPackages (ps: selectedPackages);
}
