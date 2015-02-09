var templates = require('duality/templates');

exports.coworker = function (doc, req) {
  return {
    title: doc.title,
    content: templates.render('Coworker/show.html', req, doc)
  }
}

exports.ip = function (head, req) {
  return {
    body: JSON.stringify(req.peer),
    headers: {'Content-Type': 'application/json'}
  }
}