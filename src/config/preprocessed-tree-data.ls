module.exports = do

  root = CONFIG.tree-data

  i = 0
  root.id = ++i

  trickle-down-preprocessing = (node) !->
    node.id = ++i

    if node.children

      node.children.forEach (child) ->
        child.group or= node.group
        child.image or= node.image

      if node.cluster-root
        node._children = node.children
        node.children  = null
        node._children.forEach trickle-down-preprocessing
      else
        node.children.forEach trickle-down-preprocessing

  trickle-down-preprocessing root

  root
