// Generated by CoffeeScript 1.8.0
(function() {
  var __hasProp = {}.hasOwnProperty;

  window.LurchEmbed = {};

  window.LurchEmbed.defaultURL = 'http://nathancarter.github.io/weblurch/app/app.html';

  window.LurchEmbed.makeLive = function(element, attributes, applicationURL) {
    var filename, index, key, replacement, url, value;
    if (attributes == null) {
      attributes = {
        width: 800,
        height: 400
      };
    }
    if (applicationURL == null) {
      applicationURL = window.LurchEmbed.defaultURL;
    }
    filename = 'auto-load';
    if (index = element.getAttribute('data-embed-index')) {
      filename += index;
    }
    localStorage.setItem(filename, JSON.stringify([{}, element.innerHTML]));
    url = applicationURL + '?autoload=' + filename;
    replacement = element.ownerDocument.createElement('iframe');
    replacement.style.border = '1px solid black';
    for (key in attributes) {
      if (!__hasProp.call(attributes, key)) continue;
      value = attributes[key];
      replacement.setAttribute(key, value);
    }
    ($(element)).replaceWith(replacement);
    return replacement.setAttribute('src', url);
  };

  $(window.LurchEmbed.makeAllLive = function() {
    return ($('.lurch-embed')).each(function(index, element) {
      element.setAttribute('data-embed-index', index);
      return window.LurchEmbed.makeLive(element);
    });
  });

}).call(this);

//# sourceMappingURL=lurch-embed-solo.js.map
