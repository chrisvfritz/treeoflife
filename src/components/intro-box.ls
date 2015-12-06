require! {
  '../vendor/css/lightbox.css'
  '../vendor/js/lightbox.js'
  '../images/intro.png': intro-image-url
}

module.exports = Radium class IntroBox extends React.Component

  render: ->

    $a do
      id: 'intro-link'
      href: intro-image-url
      'data-lightbox': 'intro'
