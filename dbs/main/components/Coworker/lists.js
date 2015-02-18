var templates = require('duality/templates');
var forms     = require('couchtypes/forms');
var types     = require('./types');

typeName = 'coworker'

exports.coworkers = function (head, req) {
  start({code: 200, headers: {'Content-Type': 'text/html'}});

  var col, cols = [];
  var peer = '';
  if (typeof sessionStorage != "undefined") {
    peer = sessionStorage.getItem("peer")
  }
  if (req.peer) {
    peer = req.peer
  }
  if (peer == "81.220.156.5" || peer == "127.0.0.1") {
    cols[0] = {type: typeName, doc: {skillList: [""]}};
  }

  while (col = getRow()) {
    for(var e in col.doc._attachments) {
      if(e.indexOf('avatar') == 0) {
        col.doc.avatarFileName = e
        var obj = {};
        obj[e.substring('avatar/'.length)] = col.doc._attachments[e];
        col.doc.avatarInfo = JSON.stringify(obj);
      }
    }
    if (col.doc.twitter) {
      col.doc.twitterUrl = 'https://twitter.com/' + col.doc.twitter.slice(1)
    }
    if (col.doc.github) {
      col.doc.githubUrl = 'https://github.com/' + col.doc.github.slice(1)
    }
    if (!col.doc.hasOwnProperty('skillList')) {
      col.doc.skillList = []
    }
    if (col.doc.skillList.length < 5) {
      //col.moreSkill = {
      //  idx: col.doc.skillList.length
      //}
      col.doc.skillList.push("")
    }
    col.type = col.doc.type
    cols.push(col);
  }

  var form = new forms.Form(types[typeName], null, {
    exclude: ['registrationTime']
  });
  var content = templates.render('Coworker/list.html', req, {
    peer:   peer,
    cols:   cols,
    form:   form.toHTML(req),
  });

  if(req.client) {
    $('#content').html(content);
  }
  else {
    return templates.render('base.html', req, {
      title: 'Coworkers',
      content: content
    });
  }
}