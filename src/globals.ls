root = global or window

# VENDOR ASSIGN
root import
  jQuery:   require 'jquery'
  React:    require 'react'
  ReactDOM: require 'react-dom'
  Radium:   require 'radium'
  D3:       require 'd3'
  $:        require 'arch-dom'

# STANDARD LIBRARY
root import require 'prelude-ls'

# HELPERS
for key of $
  root["$#{key}"] = $[key]
root import require './helpers.ls'

# CONFIG
root import
  CONFIG:
    tree-data: require './config/tree-data.yml'

# VENDOR
require './vendor/js/d3-tip.js'
