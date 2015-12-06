require! {
  '../config/design.ls': design-config
  '../images/home.png': home-icon-url
  'react-bootstrap/lib/OverlayTrigger'
  'react-bootstrap/lib/Popover'
  'react-motion': { Motion, spring }
}

module.exports = class Breadcrumbs extends React.Component

  (props) !->
    super props
    @state =
      height: 0

  component-will-mount: !->
    window.add-event-listener 'resize', @calculate-layout

  component-did-mount: !->
    @calculate-layout!

  calculate-layout: !~>
    const height = window.inner-height
    const breadcrumbs-height = height - design-config.breadcrumbs.home-icon.size - 100

    @set-state do
      height: height
      breadcrumbs-height: breadcrumbs-height
      layout: D3.layout.tree!
        .size [
          design-config.breadcrumbs.width
          breadcrumbs-height
        ]
      draw-path: D3.svg.diagonal!
        .projection (d) ->
          [0, breadcrumbs-height - d.y]

  render: ->
    const find-cluster-roots = (node) ->
      node.children = null
      if node._parent
        node.parent = jQuery.extend {}, node._parent
        while not node.parent.cluster-root and node.parent.parent?
          node.parent = jQuery.extend {}, node.parent.parent
        node.parent.parent = find-cluster-roots node.parent
        node.parent.children = [node]
        return node.parent
      null

    breadcrumbs = jQuery.extend {}, @props.tree-data
    breadcrumbs.parent = find-cluster-roots breadcrumbs

    while breadcrumbs.parent
      breadcrumbs = breadcrumbs.parent

    $nav do
      style:
        position: 'fixed'
        top: 0
        right: 0
        width: design-config.breadcrumbs.width
        height: '100%'
        background: design-config.sidebar.background
        min-height: 1

      $svg do
        width: design-config.breadcrumbs.width
        height: @state.height

        $g dangerously-set-inner-HTML:
          __html: """
            <filter id="inverse-color-matrix">
              <feColorMatrix
                in="SourceGraphic"
                type="matrix"
                values="-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 1 0"
              ></feColorMatrix>
            </filter>
          """

        $g do
          transform: """
            translate(#{design-config.breadcrumbs.width / 2},#{design-config.node.size})
          """

          $(OverlayTrigger) do
            animation: false
            placement: 'left'
            trigger: <[ hover ]>
            root-close: true
            overlay: $(Popover) do
              id: 'breadcrumb-home-button-popover'
              'Home'

            $a do
              xlink-href: 'http://opentreeoflife.org/'

              $image do
                x: -design-config.breadcrumbs.home-icon.size / 2
                y: -design-config.breadcrumbs.home-icon.size / 2
                width: design-config.breadcrumbs.home-icon.size
                height: design-config.breadcrumbs.home-icon.size
                xlink-href: home-icon-url

        $g do
          transform: """
            translate(
              #{design-config.breadcrumbs.width / 2},
              #{design-config.node.size + design-config.breadcrumbs.home-icon.size + 10}
            )
          """

          if @state.layout?

            const nodes = @state.layout.nodes breadcrumbs

            const breadcrumb-links = $g do

              if nodes.length > 1

                $(Motion) do
                  default-style:
                    scale: 0
                  style:
                    scale: spring 1, design-config.traversal-animation-spring
                  (transitioning-values) ~>

                    $g do
                      transform: """
                        scale(#{transitioning-values.scale})
                      """

                      $path do
                        d: "M0,#{@state.breadcrumbs-height}C0,#{@state.breadcrumbs-height / 2} 0,#{@state.breadcrumbs-height / 2} 0,0"
                        fill: 'trasparent'
                        stroke: design-config.path.background
                        stroke-dasharray: '2, 10'

            const breadcrumb-nodes = $g do

              nodes |> map (node) ~>

                  $(Motion) do
                    default-style:
                      y: 0
                      opacity: 0
                    style:
                      opacity: spring 1, design-config.traversal-animation-spring
                      y: spring do
                        if nodes.length is 1
                          0
                        else
                          @state.breadcrumbs-height - node.y
                        design-config.traversal-animation-spring
                    (transitioning-values) ~>

                      $g do
                        width: design-config.breadcrumbs.width
                        key: 'breadcrumb-group-' + node.id
                        class-name: 'node'
                        transform: """
                            translate(0,#{transitioning-values.y})
                          """
                        style:
                          opacity: transitioning-values.opacity

                        $(OverlayTrigger) do
                          animation: false
                          placement: 'left'
                          trigger: <[ hover ]>
                          root-close: true
                          overlay: $(Popover) do
                            id: 'breadcrumb-popover-' + node.id
                            if @props.tree-data.id is node.id
                              "#{node.name} (Current Cluster)"
                            else
                              node.name

                          $image do
                            x: -20
                            y: -20
                            width: 40
                            height: 40
                            xlink-href: node.image
                            style:
                              filter: 'url(#inverse-color-matrix)'
                              cursor: do
                                if @props.tree-data.id is node.id
                                  'not-allowed'
                                else
                                  'pointer'
                            on-click: !~>
                              unless @props.tree-data.id is node.id
                                @props.on-breadcrumb-click node

            [
              breadcrumb-links
              breadcrumb-nodes
            ]
                #     nodes_entering.append 'image'
                #       .attr 'x', -20
                #       .attr 'y', -20
                #       .attr 'width', '40px'
                #       .attr 'height', '40px'
                #       .style 'filter', 'url(#inverse_color_matrix)'
                #       .attr 'xlink:href', (d) -> d.image
                #       .on 'click', (d) =>
                #         unless is_current_cluster d
                #           matched_node = undefined
                #           collapse_child_clusters = (node) ->
                #             if node.cluster_root && node.children
                #               node._children = node.children
                #               node.children = null
                #             else if node.children
                #               node.children.forEach collapse_child_clusters
                #
                #           find_node = (node) ->
                #             if node.id is d.id
                #               matched_node = node
                #               matched_node.children.forEach collapse_child_clusters
                #               return
                #             node.children.forEach  find_node if node.children
                #             node._children.forEach find_node if node._children
                #           find_node @original_source
                #           @main_tree.update matched_node
                #
                #     nodes_being_positioned = node_elements.transition()
                #       .duration 1000
                #       .attr 'transform', (d) =>
                #         "translate(#{d.x},#{@height + @height_of_home_icon - d.y})"
                #       .style 'opacity', 1

                # $text do
                #   text-anchor: 'middle'
                #   node.name
                # $circle do
                #   key: 'breadcrumb-icon-' + node.id
                #   r: 20
                #   cx: -design-config.breadcrumbs.width / 2
                #   # cy: -20

        # .attr 'height', @height + @vertical_padding + @height_of_home_icon
