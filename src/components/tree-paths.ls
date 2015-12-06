require! {
  # PROJECT COMPONENTS
  './tree-path.ls': TreePath
}

module.exports = class TreePaths extends React.Component

  render: ->
    $g do
      @props.paths |> map (link) ~>
        $(TreePath) do
          draw-path: @props.draw-path
          link: link
