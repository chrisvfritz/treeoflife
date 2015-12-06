module.exports =

  # ------
  # GLOBAL
  # ------

  traversal-animation-spring: [
    # https://github.com/chenglou/react-motion#spring-number---stiffness-damping---configurationobject
    40 # Stiffness
    15 # Damping
  ]

  path:
    background: '#9BA09B'

  # -------
  # SIDEBAR
  # -------

  sidebar:
    width: 350
    padding:
      horizontal: 25
      vertical: 15
    background: '#262626'
    text-color: '#9BA09B'

    image:
      background: '#2E2E2E'

  # ----
  # TREE
  # ----

  tree:
    background: '#1E1E1E'

  node:
    size: 50
    background: '#9BA09B'

    border:
      width:
        default: 2
        variation: 4
      background: '#9BA09B'

    archaea:
      background: '#9F8B51'
    eukarya:
      background: '#33748E'
    bacteria:
      background: '#257D3F'
    origin:
      background: 'white'

  main-nodes:
    * 'Origin of Life'
    * 'Bacteria'
    * 'Archaea'
    * 'Eukarya'

  # -----------
  # BREADCRUMBS
  # -----------

  breadcrumbs:
    width: 75

    home-icon:
      size: 40

  breadcrumb:
    size: 40
