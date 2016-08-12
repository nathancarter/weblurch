// Generated by CoffeeScript 1.8.0
(function() {
  var maxCharCode,
    __slice = [].slice,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  window.Group.prototype.canonicalForm = function() {
    var child;
    if (this.children.length === 0) {
      return OM.str(this.contentAsCode());
    } else {
      return OM.app.apply(OM, (function() {
        var _i, _len, _ref, _results;
        _ref = this.children;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          _results.push(child.canonicalForm());
        }
        return _results;
      }).call(this));
    }
  };

  window.Group.prototype.attributeGroups = function(includePremises) {
    var connection, key, result, source, _i, _len, _ref;
    if (includePremises == null) {
      includePremises = false;
    }
    result = [];
    _ref = this.connectionsIn();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      connection = _ref[_i];
      source = tinymce.activeEditor.Groups[connection[0]];
      if (key = source.get('key')) {
        if (!includePremises && key === 'premise') {
          continue;
        }
        result.push(source);
      }
    }
    return result;
  };

  window.Group.prototype.attributeGroupsForKey = function(key) {
    var group, _i, _len, _ref, _results;
    _ref = this.attributeGroups(true);
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      group = _ref[_i];
      if (group.get('key') === key) {
        _results.push(group);
      }
    }
    return _results;
  };

  window.Group.prototype.attributionAncestry = function(includePremises) {
    var group, otherGroup, result, _i, _j, _len, _len1, _ref, _ref1;
    if (includePremises == null) {
      includePremises = false;
    }
    result = [];
    _ref = this.attributeGroups(includePremises);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      group = _ref[_i];
      _ref1 = [group].concat(__slice.call(group.attributionAncestry()));
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        otherGroup = _ref1[_j];
        if (__indexOf.call(result, otherGroup) < 0) {
          result.push(otherGroup);
        }
      }
    }
    return result;
  };

  window.Group.prototype.listSymbol = OM.sym('List', 'Lurch');

  window.Group.prototype.completeForm = function(includePremises) {
    var decoded, embedded, expression, group, key, list, meanings, prepare, result, strictGroupComparator, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2;
    if (includePremises == null) {
      includePremises = false;
    }
    result = this.canonicalForm();
    prepare = {};
    _ref = this.attributeGroups(includePremises);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      group = _ref[_i];
      key = group.get('key');
      (prepare[key] != null ? prepare[key] : prepare[key] = []).push(group);
    }
    _ref1 = this.keys();
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      key = _ref1[_j];
      if (decoded = OM.decodeIdentifier(key)) {
        if (prepare[decoded] == null) {
          prepare[decoded] = [];
        }
      }
    }
    for (key in prepare) {
      list = prepare[key];
      if (embedded = this.get(OM.encodeAsIdentifier(key))) {
        list.push(this);
      }
      meanings = [];
      strictGroupComparator = function(a, b) {
        return strictNodeComparator(a.open, b.open);
      };
      _ref2 = list.sort(strictGroupComparator);
      for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
        group = _ref2[_k];
        if (group === this) {
          expression = OM.decode(embedded.m);
          if (expression.type === 'a' && expression.children[0].equals(Group.prototype.listSymbol)) {
            meanings = meanings.concat(expression.children.slice(1));
          } else {
            meanings.push(expression);
          }
        } else {
          meanings.push(group.completeForm(includePremises));
        }
      }
      result = OM.att(result, OM.sym(key, 'Lurch'), meanings.length === 1 ? meanings[0] : OM.app.apply(OM, [Group.prototype.listSymbol].concat(__slice.call(meanings))));
    }
    return result;
  };

  window.Group.prototype.lookupAttributes = function(key) {
    var embedded, expression, group, list, result, strictGroupComparator, _i, _len, _ref;
    list = this.attributeGroupsForKey(key);
    if (embedded = this.get(OM.encodeAsIdentifier(key))) {
      list.push(this);
    }
    result = [];
    strictGroupComparator = function(a, b) {
      return strictNodeComparator(a.open, b.open);
    };
    _ref = list.sort(strictGroupComparator);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      group = _ref[_i];
      if (group === this) {
        expression = OM.decode(embedded.m);
        if (expression.type === 'a' && expression.children[0].equals(Group.prototype.listSymbol)) {
          result = result.concat(expression.children.slice(1));
        } else {
          result.push(expression);
        }
      } else {
        result.push(group);
      }
    }
    return result;
  };

  window.Group.prototype.embedAttribute = function(key, andDelete) {
    var g, groups, internalKey, internalValue;
    if (andDelete == null) {
      andDelete = true;
    }
    groups = (function() {
      var _i, _len, _ref, _results;
      _ref = this.attributeGroups();
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        g = _ref[_i];
        if (g.get('key') === key) {
          _results.push(g);
        }
      }
      return _results;
    }).call(this);
    internalKey = OM.encodeAsIdentifier(key);
    internalValue = {
      m: groups.length === 1 ? groups[0].completeForm() : OM.app.apply(OM, [Group.prototype.listSymbol].concat(__slice.call((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = groups.length; _i < _len; _i++) {
          g = groups[_i];
          _results.push(g.completeForm());
        }
        return _results;
      })())))
    };
    internalValue.m = internalValue.m.encode();
    return this.plugin.editor.undoManager.transact((function(_this) {
      return function() {
        var a, ancestor, ancestorIds, ancestry, connection, group, hasConnectionToNonAncestor, target, _i, _j, _k, _len, _len1, _len2, _ref, _results;
        internalValue.v = '';
        for (_i = 0, _len = groups.length; _i < _len; _i++) {
          group = groups[_i];
          _ref = group.connectionsOut();
          for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
            connection = _ref[_j];
            target = tinymce.activeEditor.Groups[connection[1]];
            group.disconnect(target);
          }
          ($(group.open)).addClass('mustreconnect');
          ancestry = group.attributionAncestry();
          ancestry.sort(strictNodeComparator);
          if (internalValue.v.length > 0) {
            internalValue.v += '\n';
          }
          internalValue.v += ((function() {
            var _k, _len2, _ref1, _results;
            _ref1 = [group].concat(__slice.call(ancestry));
            _results = [];
            for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
              g = _ref1[_k];
              _results.push(g.groupAsHTML(false));
            }
            return _results;
          })()).join('');
        }
        internalValue.v = compressWrapper(internalValue.v);
        _this.set(internalKey, internalValue);
        if (!andDelete) {
          return;
        }
        _results = [];
        for (_k = 0, _len2 = groups.length; _k < _len2; _k++) {
          group = groups[_k];
          group.remove();
          ancestry = group.attributionAncestry();
          ancestry.sort(strictNodeComparator);
          ancestorIds = [group.id()].concat(__slice.call((function() {
              var _l, _len3, _results1;
              _results1 = [];
              for (_l = 0, _len3 = ancestry.length; _l < _len3; _l++) {
                a = ancestry[_l];
                _results1.push(a.id());
              }
              return _results1;
            })()));
          _results.push((function() {
            var _l, _len3, _len4, _m, _ref1, _ref2, _results1;
            _results1 = [];
            for (_l = 0, _len3 = ancestry.length; _l < _len3; _l++) {
              ancestor = ancestry[_l];
              hasConnectionToNonAncestor = false;
              _ref1 = ancestor.connectionsOut();
              for (_m = 0, _len4 = _ref1.length; _m < _len4; _m++) {
                connection = _ref1[_m];
                if (_ref2 = connection[1], __indexOf.call(ancestorIds, _ref2) < 0) {
                  hasConnectionToNonAncestor = true;
                  break;
                }
              }
              if (!hasConnectionToNonAncestor) {
                _results1.push(ancestor.remove());
              } else {
                _results1.push(void 0);
              }
            }
            return _results1;
          })());
        }
        return _results;
      };
    })(this));
  };

  window.Group.prototype.unembedAttribute = function(key, useCurrentCursor) {
    var grouperClassRE, html, match, meaning, modifiedHTML, value;
    if (useCurrentCursor == null) {
      useCurrentCursor = false;
    }
    if (!(value = this.get(OM.encodeAsIdentifier(key)))) {
      return;
    }
    html = decompressWrapper(value.v);
    meaning = OM.decode(value.m);
    grouperClassRE = /class=('[^']*grouper[^']*'|"[^"]*grouper[^"]*")/;
    modifiedHTML = '';
    while (match = grouperClassRE.exec(html)) {
      modifiedHTML += html.substr(0, match.index) + match[0].substr(0, match[0].length - 1) + ' justPasted' + match[0].substr(match[0].length - 1);
      html = html.substr(match.index + match[0].length);
    }
    modifiedHTML += html;
    return this.plugin.editor.undoManager.transact((function(_this) {
      return function() {
        var range;
        if (!useCurrentCursor) {
          range = _this.rangeAfter();
          range.collapse(true);
          _this.plugin.editor.selection.setRng(range);
        }
        _this.plugin.editor.insertContent(modifiedHTML);
        _this.plugin.scanDocument();
        $(_this.plugin.editor.getDoc()).find('.grouper.mustreconnect').each(function(index, grouper) {
          var g;
          g = _this.plugin.grouperToGroup(grouper);
          g.connect(_this);
          g.set('key', key);
          if (!g.get('keyposition')) {
            g.set('keyposition', 'arrow');
          }
          return ($(grouper)).removeClass('mustreconnect');
        });
        return _this.clear(OM.encodeAsIdentifier(key));
      };
    })(this));
  };

  maxCharCode = 50000;

  window.compressWrapper = function(string) {
    var code, grouperRE, i, match, result, _i, _ref;
    grouperRE = /<img\s+([^>]*)\s+src=('[^']*'|"[^"]*")([^>]*)>/;
    while (match = grouperRE.exec(string)) {
      string = string.substr(0, match.index) + ("<img " + match[1] + " " + match[2] + ">") + string.substr(match.index + match[0].length);
    }
    string = LZString.compress(string);
    result = '';
    for (i = _i = 0, _ref = string.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      if ((code = string.charCodeAt(i)) < maxCharCode) {
        result += string[i];
      } else {
        result += String.fromCharCode(50000) + String.fromCharCode(code - 50000);
      }
    }
    return result;
  };

  window.decompressWrapper = function(string) {
    var code, result;
    result = '';
    while (string.length > 0) {
      if ((code = string.charCodeAt(0)) < maxCharCode) {
        result += string[0];
        string = string.substr(1);
      } else {
        result += String.fromCharCode(code + string.charCodeAt(1));
        string = string.substr(2);
      }
    }
    return LZString.decompress(result);
  };

  window.Group.prototype.contentAsCode = function() {
    var recur, shouldBreak;
    shouldBreak = function(node) {
      var _ref;
      return (_ref = node.tagName) === 'P' || _ref === 'DIV';
    };
    recur = (function(_this) {
      return function(nodeOrList) {
        var index, result, _i, _ref;
        if (nodeOrList instanceof _this.plugin.editor.getWin().Text) {
          return nodeOrList.textContent.replace(/\u2003/g, '\t');
        }
        if (nodeOrList.tagName === 'BR') {
          return '\n';
        }
        result = '';
        for (index = _i = 0, _ref = nodeOrList.childNodes.length; 0 <= _ref ? _i < _ref : _i > _ref; index = 0 <= _ref ? ++_i : --_i) {
          if (index > 0 && (shouldBreak(nodeOrList.childNodes[index - 1]) || shouldBreak(nodeOrList.childNodes[index]))) {
            result += '\n';
          }
          if (index < nodeOrList.childNodes.length - 1 || nodeOrList.childNodes[index].tagName !== 'BR') {
            result += recur(nodeOrList.childNodes[index]);
          }
        }
        return result;
      };
    })(this);
    return recur(this.contentAsFragment());
  };

  window.Group.prototype.setContentAsCode = function(code) {
    return this.setContentAsText(Group.codeToHTML(code));
  };

  window.Group.codeToHTML = function(code) {
    return code.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&apos;').replace(/\n/g, '<br>').replace(/\t/g, '&emsp;');
  };

}).call(this);

//# sourceMappingURL=main-app-group-class-solo.js.map
