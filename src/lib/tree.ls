# require! {
#   './breadcrumbs.coffee': Breadcrumbs
# }


module.exports = class Tree

  get_json_data: ->

    @breadcrumbs = new Breadcrumbs(@, root)
    @update root

  update: (source) ->

    ensure_collapsed_cluster-roots = (node) ->
      if node.cluster-root and node.children
        node._children = node.children
        node.children = null
      if node.children
        node.children.forEach ensure_collapsed_cluster-roots
      else if node._children
        node._children.forEach ensure_collapsed_cluster-roots

    source.children.forEach ensure_collapsed_cluster-roots

    @breadcrumbs.update source

    default-node-radius = @default-node-radius
    diagonal            = @diagonal

    # Compute the new tree layout.
    nodes = @tree.nodes(source).reverse()
    links = @tree.links @tree.nodes(source).reverse()

    origin = nodes.filter (d) -> d.name == 'Origin of Life'
    eukarya = nodes.filter (d) -> d.name == 'Eukarya'
    archaea = nodes.filter (d) -> d.name == 'Archaea'

    jQueryfake_link = jQuery('.fake_link')

    if jQueryfake_link.length > 0 and origin.length is 0
      jQueryfake_link.fadeOut @transition-duration / 4, ->
        jQueryfake_link.remove()

    if eukarya.length > 0 and archaea.length > 0

      @svg.insert 'path', ':first-child'
        .attr 'class', 'fake_link'
        .attr 'd', ->
          o =
            x: origin[0].x0
            y: origin[0].y0
          diagonal do
            source: o
            target: o
        .transition()
          .duration @transition-duration
        .attr 'd', ->
          o =
            x: archaea[0].x
            y: archaea[0].y
          d =
            x: eukarya[0].x
            y: eukarya[0].y
          diagonal do
            source: o
            target: d

    # for node in nodes
    #   if node.cluster-root && node.children
    #     node._children = node.children
    #     node.children = null

    # nodes.forEach (d) ->
    #   d.y = d.y + d.weight * 2

    # Update the nodes…
    node_elements = @svg.selectAll 'g.node'
      .data nodes, (d) ->
        d.id

    tooltip = d3.select('body').append 'div'
      .attr 'class', 'tooltip'
      .style 'z-index', 10
      .style 'visibility', 'hidden'
      .style 'background', '#9BA09B'
      .style 'padding', '0 20px'
      .style 'max-width', ->
        (jQuery('#tree-container').outerWidth() - 40) + 'px'

    #  Enter any new nodes at the parent's previous position.
    nodes_entering = node_elements.enter().append 'g'
      .attr 'class', 'node'
      .attr 'transform', (d) ~>
        "translate(#{source.x0},#{@height - source.y0})"
      .style 'opacity', 0
      .on 'mouseover', (d) ~>
        tooltip
          .text d.name
          .style 'visibility', 'visible'
          .style 'top', (@height - d.y + 36 ) + 'px'
          .style 'right', ~>
            if d.name in ['Origin of Life', 'Bacteria', 'Archaea', 'Eukarya']
              (@width - d.x + 165) + 'px'
            else
              (@width - d.x + 140) + 'px'
          .style 'line-height', @default-node-radius * 2 + 'px'
      .on 'mouseleave', ->
        tooltip.style 'visibility', 'hidden'

    hover_timeout = undefined
    svg = @svg
    default-node-radius = @default-node-radius
    default_stroke_width = @default_stroke_width
    on_node_click = @on_node_click
    nodes_entering.append 'circle'
      .attr 'r', default-node-radius
      .attr 'class', (d) ->
        "#{d.group} #{'wobble' if d.cluster-root}"
      .style 'fill', '#1E1E1E'
      .style 'stroke', '#1E1E1E'
      .style 'fill-opacity', 0
      .style 'stroke-opacity', 0
      .style 'stroke-width', default_stroke_width
      .on 'click', (d) ->
        clearTimeout hover_timeout
        tooltip.style 'visibility', 'hidden' if d.cluster-root
        on_node_click d, @
      .on 'mouseover', (d) ->
        current_node = @
        jQuerycurrent_node = jQuery(current_node).parent('g')
        jQuerycontainer = jQuerycurrent_node.parent()
        jQuerycurrent_node.detach()
        jQuerycontainer.append jQuerycurrent_node
        # hover_timeout = setTimeout(->
        #   unless d.cluster-root or 'selected' in d3.select(current_node)[0][0].classList
        #     svg.append 'circle'
        #       .attr 'class', "ripple #{d.group}"
        #       .attr 'cx', d.x
        #       .attr 'cy', d.y
        #       .attr 'r', ->
        #         if d.name in ['Origin of Life', 'Bacteria', 'Archaea', 'Eukarya']
        #           default-node-radius * 2 - 2
        #         else
        #           default-node-radius - 1
        #       .style 'stroke-width', 5
        #       .transition()
        #         .duration 500
        #         .ease 'quad-in'
        #       .attr 'r', ->
        #         if d.name in ['Origin of Life', 'Bacteria', 'Archaea', 'Eukarya']
        #           100
        #         else
        #           50
        #       .style 'stroke-width', 0
        #       .style 'stroke-opacity', 0
        #       .each 'end', ->
        #         d3.select(@).remove()
        #   tooltip.style 'visibility', 'hidden' if d.cluster-root
        #   on_node_click d, current_node
        # , 1500)
      .on 'mouseleave', (d) ->
        clearTimeout hover_timeout
      # .on 'mouseenter', (d) ->
      #   jQuery('#name').text d.name
      #   jQuery('#image').find('img').attr 'src', d.image
      #   jQuery('#description').text d.desc || ''
      #   return false
      # .on 'mouseleave', (d) ->
      #   if d.cluster-root
      #     search_for_parent_cluster = (d) ->
      #       return d unless d.parent
      #       return d.parent if d.parent.cluster-root || !d.parent.parent
      #       search_for_parent_cluster d.parent
      #     jQuery('#name').text search_for_parent_cluster(d).name
      #   else
      #     jQuery('#name').text source.name
      #   return false

    # Transition nodes to their new position.
    nodes_being_positioned = node_elements.transition()
      .duration @transition-duration
      .attr 'transform', (d) ~>
        "translate(#{d.x},#{@height - d.y})"
      .style 'opacity', 1

    nodes_being_positioned.select 'circle'
      .attr 'r', (d) ->
        if d.name in ['Origin of Life', 'Bacteria', 'Archaea', 'Eukarya']
          default-node-radius * 2
        else
          default-node-radius
      .style 'fill', (d) ->
        # if d._children then 'lightsteelblue' else '#1E1E1E'
        '#1E1E1E'
      .style 'stroke', (d) ->
        switch d.group
          when 'archaea'  then '#9F8B51'
          when 'eukarya'  then '#33748E'
          when 'bacteria' then '#257D3F'
          when 'origin'   then 'white'
      .style 'fill-opacity', 1
      .style 'stroke-opacity', 1

    # Transition exiting nodes to the parent's new position.
    nodes_exiting = node_elements.exit().transition()
      .duration @transition-duration / 4
      .style 'opacity', 0
      # .attr 'transform', (d) ->
      #   "translate(#{source.y},#{source.x})"
      .remove()

    nodes_exiting.select 'circle'
      .attr 'r', 1e-6
      .style 'stroke-opacity', 0

    # Update the links…
    link = @svg.selectAll 'path.link'
      .data links, (d) ->
        "#{d.source.id}->#{d.target.id}"

    # Enter any new links at the parent's previous position.
    link.enter().insert 'path', 'g'
      .attr 'class', 'link'
      .attr 'd', (d) ->
        o =
          x: source.x0
          y: source.y0
        diagonal do
          source: o
          target: o

    # Transition links to their new position.
    link.transition()
      .duration @transition-duration
      .attr 'd', diagonal

    # Transition exiting nodes to the parent's new position.
    link.exit().transition()
      .duration @transition-duration / 4
      .style 'opacity', 0
      .remove()

    # Stash the old positions for transition.
    for d in nodes
      d.x0 = d.x
      d.y0 = d.y

  update_sidebar: (node) ->
    jQuerysidebar = jQuery('#sidebar .scroll_area')
    jQuerysidebar.fadeOut 250, ->
      @jq-name = jQuery('#name')
      @jq-name.text node.name
      @jq-name.unwrap() if @jq-name.parent('a').length > 0
      @jq-name.wrap """
        <a href="http://eol.org/search?q=#{node.name.split(/\s+/).join('+')}&search=Go" target="_blank"></a>
      """
      jQuery('#image').find('img').attr 'src', node.image
      jQuery('#description').text node.desc || ''
    jQuerysidebar.fadeIn 250

    set_eol_link = (name) ~>
      jQuery.get("").done (data) ->

  triggering_node = false
  on_node_click: (node, current_node) ~>

    node_trigger = ~>
      triggering_node = true

      current_class_list = d3.select(current_node)[0][0].classList
      current_is_selected = 'selected' in current_class_list
      unless current_is_selected
        d3.selectAll('circle')[0].forEach (node) ->
          node.classList.remove 'selected'
        current_class_list.add 'selected'
        @update_sidebar node

      search_for_parent_cluster = (d) ~>
        if d.parent.cluster-root || !d.parent.parent
          @update d.parent
        else
          search_for_parent_cluster d.parent

      if node.cluster-root
        if node.children
          node.children = null
          node.parent   = node._parent
          search_for_parent_cluster node
        else
          node.children = node._children
          node._parent  = node.parent
          node.parent   = null
          @update node

    node_trigger() unless triggering_node

    setTimeout ->
      triggering_node = false
    , @transition-duration / 2


  render: ~>

    @get_json_data()
