// Generated by CoffeeScript 1.8.0
(function() {
  window.onload = function() {
    var args;
    args = top.tinymce.activeEditor.windowManager.getParams();
    if (args.fsName) {
      setFileSystemName(args.fsName);
    }
    if (args.mode) {
      return setTimeout((function() {
        return setFileBrowserMode(args.mode);
      }), 0);
    }
  };

}).call(this);

//# sourceMappingURL=tinymcedialog-solo.js.map
