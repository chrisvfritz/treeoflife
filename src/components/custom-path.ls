module.exports = class CustomPath extends React.Component

  render: ->
    $path do
      d: @props.draw-path do
        source: @props.source
        target: @props.target
