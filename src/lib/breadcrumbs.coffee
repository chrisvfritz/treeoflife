module.exports = class Breadcrumbs

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
      .attr 'transform', "translate(#{@width / 2},#{@vertical_padding / 2})"
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
      .projection (d) =>
        [d.x, @height + @height_of_home_icon - d.y]

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
        "translate(#{@width / 2}, #{@height_of_home_icon})"
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
      .attr 'transform', (d) =>
        "translate(#{d.x},#{@height + @height_of_home_icon - d.y})"
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
