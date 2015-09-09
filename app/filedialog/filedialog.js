// Generated by CoffeeScript 1.8.0
(function() {
  var allExtensions, askToDeleteEntry, changeFolder, clearActionLinks, fileBrowserMode, fsToBrowse, icon, imitateDialog, makeActionLink, makeTable, rowOf3, setup, tellPage, validBrowserModes,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  window.onmessage = function(e) {
    var fname;
    if (!(e.data instanceof Array)) {
      return console.log('Invalid message from page:', e.data);
    }
    fname = e.data.shift();
    if (typeof window[fname] !== 'function') {
      return console.log('Cannot call non-function:', fname);
    }
    return window[fname].apply(null, e.data);
  };

  tellPage = function(message) {
    return window.top.postMessage(message, '*');
  };

  fsToBrowse = new FileSystem('demo');

  window.setFileSystemName = function(name) {
    fsToBrowse = new FileSystem(name);
    return updateFileBrowser();
  };

  fileBrowserMode = null;

  validBrowserModes = ['manage files', 'open file', 'save file', 'open folder', 'save in folder'];

  window.setFileBrowserMode = function(mode) {
    if (__indexOf.call(validBrowserModes, mode) >= 0) {
      fileBrowserMode = mode;
    }
    return updateFileBrowser();
  };

  window.fileBeingMoved = {};

  window.fileToBeOpened = null;

  window.selectFile = function(name) {
    window.fileToBeOpened = name;
    tellPage(['selectedFile', name]);
    return updateFileBrowser();
  };

  changeFolder = function(destination) {
    fsToBrowse.cd(destination);
    tellPage(['changedFolder', fsToBrowse.getCwd()]);
    return selectFile(null);
  };

  imitateDialog = false;

  window.setDialogImitation = function(enable) {
    if (enable == null) {
      enable = true;
    }
    imitateDialog = !!enable;
    return updateFileBrowser();
  };

  window.buttonClicked = function(name) {
    var args, folderName, path, success;
    if (name === 'New folder') {
      folderName = prompt('Enter name of new folder', 'My Folder');
      if (fsToBrowse.mkdir(folderName)) {
        updateFileBrowser();
      } else {
        alert('That folder name is already in use.');
      }
      return;
    }
    args = [];
    if (name === 'Save') {
      path = fsToBrowse.getCwd();
      if (path.slice(-1) !== FileSystem.prototype.pathSeparator) {
        path += FileSystem.prototype.pathSeparator;
      }
      args.push(path + saveFileName.value);
      if (fileBeingMoved.name) {
        args.unshift(fileBeingMoved.full);
        if (fileBeingMoved.copy) {
          success = fsToBrowse.cp(fileBeingMoved.full, path + saveFileName.value);
          name = success ? 'Copied' : 'Copy failed';
        } else {
          success = fsToBrowse.mv(fileBeingMoved.full, path + saveFileName.value);
          name = success ? 'Moved' : 'Move failed';
        }
      }
    }
    if (name === 'Save here') {
      args.push(fsToBrowse.getCwd());
    }
    if (name === 'Open') {
      path = fsToBrowse.getCwd();
      if (path.slice(-1) !== FileSystem.prototype.pathSeparator) {
        path += FileSystem.prototype.pathSeparator;
      }
      args.push(path + fileToBeOpened);
    }
    if (name === 'Open this folder') {
      args.push(fsToBrowse.getCwd());
      name = 'Open folder';
    }
    tellPage(['buttonClicked', name].concat(args));
    window.fileBeingMoved = {};
    selectFile(null);
    return setFileBrowserMode('manage files');
  };

  window.onload = setup = function() {
    setFileBrowserMode('manage files');
    return changeFolder('.');
  };

  askToDeleteEntry = function(entry) {
    if (confirm("Are you sure you want to permantely delete " + entry + "?")) {
      fsToBrowse.rm(entry);
      return updateFileBrowser();
    }
  };

  window.updateFileBrowser = function() {
    var I, T, X, action, buttons, disable, e, entries, entry, extensions, features, file, filter, folder, index, interior, oldIndex, oldName, path, statusbar, text, title, titlebar, _i, _j, _k, _len, _len1, _len2, _ref, _ref1;
    features = {
      navigateFolders: true,
      deleteFolders: true,
      deleteFiles: true,
      createFolders: true,
      fileNameTextBox: false,
      filesDisabled: false,
      moveFiles: true,
      moveFolders: true,
      copyFiles: true,
      extensionFilter: false,
      selectFile: false
    };
    title = fileBrowserMode ? fileBrowserMode[0].toUpperCase() + fileBrowserMode.slice(1) : '';
    buttons = [];
    if (fileBrowserMode === 'manage files') {
      buttons = ['New folder', 'Done'];
    } else if (fileBrowserMode === 'save file') {
      features.deleteFolders = features.deleteFiles = features.moveFiles = features.moveFolders = features.copyFiles = false;
      features.fileNameTextBox = true;
      title = 'Save as...';
      buttons = ['Cancel', 'Save'];
      if (imitateDialog) {
        buttons.unshift('New folder');
      }
    } else if (fileBrowserMode === 'save in folder') {
      features.deleteFolders = features.deleteFiles = features.moveFiles = features.moveFolders = features.copyFiles = false;
      features.filesDisabled = true;
      title = 'Save in...';
      buttons = ['New folder', 'Cancel', 'Save here'];
    } else if (fileBrowserMode === 'open file') {
      features.deleteFolders = features.deleteFiles = features.moveFiles = features.moveFolders = features.copyFiles = false;
      features.extensionFilter = features.selectFile = true;
      buttons = ['Cancel', 'Open'];
    } else if (fileBrowserMode === 'open folder') {
      features.deleteFolders = features.deleteFiles = features.moveFiles = features.moveFolders = features.copyFiles = false;
      features.filesDisabled = true;
      buttons = ['Cancel', 'Open this folder'];
    }
    entries = [];
    if (fsToBrowse.getCwd() !== FileSystem.prototype.pathSeparator) {
      I = icon('up-arrow');
      T = 'Parent folder';
      if (features.navigateFolders) {
        action = function() {
          return changeFolder('..');
        };
        I = makeActionLink(I, 'Go up to parent folder', action);
        T = makeActionLink(T, 'Go up to parent folder', action);
      }
      entries.push(rowOf3(I, T));
    }
    _ref = fsToBrowse.ls('.', 'folders');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      folder = _ref[_i];
      I = icon('folder');
      T = folder;
      if (features.navigateFolders) {
        (function(folder) {
          action = function() {
            return changeFolder(folder);
          };
          I = makeActionLink(I, 'Enter folder ' + folder, action);
          return T = makeActionLink(T, 'Enter folder ' + folder, action);
        })(folder);
      }
      X = '';
      if (features.deleteFolders) {
        (function(folder) {
          return X += makeActionLink(icon('delete'), 'Delete folder ' + folder, function() {
            return askToDeleteEntry(folder);
          });
        })(folder);
      }
      if (features.moveFolders) {
        (function(folder) {
          return X += makeActionLink(icon('move'), 'Move folder ' + folder, function() {
            var sep;
            window.fileBeingMoved = {
              name: folder
            };
            fileBeingMoved.path = fsToBrowse.getCwd();
            fileBeingMoved.full = fileBeingMoved.path;
            sep = FileSystem.prototype.pathSeparator;
            if (fileBeingMoved.full.slice(-1) !== sep) {
              fileBeingMoved.full += sep;
            }
            fileBeingMoved.full += folder;
            fileBeingMoved.copy = false;
            fileBrowserMode = 'save file';
            return updateFileBrowser();
          });
        })(folder);
      }
      entries.push(rowOf3(I, T, X));
    }
    filter = typeof fileFilter !== "undefined" && fileFilter !== null ? fileFilter.options[typeof fileFilter !== "undefined" && fileFilter !== null ? fileFilter.selectedIndex : void 0].value : void 0;
    if (filter === '*.*') {
      filter = null;
    } else {
      filter = filter != null ? filter.slice(1) : void 0;
    }
    _ref1 = fsToBrowse.ls('.', 'files');
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      file = _ref1[_j];
      if (filter && file.slice(-filter.length) !== filter) {
        continue;
      }
      I = icon('text-file');
      T = file;
      if (features.filesDisabled) {
        T = "<font color='#888888'>" + T + "</font>";
      } else if (features.selectFile) {
        (function(file) {
          action = function() {
            return selectFile(file);
          };
          I = makeActionLink(I, 'Open ' + file, action);
          return T = makeActionLink(T, 'Open ' + file, action);
        })(file);
      }
      if (features.fileNameTextBox) {
        (function(file) {
          action = function() {
            saveFileName.value = file;
            return saveBoxKeyPressed();
          };
          I = makeActionLink(I, 'Save as ' + file, action);
          return T = makeActionLink(T, 'Save as ' + file, action);
        })(file);
      }
      X = '';
      if (features.deleteFiles) {
        (function(file) {
          return X += makeActionLink(icon('delete'), 'Delete file ' + file, function() {
            return askToDeleteEntry(file);
          });
        })(file);
      }
      if (features.moveFiles) {
        (function(file) {
          return X += makeActionLink(icon('move'), 'Move file ' + file, function() {
            var sep;
            window.fileBeingMoved = {
              name: file
            };
            fileBeingMoved.path = fsToBrowse.getCwd();
            fileBeingMoved.full = fileBeingMoved.path;
            sep = FileSystem.prototype.pathSeparator;
            if (fileBeingMoved.full.slice(-1) !== sep) {
              fileBeingMoved.full += sep;
            }
            fileBeingMoved.full += file;
            fileBeingMoved.copy = false;
            fileBrowserMode = 'save file';
            return updateFileBrowser();
          });
        })(file);
      }
      if (features.copyFiles) {
        (function(file) {
          return X += makeActionLink(icon('copy'), 'Copy file ' + file, function() {
            var sep;
            window.fileBeingMoved = {
              name: file
            };
            fileBeingMoved.path = fsToBrowse.getCwd();
            fileBeingMoved.full = fileBeingMoved.path;
            sep = FileSystem.prototype.pathSeparator;
            if (fileBeingMoved.full.slice(-1) !== sep) {
              fileBeingMoved.full += sep;
            }
            fileBeingMoved.full += file;
            fileBeingMoved.copy = true;
            fileBrowserMode = 'save file';
            return updateFileBrowser();
          });
        })(file);
      }
      entry = rowOf3(I, T, X);
      if (fileToBeOpened === file) {
        entry = "SELECT" + entry;
      }
      entries.push(entry);
    }
    if (entries.length === 0) {
      entries.push('(empty filesystem)');
    }
    interior = makeTable(entries);
    titlebar = statusbar = '';
    if (features.fileNameTextBox) {
      statusbar += "File name: <input id='saveFileName' type='text' size=40 onkeyup='saveBoxKeyPressed(event);'/>";
    }
    if (features.extensionFilter) {
      extensions = (function() {
        var _k, _len2, _ref2, _results;
        _ref2 = allExtensions();
        _results = [];
        for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
          e = _ref2[_k];
          _results.push("<option>" + e + "</option>");
        }
        return _results;
      })();
      statusbar += "File type: <select id='fileFilter' onchange='updateFileBrowser();'> " + (extensions.join('\n')) + " </select>";
    }
    for (index = _k = 0, _len2 = buttons.length; _k < _len2; index = ++_k) {
      text = buttons[index];
      disable = '';
      if (text === 'Open' && !fileToBeOpened) {
        disable = 'disabled=true';
      }
      buttons[index] = "<input type='button' value='  " + text + "  ' id='statusBarButton" + text + "' " + disable + " onclick='buttonClicked(\"" + text + "\");'/>";
    }
    buttons = buttons.join(' ');
    if (imitateDialog) {
      path = fsToBrowse.getCwd();
      if (path === FileSystem.prototype.pathSeparator) {
        path += ' (top level)';
      }
      titlebar = "<table border=1 cellpadding=5 cellspacing=0 width=100% height=100%> <tr height=1%> <td bgcolor=#cccccc> <table border=0 cellpadding=0 cellspacing=0 width=100%> <tr> <td align=left width=33%> <b>" + title + "</b> </td> <td align=center width=34%> Folder: " + path + " </td> <td align=right width=33%> " + (icon('close')) + " </td> </tr> </table> </td> </tr> <tr> <td bgcolor=#fafafa valign=top>";
      statusbar = "   </td> </tr> <tr height=1%> <td bgcolor=#cccccc> <table border=0 cellpadding=0 cellspacing=0 width=100%> <tr> <td align=left width=50%> " + statusbar + " </td> <td align=right width=50%> " + buttons + " </td> </tr> </table> </td> </tr> </table>";
    } else {
      if (window.fileBeingMoved.name) {
        statusbar += " &nbsp; " + buttons;
      }
      statusbar = "<div style='position: absolute; bottom: 0; width: 90%; margin-bottom: 5px;'> <center>" + statusbar + "</center> </div>";
    }
    oldName = (typeof saveFileName !== "undefined" && saveFileName !== null ? saveFileName.value : void 0) || (typeof fileBeingMoved !== "undefined" && fileBeingMoved !== null ? fileBeingMoved.name : void 0);
    oldIndex = typeof fileFilter !== "undefined" && fileFilter !== null ? fileFilter.selectedIndex : void 0;
    document.body.innerHTML = titlebar + interior + statusbar;
    if (oldName && (typeof saveFileName !== "undefined" && saveFileName !== null)) {
      saveFileName.value = oldName;
    }
    if (oldIndex && (typeof fileFilter !== "undefined" && fileFilter !== null)) {
      fileFilter.selectedIndex = oldIndex;
    }
    saveBoxKeyPressed();
    if (typeof saveFileName !== "undefined" && saveFileName !== null) {
      return saveFileName.focus();
    }
  };

  window.saveBoxKeyPressed = function(event) {
    var name;
    name = typeof saveFileName !== "undefined" && saveFileName !== null ? saveFileName.value : void 0;
    if (typeof statusBarButtonSave !== "undefined" && statusBarButtonSave !== null) {
      statusBarButtonSave.disabled = !name;
    }
    if (typeof name === 'string') {
      tellPage(['saveFileNameChanged', name]);
    }
    if ((event != null ? event.keyCode : void 0) === 13) {
      return buttonClicked('Save');
    }
    if ((event != null ? event.keyCode : void 0) === 27) {
      return buttonClicked('Cancel');
    }
  };

  makeTable = function(entries) {
    var half, i, lcolor, left, rcolor, result, right, _i;
    result = '<table border=0 width=100% cellspacing=5 cellpadding=5>';
    half = Math.ceil(entries.length / 2);
    for (i = _i = 0; 0 <= half ? _i < half : _i > half; i = 0 <= half ? ++_i : --_i) {
      left = entries[i];
      lcolor = 'bgcolor=#e8e8e8';
      if (left.slice(0, 6) === 'SELECT') {
        lcolor = 'bgcolor=#ddddff';
        left = left.slice(6);
      }
      right = entries[i + half];
      rcolor = 'bgcolor=#e8e8e8';
      if (!right) {
        rcolor = '';
      } else if (right.slice(0, 6) === 'SELECT') {
        rcolor = 'bgcolor=#ddddff';
        right = right.slice(6);
      }
      result += "<tr> <td width=50% " + lcolor + ">" + left + "</td> <td width=50% " + rcolor + ">" + (right || '') + "</td> </tr>";
    }
    return result + '</table>';
  };

  window.actionLinks = [];

  clearActionLinks = function() {
    var actionLinks;
    return actionLinks = [];
  };

  makeActionLink = function(text, tooltip, func) {
    var number;
    number = actionLinks.length;
    actionLinks.push(func);
    return "<a href='javascript:void(0);' title='" + tooltip + "' onclick='actionLinks[" + number + "]();'>" + text + "</a>";
  };

  icon = function(name) {
    return "<img src='" + name + ".png'>";
  };

  rowOf3 = function(icon, text, more) {
    if (more == null) {
      more = '';
    }
    return "<table border=0 cellpadding=0 cellspacing=0 width=100%><tr> <td width=22>" + (icon || '') + "</td> <td align=left>" + text + " &nbsp; &nbsp; </td> <td align=left width=66><nobr>" + more + "</nobr></td></tr></table>";
  };

  allExtensions = function(F) {
    var extension, file, folder, result, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2;
    if (F == null) {
      F = null;
    }
    if (!F) {
      F = new FileSystem(fsToBrowse.getName());
    }
    result = ['*.*'];
    _ref = F.ls('.', 'files');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      file = _ref[_i];
      extension = /\.[^.]*?$/.exec(file);
      if (extension) {
        extension = '*' + extension;
        if (__indexOf.call(result, extension) < 0) {
          result.push(extension);
        }
      }
    }
    _ref1 = F.ls('.', 'folders');
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      folder = _ref1[_j];
      F.cd(folder);
      _ref2 = allExtensions(F);
      for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
        extension = _ref2[_k];
        if (__indexOf.call(result, extension) < 0) {
          result.push(extension);
        }
      }
      F.cd('..');
    }
    return result.sort();
  };

}).call(this);

//# sourceMappingURL=filedialog.js.map