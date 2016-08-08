// Generated by CoffeeScript 1.8.0
(function() {
  window.groupMenuItems.appsettings = {
    text: 'Application settings...',
    context: 'file',
    onclick: function() {
      return tinymce.activeEditor.Settings.application.showUI();
    }
  };

  window.groupMenuItems.docsettings = {
    text: 'Document settings...',
    context: 'file',
    onclick: function() {
      return tinymce.activeEditor.Settings.document.showUI();
    }
  };

  window.afterEditorReadyArray.push(function(editor) {
    var A, D;
    A = editor.Settings.addCategory('application');
    if (!A.get('filesystem')) {
      A.set('filesystem', 'dropbox');
    }
    A.setup = function(div) {
      var fs, _ref, _ref1;
      fs = A.get('filesystem');
      return div.innerHTML = [editor.Settings.UI.heading('Wiki Login'), editor.Settings.UI.info('Entering a username and password here does NOT create an account on the wiki.  You must already have one.  If you do not, first visit <a href="/wiki/index.php" target="_blank" style="color: blue;">the wiki</a>, create an account, then return here.'), editor.Settings.UI.text('Username', 'wiki_username', (_ref = A.get('wiki_username')) != null ? _ref : ''), editor.Settings.UI.password('Password', 'wiki_password', (_ref1 = A.get('wiki_password')) != null ? _ref1 : ''), editor.Settings.UI.heading('Open/Save Filesystem'), editor.Settings.UI.radioButton('Dropbox (cloud storage, requires account)', 'filesystem', fs === 'dropbox', 'filesystem_dropbox'), editor.Settings.UI.radioButton('Local Storage (kept permanently, in browser only)', 'filesystem', fs === 'local storage', 'filesystem_local_storage')].join('\n');
    };
    A.teardown = function(div) {
      var elt;
      elt = function(id) {
        return div.ownerDocument.getElementById(id);
      };
      A.set('wiki_username', elt('wiki_username').value);
      A.set('wiki_password', elt('wiki_password').value);
      return A.setFilesystem(elt('filesystem_dropbox').checked ? 'dropbox' : 'local storage');
    };
    A.setFilesystem = function(name) {
      A.set('filesystem', name);
      if (name === 'dropbox') {
        editor.LoadSave.installOpenHandler(editor.Dropbox.openHandler);
        editor.LoadSave.installSaveHandler(editor.Dropbox.saveHandler);
        return editor.LoadSave.installManageFilesHandler(editor.Dropbox.manageFilesHandler);
      } else {
        editor.LoadSave.installOpenHandler();
        editor.LoadSave.installSaveHandler();
        return editor.LoadSave.installManageFilesHandler();
      }
    };
    A.setFilesystem(A.get('filesystem'));
    D = editor.Settings.addCategory('document');
    D.metadata = {};
    D.get = function(key) {
      return D.metadata[key];
    };
    D.set = function(key, value) {
      return D.metadata[key] = value;
    };
    D.setup = function(div) {
      var _ref;
      div.innerHTML = [editor.Settings.UI.heading('Dependencies'), "<div id='dependenciesSection'></div>", editor.Settings.UI.heading('Wiki Publishing'), editor.Settings.UI.text('Publish to wiki under this title', 'wiki_title', (_ref = D.get('wiki_title')) != null ? _ref : '')].join('\n');
      return editor.Dependencies.installUI(div.ownerDocument.getElementById('dependenciesSection'));
    };
    D.teardown = function(div) {
      var elt;
      elt = function(id) {
        return div.ownerDocument.getElementById(id);
      };
      return D.set('wiki_title', elt('wiki_title').value);
    };
    editor.LoadSave.saveMetaData = function() {
      D.metadata.dependencies = editor.Dependencies["export"]();
      return D.metadata;
    };
    return editor.LoadSave.loadMetaData = function(object) {
      var _ref, _ref1;
      D.metadata = object;
      return editor.Dependencies["import"]((_ref = (_ref1 = D.metadata) != null ? _ref1.dependencies : void 0) != null ? _ref : []);
    };
  });

}).call(this);

//# sourceMappingURL=main-app-settings-solo.js.map