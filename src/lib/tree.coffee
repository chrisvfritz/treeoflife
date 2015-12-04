window.TreeOfLife = {}

class TreeOfLife.Tree

  constructor: ->
    @jQuerydoc            = jQuery(document)
    @jQuerywin            = jQuery(window)
    @jQuerybody           = jQuery('body')
    @jQuerytree_container = jQuery('#tree_container')

    @fade_in_after       = 1000
    @transition_duration = 1000

    @default_node_radius = 25
    @default_stroke_width = 2
    @default_max_stroke_width = 4

    # COLORS
    @colors =
      node:             '#9BA09B'
      path:             '#9BA09B'
      path_highlighted: 'orange'

    @setup_render_area()

    jQuery(window).on 'resize', ->
      window.location.href = window.location.href

  setup_render_area: =>

    default_node_radius = @default_node_radius
    default_max_stroke_width = @default_max_stroke_width
    stroke_width = @default_stroke_width
    update = @update

    margin =
      top:    default_node_radius * 2 + stroke_width + default_max_stroke_width
      right:  default_node_radius + stroke_width + default_max_stroke_width
      bottom: default_node_radius * 2 + stroke_width + default_max_stroke_width
      left:   default_node_radius + stroke_width + default_max_stroke_width

    @width  = @jQuerytree_container.width() - margin.left - margin.right
    @height = @jQuerywin.height()           - margin.top  - margin.bottom - 5

    @tree = d3.layout.cluster()
      .size [@width, @height]
      .separation (a,b) ->
        # extra = (if a.parent == b.parent then 50 else 100)
        # a.weight + b.weight + default_node_radius + extra
        if a.name in ['Origin of Life', 'Bacteria', 'Archaea', 'Eukarya'] or b.name in ['Origin of Life', 'Bacteria', 'Archaea', 'Eukarya']
          3
        else
          if a.parent is b.parent then 1 else 2


    @diagonal = d3.svg.diagonal().projection (d) ->
      [d.x, d.y]

    console.log @width
    @svg = d3.select('#tree_container').append 'svg'
      .attr 'width',  @width  + margin.right + margin.left
      .attr 'height', @height + margin.top   + margin.bottom
      .append 'g'
        .attr 'transform', "translate(#{margin.left},#{margin.top})"

  get_json_data: =>

    # bubble_up_weights = (node) ->
    #   if (children = (if node.children then node.children else node._children)) && children.length != 0
    #     bubble_up_weights(child) for child in children
    #     node.weight = (child.weight for child in children).reduce (a,b) -> a/1.3 + b/1.3
    #     node.total_children = children.length + children.reduce (a,b) -> a.total_children + b.total_children
    #   else
    #     node.weight = 10
    #     node.total_children = 0

    # bubble_up_weights root
    root = CONFIG.treeData

    i = 0
    root.id = ++i

    trickle_down_preprocessing = (node) ->
      node.id = ++i

      if node.children

        node.children.forEach (child) ->
          child.group ||= node.group
          child.image ||= node.image

        if node.cluster_root
          node._children = node.children
          node.children  = null
          node._children.forEach trickle_down_preprocessing
        else
          node.children.forEach trickle_down_preprocessing

    trickle_down_preprocessing root

    root.x0 = @width / 2
    root.y0 = 0

    @breadcrumbs = new TreeOfLife.Breadcrumbs(@, root)
    @update root

  update: (source) =>

    ensure_collapsed_cluster_roots = (node) ->
      if node.cluster_root and node.children
        node._children = node.children
        node.children = null
      if node.children
        node.children.forEach ensure_collapsed_cluster_roots
      else if node._children
        node._children.forEach ensure_collapsed_cluster_roots

    source.children.forEach ensure_collapsed_cluster_roots

    @breadcrumbs.update source

    default_node_radius = @default_node_radius
    diagonal            = @diagonal

    # Compute the new tree layout.
    nodes = @tree.nodes(source).reverse()
    links = @tree.links @tree.nodes(source).reverse()

    origin = nodes.filter (d) -> d.name == 'Origin of Life'
    eukarya = nodes.filter (d) -> d.name == 'Eukarya'
    archaea = nodes.filter (d) -> d.name == 'Archaea'

    jQueryfake_link = jQuery('.fake_link')

    if jQueryfake_link.length > 0 and origin.length is 0
      jQueryfake_link.fadeOut @transition_duration / 4, ->
        jQueryfake_link.remove()

    if eukarya.length > 0 and archaea.length > 0

      @svg.insert 'path', ':first-child'
        .attr 'class', 'fake_link'
        .attr 'd', ->
          o =
            x: origin[0].x0
            y: origin[0].y0
          diagonal
            source: o
            target: o
        .transition()
          .duration @transition_duration
        .attr 'd', ->
          o =
            x: archaea[0].x
            y: archaea[0].y
          d =
            x: eukarya[0].x
            y: eukarya[0].y
          diagonal
            source: o
            target: d

    # for node in nodes
    #   if node.cluster_root && node.children
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
        (jQuery('#tree_container').outerWidth() - 40) + 'px'

    #  Enter any new nodes at the parent's previous position.
    nodes_entering = node_elements.enter().append 'g'
      .attr 'class', 'node'
      .attr 'transform', (d) ->
        "translate(#{source.x0},#{source.y0})"
      .style 'opacity', 0
      .on 'mouseover', (d) =>
        tooltip
          .text d.name
          .style 'visibility', 'visible'
          .style 'top', (@height - d.y + 36 ) + 'px'
          .style 'right', =>
            if d.name in ['Origin of Life', 'Bacteria', 'Archaea', 'Eukarya']
              (@width - d.x + 165) + 'px'
            else
              (@width - d.x + 140) + 'px'
          .style 'line-height', @default_node_radius * 2 + 'px'
      .on 'mouseleave', ->
        tooltip.style 'visibility', 'hidden'

    hover_timeout = undefined
    svg = @svg
    default_node_radius = @default_node_radius
    default_stroke_width = @default_stroke_width
    on_node_click = @on_node_click
    nodes_entering.append 'circle'
      .attr 'r', default_node_radius
      .attr 'class', (d) ->
        "#{d.group} #{'wobble' if d.cluster_root}"
      .style 'fill', '#1E1E1E'
      .style 'stroke', '#1E1E1E'
      .style 'fill-opacity', 0
      .style 'stroke-opacity', 0
      .style 'stroke-width', default_stroke_width
      .on 'click', (d) ->
        clearTimeout hover_timeout
        tooltip.style 'visibility', 'hidden' if d.cluster_root
        on_node_click d, @
      .on 'mouseover', (d) ->
        current_node = @
        jQuerycurrent_node = jQuery(current_node).parent('g')
        jQuerycontainer = jQuerycurrent_node.parent()
        jQuerycurrent_node.detach()
        jQuerycontainer.append jQuerycurrent_node
        # hover_timeout = setTimeout(->
        #   unless d.cluster_root or 'selected' in d3.select(current_node)[0][0].classList
        #     svg.append 'circle'
        #       .attr 'class', "ripple #{d.group}"
        #       .attr 'cx', d.x
        #       .attr 'cy', d.y
        #       .attr 'r', ->
        #         if d.name in ['Origin of Life', 'Bacteria', 'Archaea', 'Eukarya']
        #           default_node_radius * 2 - 2
        #         else
        #           default_node_radius - 1
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
        #   tooltip.style 'visibility', 'hidden' if d.cluster_root
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
      #   if d.cluster_root
      #     search_for_parent_cluster = (d) ->
      #       return d unless d.parent
      #       return d.parent if d.parent.cluster_root || !d.parent.parent
      #       search_for_parent_cluster d.parent
      #     jQuery('#name').text search_for_parent_cluster(d).name
      #   else
      #     jQuery('#name').text source.name
      #   return false

    # Transition nodes to their new position.
    nodes_being_positioned = node_elements.transition()
      .duration @transition_duration
      .attr 'transform', (d) ->
        "translate(#{d.x},#{d.y})"
      .style 'opacity', 1

    nodes_being_positioned.select 'circle'
      .attr 'r', (d) ->
        if d.name in ['Origin of Life', 'Bacteria', 'Archaea', 'Eukarya']
          default_node_radius * 2
        else
          default_node_radius
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
      .duration @transition_duration / 4
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
        diagonal
          source: o
          target: o

    # Transition links to their new position.
    link.transition()
      .duration @transition_duration
      .attr 'd', diagonal

    # Transition exiting nodes to the parent's new position.
    link.exit().transition()
      .duration @transition_duration / 4
      .style 'opacity', 0
      .remove()

    # Stash the old positions for transition.
    for d in nodes
      d.x0 = d.x
      d.y0 = d.y

  update_sidebar: (node) ->
    jQuerysidebar = jQuery('#sidebar .scroll_area')
    jQuerysidebar.fadeOut 250, ->
      @jQueryname = jQuery('#name')
      @jQueryname.text node.name
      @jQueryname.unwrap() if @jQueryname.parent('a').length > 0
      @jQueryname.wrap """
        <a href="http://eol.org/search?q=#{node.name.split(/\s+/).join('+')}&search=Go" target="_blank"></a>
      """
      jQuery('#image').find('img').attr 'src', node.image
      jQuery('#description').text node.desc || ''
    jQuerysidebar.fadeIn 250

    set_eol_link = (name) =>
      jQuery.get("").done (data) ->

  triggering_node = false
  on_node_click: (node, current_node) =>

    node_trigger = =>
      triggering_node = true

      current_class_list = d3.select(current_node)[0][0].classList
      current_is_selected = 'selected' in current_class_list
      unless current_is_selected
        d3.selectAll('circle')[0].forEach (node) ->
          node.classList.remove 'selected'
        current_class_list.add 'selected'
        @update_sidebar node

      search_for_parent_cluster = (d) =>
        if d.parent.cluster_root || !d.parent.parent
          @update d.parent
        else
          search_for_parent_cluster d.parent

      if node.cluster_root
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
    , @transition_duration / 2


  render: =>

    @get_json_data()

class TreeOfLife.Breadcrumbs

  constructor: (tree, original_source) ->

    @breadcrumps         = '#breadcrumbs'
    @jQuerybreadcrumbs   = jQuery(breadcrumbs)
    @vertical_padding    = 100
    @main_tree           = tree
    @original_source     = original_source
    @height_of_home_icon = 60

    @setup_render_area()

  setup_render_area: =>

    @width = @jQuerybreadcrumbs.width()
    @height = jQuery(window).height() - @vertical_padding - @height_of_home_icon

    @transition_duration = 1000
    @jQueryname = jQuery('#name')

    @svg = d3.select(@breadcrumps).append 'svg'
      .attr 'width', @width
      .attr 'height', @height + @vertical_padding + @height_of_home_icon

    @svg.append 'filter'
      .attr 'id', 'inverse_color_matrix'
      .append 'svg:feColorMatrix'
        .attr 'in', 'SourceGraphic'
        .attr 'type', 'matrix'
        .attr 'values', '-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 1 0'

    @svg.append 'g'
      .attr 'transform', "translate(#{@width / 2},#{@height + @height_of_home_icon + @vertical_padding / 2})"
      .append 'image'
        .attr 'x', -20
        .attr 'y', -20
        .attr 'width', '40px'
        .attr 'height', '40px'
        .attr 'xlink:href', require('../images/home.png')
        .on 'click', -> window.location.href = 'http://opentreeoflife.org/'

    @svg = @svg
      .append 'g'
        .attr 'transform', "translate(0,#{@vertical_padding / 2})"

    @tree = d3.layout.tree()
      .size [@width, @height]

    @diagonal = d3.svg.diagonal()
      .projection (d) ->
        [d.x, d.y]

  update: (source) =>

    source = jQuery.extend({}, source)

    previous_cluster_root = (node) ->
      node.children = null
      if node._parent
        node.parent = jQuery.extend({}, node._parent)
        while !node.parent.cluster_root && node.parent.parent
          node.parent = jQuery.extend({}, node.parent.parent)
        node.parent.parent = previous_cluster_root node.parent
        node.parent.children = [node]
        return node.parent
      null

    source.parent = previous_cluster_root source

    while source.parent
      source = source.parent

    nodes = @tree.nodes source

    is_current_cluster = (node) ->
      nodes.length is jQuery('.breadcrumb').length

    # Put the origin node on top when it's alone
    nodes[0].y = @height if nodes.length == 1
    links = @tree.links nodes

    tooltip = d3.select('body').append 'div'
      .attr 'class', 'tooltip'
      .style 'z-index', 10
      .style 'visibility', 'hidden'
      .style 'background', '#9BA09B'
      .style 'padding', '0 20px'
      .style 'max-width', ->
        (jQuery('#tree_container').outerWidth() - 40) + 'px'

    node_elements = @svg.selectAll 'g.breadcrumb'
      .data nodes, (d) ->
        d.id

    node_elements.select 'image'
      .attr 'class', ''

    width = @width
    height = @height
    height_of_home_icon = @height_of_home_icon
    nodes_entering = node_elements.enter().append 'g'
      .attr 'class', 'breadcrumb'
      .attr 'transform', (d) =>
        "translate(#{@width / 2}, #{@height})"
      .style 'opacity', 0
      .on 'mouseover', (d) ->
        d3.select(@).select('image').attr 'class', -> if is_current_cluster(d) then 'current_cluster' else ''
        tooltip
          .text ->
            text = d.name
            text += " (Current Cluster)" if is_current_cluster(d)
            text
          .style 'visibility', 'visible'
          .style 'top', (height + height_of_home_icon - d.y + d3.event.target.getCTM().e - 8) + 'px'
          .style 'right', width + 'px'
          .style 'line-height', d3.event.target.getBoundingClientRect().height + 'px'
          # .style 'margin-top', ->
          #   console.log -parseInt(tooltip.style('height')) / 2
          #   (-parseInt(tooltip.style('height')) / 2) + 'px'
      .on 'mouseleave', ->
        tooltip.style 'visibility', 'hidden'
      # # .on 'mousemove', ->
      #   tooltip

    nodes_entering.append 'image'
      .attr 'x', -20
      .attr 'y', -20
      .attr 'width', '40px'
      .attr 'height', '40px'
      .style 'filter', 'url(#inverse_color_matrix)'
      .attr 'xlink:href', (d) -> d.image
      .on 'click', (d) =>
        unless is_current_cluster d
          matched_node = undefined
          collapse_child_clusters = (node) ->
            if node.cluster_root && node.children
              node._children = node.children
              node.children = null
            else if node.children
              node.children.forEach collapse_child_clusters

          find_node = (node) ->
            if node.id is d.id
              matched_node = node
              matched_node.children.forEach collapse_child_clusters
              return
            node.children.forEach  find_node if node.children
            node._children.forEach find_node if node._children
          find_node @original_source
          @main_tree.update matched_node

    nodes_being_positioned = node_elements.transition()
      .duration 1000
      .attr 'transform', (d) ->
        "translate(#{d.x},#{d.y})"
      .style 'opacity', 1

    nodes_exiting = node_elements.exit().transition()
      .duration @transition_duration
      .style 'opacity', 0
      .remove()

    # Update the links…
    link = @svg.selectAll 'path.breadcrumb_link'
      .data links, (d) ->
        "#{d.source.id}->#{d.target.id}"

    # Enter any new links at the parent's previous position.
    link.enter().insert 'path', 'g'
      .attr 'class', 'breadcrumb_link'
      .attr 'd', (d) =>
        o =
          x: @width / 2
          y: @height
        @diagonal
          source: o
          target: o
      .style 'stroke', '#555'
      .style 'stroke-width', 2
      .style 'stroke-dasharray', '2, 10'

    # Transition links to their new position.
    link.transition()
      .duration @transition_duration
      .attr 'd', @diagonal

    # Transition exiting nodes to the parent's new position.
    link.exit().transition()
      .duration @transition_duration / 4
      .style 'opacity', 0
      .remove()

    # node.append 'image'
    #   .attr 'x', -30
    #   .attr 'y', -30
    #   .attr 'width', 60
    #   .attr 'height', 60
    #   .attr 'xlink:href', (d) ->
    #     "/images/#{d.image}.svg"

    # Stash the old positions for transition.
    # for d in nodes
    #   d.x0 = d.x
    #   d.y0 = d.y

module.exports = TreeOfLife.Tree
