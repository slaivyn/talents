var templates = require('duality/templates');
var forms     = require('couchtypes/forms');
var types     = require('./types');

typeName = 'coworker'

exports.coworkers = function (head, req) {
  start({code: 200, headers: {'Content-Type': 'text/html'}});

  var col, rows = [];
  var cols = [];
  if(req.peer == "81.220.156.5" || req.peer == "127.0.0.1") {
    cols[0] = {type: typeName};
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
    col.type = col.doc.type
    cols.push(col);
  }
  if(cols.length) {
    rows.push({cols: cols});
  }

  if(typeof console != "undefined") {
    console.log("rows", rows)
  }

  var form = new forms.Form(types[typeName], null, {
    exclude: ['registrationTime']
  });
  if(req.info) {
    dbname = req.info.db_name
  } else {
    dbname = ""
  }
  var content = templates.render('Coworker/list.html', req, {
//    dbname: dbname,
    rows:   rows,
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