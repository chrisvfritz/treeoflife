require! {
  # VENDOR ASSETS
  '../vendor/css/lightbox.css'
  '../vendor/js/lightbox.js'

  # PROJECT ASSETS
  '../images/intro.png': intro-image-url
}

module.exports = Radium class IntroBox extends React.Component

  render: ->

    $a do
      id: 'intro-link'
      href: intro-image-url
      'data-lightbox': 'intro'
