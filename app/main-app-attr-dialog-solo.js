// Generated by CoffeeScript 1.8.0
(function() {
  var canonicalFormToHTML,
    __slice = [].slice;

  canonicalFormToHTML = function(form) {
    var child, inside, type;
    type = tinymce.activeEditor.Groups.groupTypes.expression;
    inside = form.type === 'st' ? form.value : ((function() {
      var _i, _len, _ref, _results;
      _ref = form.children;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        _results.push(canonicalFormToHTML(child));
      }
      return _results;
    })()).join('');
    return type.openImageHTML + inside + type.closeImageHTML;
  };

  window.attributesActionForGroup = function(group) {
    var reload, showDialog;
    reload = function() {
      tinymce.activeEditor.windowManager.close();
      return showDialog();
    };
    return showDialog = function() {
      var addRow, addRule, attr, attribute, decodeId, decoded, embedded, encodeButton, encodeId, encodeLink, encodeTextInput, expression, index, key, list, meaning, nonLink, prepare, showKey, strictGroupComparator, summary, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1, _ref2, _ref3;
      summary = "<p>Expression: " + (canonicalFormToHTML(group.canonicalForm())) + "</p> <table border=0 cellpadding=5 cellspacing=0 width=100%>";
      addRow = function(key, value, type, links) {
        if (value == null) {
          value = '';
        }
        if (type == null) {
          type = '';
        }
        if (links == null) {
          links = '';
        }
        return summary += "<tr><td width=33% align=left>" + key + "</td> <td width=33% align=left>" + value + "</td> <td width=24% align=right>" + type + "</td> <td width=10% align=right>" + links + "</td> </tr>";
      };
      addRule = function() {
        return summary += "<tr><td colspan=4><hr></td></tr>";
      };
      prepare = {};
      _ref = group.attributeGroups();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        attribute = _ref[_i];
        key = attribute.get('key');
        (prepare[key] != null ? prepare[key] : prepare[key] = []).push(attribute);
      }
      _ref1 = group.keys();
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        key = _ref1[_j];
        if (decoded = OM.decodeIdentifier(key)) {
          if (prepare[decoded] == null) {
            prepare[decoded] = [];
          }
        }
      }
      encodeId = function(json) {
        return OM.encodeAsIdentifier(JSON.stringify(json));
      };
      decodeId = function(href) {
        return JSON.parse(OM.decodeIdentifier(href));
      };
      encodeLink = function(text, json, style, hover) {
        if (style == null) {
          style = true;
        }
        style = style ? '' : 'style="text-decoration: none; color: black;" ';
        hover = hover ? " title='" + hover + "'" : '';
        return "<a href='#' id='" + (encodeId(json)) + "' " + style + " " + hover + " >" + text + "</a>";
      };
      encodeButton = function(text, json) {
        return "<input type='button' id='" + (encodeId(json)) + "' value='" + text + "'/>";
      };
      encodeTextInput = function(text, json) {
        return "<input type='text' id='" + (encodeId(json)) + "' value='" + text + "'/>";
      };
      nonLink = function(text, hover) {
        return "<span title='" + hover + "' style='color: #aaaaaa;'>" + text + "</span>";
      };
      for (key in prepare) {
        list = prepare[key];
        if (embedded = group.get(OM.encodeAsIdentifier(key))) {
          list.push(group);
        }
        strictGroupComparator = function(a, b) {
          return strictNodeComparator(a.open, b.open);
        };
        showKey = key + ' ' + encodeLink('&#x1f589;', ['edit key', key], false, 'Edit attribute key');
        _ref2 = list.sort(strictGroupComparator);
        for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
          attr = _ref2[_k];
          if (attr === group) {
            expression = OM.decode(embedded.m);
            if (expression.type === 'a' && expression.children[0].equals(Group.prototype.listSymbol)) {
              _ref3 = expression.children.slice(1);
              for (index = _l = 0, _len3 = _ref3.length; _l < _len3; index = ++_l) {
                meaning = _ref3[index];
                addRow(showKey, canonicalFormToHTML(meaning) + ' ' + (meaning.type === 'st' ? encodeLink('&#x1f589;', ['edit from internal list', key, index], false, 'Edit attribute') : nonLink('&#x1f589;', 'Cannot edit -- not atomic')), 'hidden ' + encodeLink('&#x1f441;', ['show', key], false, 'Show attribute'), encodeLink('&#10007;', ['remove from internal list', key, index], false, 'Remove attribute'));
                showKey = '';
              }
            } else {
              addRow(showKey, canonicalFormToHTML(expression) + ' ' + (expression.type === 'st' ? encodeLink('&#x1f589;', ['edit internal solo', key], false, 'Edit attribute') : nonLink('&#x1f589;', 'Cannot edit -- not atomic')), 'hidden ' + encodeLink('&#x1f441;', ['show', key], false, 'Show attribute'), encodeLink('&#10007;', ['remove internal solo', key], false, 'Remove attribute'));
              showKey = '';
            }
          } else {
            meaning = attr.canonicalForm();
            addRow(showKey, canonicalFormToHTML(meaning) + ' ' + (meaning.type === 'st' ? encodeLink('&#x1f589;', ['edit external', attr.id()], false, 'Edit attribute') : nonLink('&#x1f589;', 'Cannot edit -- not atomic')), 'visible ' + encodeLink('&#x1f441;', ['hide', key], false, 'Hide attribute'), encodeLink('&#10007;', ['remove external', attr.id()], false, 'Remove attribute'));
            showKey = '';
          }
        }
        addRule();
      }
      summary += '</table>';
      if (Object.keys(prepare).length === 0) {
        summary += '<p>The expression has no attributes.</p>';
        addRule();
      }
      summary += '<center><p>' + encodeLink('<b>+</b>', ['add attribute'], false, 'Add new attribute') + '</p></center>';
      return tinymce.activeEditor.Dialogs.alert({
        title: 'Attributes',
        message: summary,
        width: 600,
        onclick: function(data) {
          var grouper, internalKey, internalValue, type, visuals, _ref4;
          try {
            _ref4 = decodeId(data.id), type = _ref4[0], key = _ref4[1], index = _ref4[2];
          } catch (_error) {}
          if (type === 'remove from internal list') {
            internalKey = OM.encodeAsIdentifier(key);
            internalValue = group.get(internalKey);
            meaning = OM.decode(internalValue.m);
            meaning = OM.app.apply(OM, [meaning.children[0]].concat(__slice.call(meaning.children.slice(1, index + 1)), __slice.call(meaning.children.slice(index + 2))));
            visuals = decompressWrapper(internalValue.v);
            visuals = visuals.split('\n');
            visuals.splice(index, 1);
            visuals = visuals.join('\n');
            internalValue = {
              m: meaning.encode(),
              v: compressWrapper(visuals)
            };
            group.plugin.editor.undoManager.transact(function() {
              return group.set(internalKey, internalValue);
            });
            reload();
          } else if (type === 'remove internal solo') {
            group.plugin.editor.undoManager.transact(function() {
              return group.clear(OM.encodeAsIdentifier(key));
            });
            reload();
          } else if (type === 'remove external') {
            group.plugin.editor.undoManager.transact(function() {
              return tinymce.activeEditor.Groups[key].disconnect(group);
            });
            reload();
          } else if (type === 'show') {
            group.unembedAttribute(key);
            reload();
          } else if (type === 'hide') {
            group.embedAttribute(key);
            reload();
          } else if (type === 'edit key') {
            tinymce.activeEditor.Dialogs.prompt({
              title: 'Enter new key',
              message: "Change \"" + key + "\" to what?",
              okCallback: function(newKey) {
                if (!/^[a-zA-Z0-9-_]+$/.test(newKey)) {
                  tinymce.activeEditor.Dialogs.alert({
                    title: 'Invalid key',
                    message: 'Keys can only contain Roman letters, decimal digits, hyphens, and underscores (no spaces or other punctuation).',
                    width: 300,
                    height: 200
                  });
                  return;
                }
                if (group.attributeGroupsForKey(newKey).length > 0) {
                  tinymce.activeEditor.Dialogs.alert({
                    title: 'Invalid key',
                    message: 'That key is already in use by a different attribute.',
                    width: 300,
                    height: 200
                  });
                  return;
                }
                return tinymce.activeEditor.undoManager.transact(function() {
                  var attrs, encKey, encNew, tmp, _len4, _m;
                  attrs = group.attributeGroupsForKey(key);
                  for (_m = 0, _len4 = attrs.length; _m < _len4; _m++) {
                    attr = attrs[_m];
                    attr.set('key', newKey);
                  }
                  encKey = OM.encodeAsIdentifier(key);
                  encNew = OM.encodeAsIdentifier(newKey);
                  tmp = group.get(encKey);
                  group.clear(encKey);
                  group.set(encNew, tmp);
                  return reload();
                });
              }
            });
          }
          if (type === 'edit from internal list') {
            return tinymce.activeEditor.Dialogs.prompt({
              title: 'Enter new value',
              message: "Provide the new content of the atomic expression.",
              okCallback: function(newValue) {
                var match;
                internalKey = OM.encodeAsIdentifier(key);
                internalValue = group.get(internalKey);
                meaning = OM.decode(internalValue.m);
                meaning.children[index + 1].tree.v = newValue;
                visuals = decompressWrapper(internalValue.v);
                visuals = visuals.split('\n');
                match = /^<([^>]*)>([^<]*)<(.*)$/.exec(visuals[index]);
                if (!match) {
                  return;
                }
                newValue = newValue.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&apos;');
                visuals[index] = "<" + match[1] + ">" + newValue + "<" + match[3];
                visuals = visuals.join('\n');
                internalValue = {
                  m: meaning.encode(),
                  v: compressWrapper(visuals)
                };
                group.plugin.editor.undoManager.transact(function() {
                  return group.set(internalKey, internalValue);
                });
                return reload();
              }
            });
          } else if (type === 'edit internal solo') {
            return tinymce.activeEditor.Dialogs.prompt({
              title: 'Enter new value',
              message: "Provide the new content of the atomic expression.",
              okCallback: function(newValue) {
                var match;
                internalKey = OM.encodeAsIdentifier(key);
                internalValue = group.get(internalKey);
                meaning = OM.decode(internalValue.m);
                meaning.tree.v = newValue;
                visuals = decompressWrapper(internalValue.v);
                match = /^<([^>]*)>([^<]*)<(.*)$/.exec(visuals);
                if (!match) {
                  return;
                }
                newValue = newValue.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&apos;');
                visuals = "<" + match[1] + ">" + newValue + "<" + match[3];
                internalValue = {
                  m: meaning.encode(),
                  v: compressWrapper(visuals)
                };
                group.plugin.editor.undoManager.transact(function() {
                  return group.set(internalKey, internalValue);
                });
                return reload();
              }
            });
          } else if (type === 'edit external') {
            return tinymce.activeEditor.Dialogs.prompt({
              title: 'Enter new value',
              message: "Provide the new content of the atomic expression.",
              okCallback: function(newValue) {
                group.plugin[key].setContentAsText(newValue);
                return reload();
              }
            });
          } else if (type === 'add attribute') {
            index = 1;
            key = function() {
              return OM.encodeAsIdentifier("attribute" + index);
            };
            while (group.get(key())) {
              index++;
            }
            meaning = OM.string('edit this');
            grouper = function(type) {
              var result;
              result = grouperHTML('expression', type, 0, false);
              if (type === 'open') {
                result = result.replace('grouper', 'grouper mustreconnect');
              }
              return result;
            };
            visuals = grouper('open') + meaning.value + grouper('close');
            internalValue = {
              m: meaning.encode(),
              v: compressWrapper(visuals)
            };
            group.plugin.editor.undoManager.transact(function() {
              return group.set(key(), internalValue);
            });
            return reload();
          }
        }
      });
    };
  };

}).call(this);

//# sourceMappingURL=main-app-attr-dialog-solo.js.map
