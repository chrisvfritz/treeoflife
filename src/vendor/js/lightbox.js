/*!
 * Lightbox v2.8.1
 * by Lokesh Dhakar
 *
 * More info:
 * http://lokeshdhakar.com/projects/lightbox2/
 *
 * Copyright 2007, 2015 Lokesh Dhakar
 * Released under the MIT license
 * https://github.com/lokesh/lightbox2/blob/master/LICENSE
 */

// Uses Node, AMD or browser globals to create a module.
(function (root, factory) {
    if (typeof define === 'function' && define.amd) {
        // AMD. Register as an anonymous module.
        define(['jquery'], factory);
    } else if (typeof exports === 'object') {
        // Node. Does not work with strict CommonJS, but
        // only CommonJS-like environments that support module.exports,
        // like Node.
        module.exports = factory(require('jquery'));
    } else {
        // Browser globals (root is window)
        root.lightbox = factory(root.jQuery);
    }
}(this, function (jQuery) {

  function Lightbox(options) {
    this.album = [];
    this.currentImageIndex = void 0;
    this.init();

    // options
    this.options = jQuery.extend({}, this.constructor.defaults);
    this.option(options);
  }

  // Descriptions of all options available on the demo site:
  // http://lokeshdhakar.com/projects/lightbox2/index.html#options
  Lightbox.defaults = {
    albumLabel: 'Image %1 of %2',
    alwaysShowNavOnTouchDevices: false,
    fadeDuration: 500,
    fitImagesInViewport: true,
    // maxWidth: 800,
    // maxHeight: 600,
    positionFromTop: 50,
    resizeDuration: 700,
    showImageNumberLabel: true,
    wrapAround: false
  };

  Lightbox.prototype.option = function(options) {
    jQuery.extend(this.options, options);
  };

  Lightbox.prototype.imageCountLabel = function(currentImageNum, totalImages) {
    return this.options.albumLabel.replace(/%1/g, currentImageNum).replace(/%2/g, totalImages);
  };

  Lightbox.prototype.init = function() {
    this.enable();
    this.build();
  };

  // Loop through anchors and areamaps looking for either data-lightbox attributes or rel attributes
  // that contain 'lightbox'. When these are clicked, start lightbox.
  Lightbox.prototype.enable = function() {
    var self = this;
    jQuery('body').on('click', 'a[rel^=lightbox], area[rel^=lightbox], a[data-lightbox], area[data-lightbox]', function(event) {
      self.start(jQuery(event.currentTarget));
      return false;
    });
  };

  // Build html for the lightbox and the overlay.
  // Attach event handlers to the new DOM elements. click click click
  Lightbox.prototype.build = function() {
    var self = this;
    jQuery("<div id='lightboxOverlay' class='lightboxOverlay'></div><div id='lightbox' class='lightbox'><div class='lb-dataContainer'><div class='lb-data'><div class='lb-details'><span class='lb-caption'></span><span class='lb-number'></span></div><div class='lb-closeContainer'><a class='lb-close'></a></div></div></div><div class='lb-outerContainer'><div class='lb-container'><img class='lb-image' src='' /><div class='lb-nav'><a class='lb-prev' href='' ></a><a class='lb-next' href='' ></a></div><div class='lb-loader'><a class='lb-cancel'></a></div></div></div></div>").appendTo(jQuery('body'));

    // Cache jQuery objects
    this.jQuerylightbox       = jQuery('#lightbox');
    this.jQueryoverlay        = jQuery('#lightboxOverlay');
    this.jQueryouterContainer = this.jQuerylightbox.find('.lb-outerContainer');
    this.jQuerycontainer      = this.jQuerylightbox.find('.lb-container');

    // Store css values for future lookup
    this.containerTopPadding = parseInt(this.jQuerycontainer.css('padding-top'), 10);
    this.containerRightPadding = parseInt(this.jQuerycontainer.css('padding-right'), 10);
    this.containerBottomPadding = parseInt(this.jQuerycontainer.css('padding-bottom'), 10);
    this.containerLeftPadding = parseInt(this.jQuerycontainer.css('padding-left'), 10);

    // Attach event handlers to the newly minted DOM elements
    this.jQueryoverlay.hide().on('click', function() {
      self.end();
      return false;
    });

    this.jQuerylightbox.hide().on('click', function(event) {
      if (jQuery(event.target).attr('id') === 'lightbox') {
        self.end();
      }
      return false;
    });

    this.jQueryouterContainer.on('click', function(event) {
      if (jQuery(event.target).attr('id') === 'lightbox') {
        self.end();
      }
      return false;
    });

    this.jQuerylightbox.find('.lb-prev').on('click', function() {
      if (self.currentImageIndex === 0) {
        self.changeImage(self.album.length - 1);
      } else {
        self.changeImage(self.currentImageIndex - 1);
      }
      return false;
    });

    this.jQuerylightbox.find('.lb-next').on('click', function() {
      if (self.currentImageIndex === self.album.length - 1) {
        self.changeImage(0);
      } else {
        self.changeImage(self.currentImageIndex + 1);
      }
      return false;
    });

    this.jQuerylightbox.find('.lb-loader, .lb-close').on('click', function() {
      self.end();
      return false;
    });
  };

  // Show overlay and lightbox. If the image is part of a set, add siblings to album array.
  Lightbox.prototype.start = function(jQuerylink) {
    var self    = this;
    var jQuerywindow = jQuery(window);

    jQuerywindow.on('resize', jQuery.proxy(this.sizeOverlay, this));

    jQuery('select, object, embed').css({
      visibility: 'hidden'
    });

    this.sizeOverlay();

    this.album = [];
    var imageNumber = 0;

    function addToAlbum(jQuerylink) {
      self.album.push({
        link: jQuerylink.attr('href'),
        title: jQuerylink.attr('data-title') || jQuerylink.attr('title')
      });
    }

    // Support both data-lightbox attribute and rel attribute implementations
    var dataLightboxValue = jQuerylink.attr('data-lightbox');
    var jQuerylinks;

    if (dataLightboxValue) {
      jQuerylinks = jQuery(jQuerylink.prop('tagName') + '[data-lightbox="' + dataLightboxValue + '"]');
      for (var i = 0; i < jQuerylinks.length; i = ++i) {
        addToAlbum(jQuery(jQuerylinks[i]));
        if (jQuerylinks[i] === jQuerylink[0]) {
          imageNumber = i;
        }
      }
    } else {
      if (jQuerylink.attr('rel') === 'lightbox') {
        // If image is not part of a set
        addToAlbum(jQuerylink);
      } else {
        // If image is part of a set
        jQuerylinks = jQuery(jQuerylink.prop('tagName') + '[rel="' + jQuerylink.attr('rel') + '"]');
        for (var j = 0; j < jQuerylinks.length; j = ++j) {
          addToAlbum(jQuery(jQuerylinks[j]));
          if (jQuerylinks[j] === jQuerylink[0]) {
            imageNumber = j;
          }
        }
      }
    }

    // Position Lightbox
    var top  = jQuerywindow.scrollTop() + this.options.positionFromTop;
    var left = jQuerywindow.scrollLeft();
    this.jQuerylightbox.css({
      top: top + 'px',
      left: left + 'px'
    }).fadeIn(this.options.fadeDuration);

    this.changeImage(imageNumber);
  };

  // Hide most UI elements in preparation for the animated resizing of the lightbox.
  Lightbox.prototype.changeImage = function(imageNumber) {
    var self = this;

    this.disableKeyboardNav();
    var jQueryimage = this.jQuerylightbox.find('.lb-image');

    this.jQueryoverlay.fadeIn(this.options.fadeDuration);

    jQuery('.lb-loader').fadeIn('slow');
    this.jQuerylightbox.find('.lb-image, .lb-nav, .lb-prev, .lb-next, .lb-dataContainer, .lb-numbers, .lb-caption').hide();

    this.jQueryouterContainer.addClass('animating');

    // When image to show is preloaded, we send the width and height to sizeContainer()
    var preloader = new Image();
    preloader.onload = function() {
      var jQuerypreloader;
      var imageHeight;
      var imageWidth;
      var maxImageHeight;
      var maxImageWidth;
      var windowHeight;
      var windowWidth;

      jQueryimage.attr('src', self.album[imageNumber].link);

      jQuerypreloader = jQuery(preloader);

      jQueryimage.width(preloader.width);
      jQueryimage.height(preloader.height);

      if (self.options.fitImagesInViewport) {
        // Fit image inside the viewport.
        // Take into account the border around the image and an additional 10px gutter on each side.

        windowWidth    = jQuery(window).width();
        windowHeight   = jQuery(window).height();
        maxImageWidth  = windowWidth - self.containerLeftPadding - self.containerRightPadding - 20;
        maxImageHeight = windowHeight - self.containerTopPadding - self.containerBottomPadding - 120;

        // Check if image size is larger then maxWidth|maxHeight in settings
        if (self.options.maxWidth && self.options.maxWidth < maxImageWidth) {
          maxImageWidth = self.options.maxWidth;
        }
        if (self.options.maxHeight && self.options.maxHeight < maxImageWidth) {
          maxImageHeight = self.options.maxHeight;
        }

        // Is there a fitting issue?
        if ((preloader.width > maxImageWidth) || (preloader.height > maxImageHeight)) {
          if ((preloader.width / maxImageWidth) > (preloader.height / maxImageHeight)) {
            imageWidth  = maxImageWidth;
            imageHeight = parseInt(preloader.height / (preloader.width / imageWidth), 10);
            jQueryimage.width(imageWidth);
            jQueryimage.height(imageHeight);
          } else {
            imageHeight = maxImageHeight;
            imageWidth = parseInt(preloader.width / (preloader.height / imageHeight), 10);
            jQueryimage.width(imageWidth);
            jQueryimage.height(imageHeight);
          }
        }
      }
      self.sizeContainer(jQueryimage.width(), jQueryimage.height());
    };

    preloader.src          = this.album[imageNumber].link;
    this.currentImageIndex = imageNumber;
  };

  // Stretch overlay to fit the viewport
  Lightbox.prototype.sizeOverlay = function() {
    this.jQueryoverlay
      .width(jQuery(window).width())
      .height(jQuery(document).height());
  };

  // Animate the size of the lightbox to fit the image we are showing
  Lightbox.prototype.sizeContainer = function(imageWidth, imageHeight) {
    var self = this;

    var oldWidth  = this.jQueryouterContainer.outerWidth();
    var oldHeight = this.jQueryouterContainer.outerHeight();
    var newWidth  = imageWidth + this.containerLeftPadding + this.containerRightPadding;
    var newHeight = imageHeight + this.containerTopPadding + this.containerBottomPadding;

    function postResize() {
      self.jQuerylightbox.find('.lb-dataContainer').width(newWidth);
      self.jQuerylightbox.find('.lb-prevLink').height(newHeight);
      self.jQuerylightbox.find('.lb-nextLink').height(newHeight);
      self.showImage();
    }

    if (oldWidth !== newWidth || oldHeight !== newHeight) {
      this.jQueryouterContainer.animate({
        width: newWidth,
        height: newHeight
      }, this.options.resizeDuration, 'swing', function() {
        postResize();
      });
    } else {
      postResize();
    }
  };

  // Display the image and its details and begin preload neighboring images.
  Lightbox.prototype.showImage = function() {
    this.jQuerylightbox.find('.lb-loader').stop(true).hide();
    this.jQuerylightbox.find('.lb-image').fadeIn('slow');

    this.updateNav();
    this.updateDetails();
    this.preloadNeighboringImages();
    this.enableKeyboardNav();
  };

  // Display previous and next navigation if appropriate.
  Lightbox.prototype.updateNav = function() {
    // Check to see if the browser supports touch events. If so, we take the conservative approach
    // and assume that mouse hover events are not supported and always show prev/next navigation
    // arrows in image sets.
    var alwaysShowNav = false;
    try {
      document.createEvent('TouchEvent');
      alwaysShowNav = (this.options.alwaysShowNavOnTouchDevices) ? true : false;
    } catch (e) {}

    this.jQuerylightbox.find('.lb-nav').show();

    if (this.album.length > 1) {
      if (this.options.wrapAround) {
        if (alwaysShowNav) {
          this.jQuerylightbox.find('.lb-prev, .lb-next').css('opacity', '1');
        }
        this.jQuerylightbox.find('.lb-prev, .lb-next').show();
      } else {
        if (this.currentImageIndex > 0) {
          this.jQuerylightbox.find('.lb-prev').show();
          if (alwaysShowNav) {
            this.jQuerylightbox.find('.lb-prev').css('opacity', '1');
          }
        }
        if (this.currentImageIndex < this.album.length - 1) {
          this.jQuerylightbox.find('.lb-next').show();
          if (alwaysShowNav) {
            this.jQuerylightbox.find('.lb-next').css('opacity', '1');
          }
        }
      }
    }
  };

  // Display caption, image number, and closing button.
  Lightbox.prototype.updateDetails = function() {
    var self = this;

    // Enable anchor clicks in the injected caption html.
    // Thanks Nate Wright for the fix. @https://github.com/NateWr
    if (typeof this.album[this.currentImageIndex].title !== 'undefined' &&
      this.album[this.currentImageIndex].title !== '') {
      this.jQuerylightbox.find('.lb-caption')
        .html(this.album[this.currentImageIndex].title)
        .fadeIn('fast')
        .find('a').on('click', function(event) {
          if (jQuery(this).attr('target') !== undefined) {
            window.open(jQuery(this).attr('href'), jQuery(this).attr('target'));
          } else {
            location.href = jQuery(this).attr('href');
          }
        });
    }

    if (this.album.length > 1 && this.options.showImageNumberLabel) {
      var labelText = this.imageCountLabel(this.currentImageIndex + 1, this.album.length);
      this.jQuerylightbox.find('.lb-number').text(labelText).fadeIn('fast');
    } else {
      this.jQuerylightbox.find('.lb-number').hide();
    }

    this.jQueryouterContainer.removeClass('animating');

    this.jQuerylightbox.find('.lb-dataContainer').fadeIn(this.options.resizeDuration, function() {
      return self.sizeOverlay();
    });
  };

  // Preload previous and next images in set.
  Lightbox.prototype.preloadNeighboringImages = function() {
    if (this.album.length > this.currentImageIndex + 1) {
      var preloadNext = new Image();
      preloadNext.src = this.album[this.currentImageIndex + 1].link;
    }
    if (this.currentImageIndex > 0) {
      var preloadPrev = new Image();
      preloadPrev.src = this.album[this.currentImageIndex - 1].link;
    }
  };

  Lightbox.prototype.enableKeyboardNav = function() {
    jQuery(document).on('keyup.keyboard', jQuery.proxy(this.keyboardAction, this));
  };

  Lightbox.prototype.disableKeyboardNav = function() {
    jQuery(document).off('.keyboard');
  };

  Lightbox.prototype.keyboardAction = function(event) {
    var KEYCODE_ESC        = 27;
    var KEYCODE_LEFTARROW  = 37;
    var KEYCODE_RIGHTARROW = 39;

    var keycode = event.keyCode;
    var key     = String.fromCharCode(keycode).toLowerCase();
    if (keycode === KEYCODE_ESC || key.match(/x|o|c/)) {
      this.end();
    } else if (key === 'p' || keycode === KEYCODE_LEFTARROW) {
      if (this.currentImageIndex !== 0) {
        this.changeImage(this.currentImageIndex - 1);
      } else if (this.options.wrapAround && this.album.length > 1) {
        this.changeImage(this.album.length - 1);
      }
    } else if (key === 'n' || keycode === KEYCODE_RIGHTARROW) {
      if (this.currentImageIndex !== this.album.length - 1) {
        this.changeImage(this.currentImageIndex + 1);
      } else if (this.options.wrapAround && this.album.length > 1) {
        this.changeImage(0);
      }
    }
  };

  // Closing time. :-(
  Lightbox.prototype.end = function() {
    this.disableKeyboardNav();
    jQuery(window).off('resize', this.sizeOverlay);
    this.jQuerylightbox.fadeOut(this.options.fadeDuration);
    this.jQueryoverlay.fadeOut(this.options.fadeDuration);
    jQuery('select, object, embed').css({
      visibility: 'visible'
    });
  };

  return new Lightbox();
}));
