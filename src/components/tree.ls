require! {
  # CONFIG
  '../config/design.ls': design-config

  # VENDOR COMPONENTS
  'react-motion': { Motion, spring }

  # PROJECT COMPONENTS
  './tree-nodes.ls': TreeNodes
  './tree-node.ls':  TreeNode
  './tree-paths.ls': TreePaths
  './tree-path.ls':  TreePath
}

design-config.svg =
  margin:
    vertical: do
      design-config.node.size +
      design-config.node.border.width.default +
      design-config.node.border.width.variation
    horizontal: do
      design-config.node.size / 2 +
      design-config.node.border.width.default +
      design-config.node.border.width.variation

module.exports = class Tree extends React.Component

  (props) !->
    super props
    @state =
      width: 0
      height: 0

  component-will-mount: !->
    window.add-event-listener 'resize', @calculate-layout

  component-did-mount: !->
    @wrapper = ReactDOM.find-DOM-node @refs.tree-container
    @calculate-layout!

  calculate-layout: !~>
    width =
      @wrapper.offset-width - design-config.svg.margin.horizontal * 2
    height =
      window.inner-height - design-config.svg.margin.vertical * 2

    @set-state do
      width: width
      height: height
      layout: D3.layout.cluster!
        .size [width, height]
        .separation (a,b) ->
          if a.name in design-config.main-nodes or b.name in design-config.main-nodes
            3
          else
            if a.parent is b.parent then 1 else 2
      draw-path: D3.svg.diagonal!
        .projection (d) ->
          [d.x, height - d.y]

  component-will-unmount: !->
    window.remove-event-listener 'resize', @calculate-layout

  render: ->
    return '' unless @props

    const { tree-data } = @props

    $main do
      ref: 'treeContainer'
      style:
        min-height: 1

      $svg do
        width: @state.width + design-config.svg.margin.horizontal * 2
        height: @state.height + design-config.svg.margin.vertical * 2

        $g do
          transform: """
            translate(
              #{design-config.svg.margin.horizontal},
              #{design-config.svg.margin.vertical}
            )
          """

          if @state.layout?

            const nodes = @state.layout.nodes tree-data

            const path-elements = $(TreePaths) do
              paths: @state.layout.links nodes
              draw-path: @state.draw-path

            if tree-data.name is 'Origin of Life'
              const archaea-to-eukarya-path = $(TreePath) do
                draw-path: @state.draw-path
                link:
                  source: nodes |> find (.name is 'Archaea')
                  target: nodes |> find (.name is 'Eukarya')

            const node-elements = $(TreeNodes) do
              nodes: nodes
              cluster-root-node: tree-data
              tree-height: @state.height
              on-node-click: @props.on-node-click
              last-mouse-position: @props.last-mouse-position
              active-node: @props.active-node

            $g do

              $(Motion) do
                key: 'path-cluster-' + tree-data.id
                default-style:
                  x: @props.last-mouse-position?x or tree-data.x
                  y: @state.height - (@props.last-mouse-position?y or tree-data.y)
                  scale: 0
                style:
                  x: spring 0, design-config.traversal-animation-spring
                  y: spring 0, design-config.traversal-animation-spring
                  scale: spring 1, design-config.traversal-animation-spring
                (transitioning-values) ->
                  $g do
                    transform: """
                      translate(
                        #{transitioning-values.x},
                        #{transitioning-values.y}
                      )
                      scale(#{transitioning-values.scale})
                    """
                    path-elements
                    tree-data.name is 'Origin of Life' and archaea-to-eukarya-path
                    node-elements

              if @props.active-node?cluster-root and
                 @props.last-mouse-position?

                const active-node-clone = {} <<< @props.active-node
                const final-x = @props.last-mouse-position?x or tree-data.x
                const final-y =
                  if active-node-clone.children?
                    @state.height
                  else
                    0

                $(Motion) do
                  key: 'active-node-overlay-' + active-node-clone.id + '-' + tree-data.id
                  default-style:
                    x: final-x
                    y: final-y
                  style:
                    x: spring active-node-clone.x, design-config.traversal-animation-spring
                    y: spring active-node-clone.y, design-config.traversal-animation-spring
                  (transitioning-values) ~>
                    # Only display overlay node during transitions
                    return $g! if transitioning-values.y < 1 or
                      transitioning-values.y > @state.height - 1

                    $g do
                      key: 'tree-node-overlay-' + active-node-clone.id
                      ref: 'tree-node-overlay-' + active-node-clone.id
                      style:
                        pointer-events: 'none'
                      $(TreeNode) do
                        node: active-node-clone <<< do
                          x: transitioning-values.x
                          y: transitioning-values.y
                        cluster-root-node: tree-data
                        tree-height: @state.height
                        on-node-click: @props.on-node-click
                        last-mouse-position: @props.last-mouse-position
                        active-node: @props.active-node
