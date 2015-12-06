require! {
  'react-motion': { Motion, spring }
  '../config/design.ls': design-config
}

module.exports = class TreePath extends React.Component

  render: ->
    $path do
      key: 'path-' + @props.link.source.id + '->' + @props.link.target.id
      d: @props.draw-path @props.link
      style:
        fill: 'transparent'
        stroke: design-config.path.background
