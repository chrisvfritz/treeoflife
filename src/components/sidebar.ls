require! {
  'react-motion': { Motion, spring }
  '../config/design.ls': design-config
}

module.exports = Radium class Sidebar extends React.Component

  render: ->
    const { featured-node } = @props

    $aside do
      id: 'sidebar'
      style:
        position: 'fixed'
        top: 0
        left: 0
        width: design-config.sidebar.width
        height: '100%'
        background: design-config.sidebar.background
        color: design-config.sidebar.text-color

      $(Motion) do
        key: 'sidebar-' + featured-node.id
        default-style:
          opacity: 0
        style:
          opacity: spring 1, [60, 15]
        (transitioning-values) ->
          $div do
            class-name: 'scroll-area'
            style:
              opacity: transitioning-values.opacity
              height: '100%'
              overflow-y: 'scroll'
              box-sizing: 'border-box'
              padding: "#{design-config.sidebar.padding.vertical}px #{design-config.sidebar.padding.horizontal}px"
              margin-bottom: design-config.sidebar.padding.vertical

            $a do
              key: 'sidebar-anchor-' + featured-node.id + Math.random!
              href: "http://eol.org/search?q=#{encode-URI-component featured-node.name}&search=Go"
              target: '_blank'
              style:
                color: '#4E8B9A'
                text-decoration: 'none'
                ':hover':
                  text-decoration: 'underline'

              $h2 do
                style:
                  margin-top: 0
                id: 'name'
                featured-node.name

            $div do
              id: 'image'
              style:
                padding: 10
                background: design-config.sidebar.image.background
                border-radius: 4
                text-align: 'center'

              $img do
                style:
                  max-width: '100%'
                  max-height: 250
                  filter: 'invert(1)'
                src: featured-node.image
                alt: featured-node.name

            $p do
              id: 'description'
              featured-node.desc
