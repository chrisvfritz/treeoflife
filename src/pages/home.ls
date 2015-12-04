require! {
  '../images/intro.png': intro-image-url
  '../lib/tree.coffee': Tree
}

module.exports = class Home extends React.Component

  component-did-mount: !->
    jQuery('#intro-link').trigger 'click'
    set-timeout do
      !->
        new Tree().render!
      1000

  render: ->
    $div do

      $a do
        id: 'intro-link'
        href: intro-image-url
        'data-lightbox': 'intro'

      $div do
        id: 'sidebar'

        $div do
          class-name: 'scroll_area'

          $a do
            href: 'http://eol.org/search?q=Origin+of+Life&search=Go' target: '_blank'

            $h2 do
              id: 'name'
              "Origin of Life"

          $div do
            id: 'image'

            $img do
              src:  'http://phylopic.org/assets/images/submissions/6b79f4f2-3c34-4130-9e60-4ba2fe68ff48.svg'
              alt: 'Clade Image'

          $p do
            id: 'description'
            "The origin of life began approximately 3.6-3.8 billion years ago."

      $div do
        id: 'breadcrumbs'

      $div do
        id: 'tree_container'
