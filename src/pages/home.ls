require! {
  '../config/design.ls': design-config
  '../lib/preprocessed-tree-data.ls': initial-tree-data

  '../components/intro-box.ls': IntroBox
  '../components/sidebar.ls': Sidebar
  '../components/tree.ls': Tree
  '../components/breadcrumbs.ls': Breadcrumbs

  # '../lib/tree.ls': Tree
}

module.exports = Radium class Home extends React.Component

  (props) !->
    super props
    @state =
      tree-data: initial-tree-data
      original-source: jQuery.extend {}, initial-tree-data

  collapse-children: (target-node) !~>

    const ensure-collapsed-child-clusters = (node) !->
      if node.cluster-root and node.children
        node._children = node.children
        node.children = null
      if node.children
        node.children.for-each ensure-collapsed-child-clusters
      else if node._children
        node._children.for-each ensure-collapsed-child-clusters

    target-node.children.for-each ensure-collapsed-child-clusters

  update-cluster-root-with: (activated-node) !~>

    if @state.tree-data.id is activated-node.id

      @collapse-children activated-node

      activated-node._children = activated-node.children
      activated-node.children = null

      activated-node.parent = activated-node._parent
      activated-node._parent = null

      const search-for-parent-cluster = (node) !~>

        if node.parent.cluster-root or not node.parent.parent
          @set-state do
            tree-data: node.parent
        else
          search-for-parent-cluster node.parent

      search-for-parent-cluster activated-node

    else

      activated-node.children = activated-node._children
      activated-node._children = null

      activated-node._parent = activated-node.parent
      activated-node.parent = null

      @set-state do
        tree-data: activated-node

  component-will-mount: !->
    body-styles = {
      padding-left: design-config.sidebar.width + 'px'
      padding-right: design-config.breadcrumbs.width  + 'px'
      background: design-config.tree.background
      font-family: "'Open Sans', 'Helvetica Neue', Helvetica, Verdana, Arial, sans-serif"
      position: 'relative'
      overflow: 'hidden'
    }
    for property, value of body-styles
      document.body.style[property] = value

  component-did-mount: !->
    jQuery('#intro-link').trigger 'click'
    new Tree().render!

  render: ->
    $div do

      $(IntroBox)!

      $(Sidebar) do
        featured-node: @state.active-node or @state.tree-data

      $(Breadcrumbs) do
        tree-data: @state.tree-data
        on-breadcrumb-click: (clicked-breadcrumb) !~>
          unless clicked-breadcrumb.id is @state.tree-data.id
            matched-node = undefined

            find_node = (node) ~>
              if node.id is clicked-breadcrumb.id
                matched-node := node
                @collapse-children matched-node
                return
              node.children.for-each  find_node if node.children
              node._children.for-each find_node if node._children
            find_node jQuery.extend({}, @state.original-source)

            @set-state do
              tree-data: matched-node
              last-mouse-position: null

      $(Tree) do
        tree-data: @state.tree-data
        last-mouse-position: @state.last-mouse-position
        active-node: @state.active-node
        on-node-click: (clicked-node) !~>
          unless clicked-node.id is @state.active-node?id
            @set-state do
              active-node: clicked-node
          return unless clicked-node.cluster-root

          @set-state do
            last-mouse-position:
              x: clicked-node.x
              y: clicked-node.y

          @update-cluster-root-with clicked-node
