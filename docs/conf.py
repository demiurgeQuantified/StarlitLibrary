# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'Starlit Library'
copyright = '2025, albion'
author = 'albion'
release = 'v42-1.5.0'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
	'sphinx_lua_ls'
]

lua_ls_project_root = "../Contents/mods/StarlitLibrary/42/media/lua"


templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']
highlight_language = "lua"



# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']
