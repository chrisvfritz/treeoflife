require! {
  # CONFIG
  '../config/design.ls': design-config

  # VENDOR ASSETS
  '../vendor/css/bootstrap-popover.css'

  # VENDOR COMPONENTS
  'react-bootstrap/lib/OverlayTrigger'
  'react-bootstrap/lib/Popover'
  'react-motion': { Motion, spring }
}

module.exports = class TreeNode extends React.Component

  render: ->

    const {
      node, cluster-root-node, active-node, last-mouse-position, tree-height,
      on-node-click
    } = @props

    const node-radius =
      if node.name in design-config.main-nodes
        design-config.node.size
      else
        design-config.node.size / 2

    const node-background =
      if node.id is active-node?id
        design-config.node[node.group].background
      else
        design-config.node.background

    $(OverlayTrigger) do
      animation: false
      placement: 'left'
      trigger: <[ hover ]>
      root-close: true
      overlay: $(Popover) do
        id: 'circle-tooltip-' + node.id
        style:
          margin-right: 50
        node.name

      $g do
        key: 'node-group-' + node.id
        class-name: 'node'
        transform: """
          translate(#{node.x}, #{tree-height - node.y})
        """

        $circle do
          key: 'node-circle-' + node.id
          class-name: node.cluster-root and 'wobble'
          r: node-radius
          style:
            fill: node-background
            cursor: do
              if node.id is active-node?id and not node.cluster-root
                'default'
              else
                'pointer'
            stroke: design-config.node[node.group].background
            stroke-width: 2
          on-click: !~>
            on-node-click node
