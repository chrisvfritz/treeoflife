require! {
  './tree-node.ls': TreeNode
}

module.exports = class TreeNodes extends React.Component

  render: ->

    const {
      nodes, cluster-root-node, active-node, last-mouse-position, tree-height
      on-node-click
    } = @props

    $g do
      nodes
        |> sort-by (.x)
        |> map (node) ~>
          $(TreeNode) do
            key: 'tree-node-' + node.id
            ref: 'tree-node-' + node.id
            node: node
            cluster-root-node: cluster-root-node
            tree-height: tree-height
            active-node: active-node
            last-mouse-position: last-mouse-position
            on-node-click: on-node-click
