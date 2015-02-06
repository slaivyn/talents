var templates = require('duality/templates');
var forms     = require('couchtypes/forms');
var utils     = require('duality/utils');
var events    = require('duality/events');
var types     = require('./types');

var twitterBase, githubBase, idx;


exports.edit_coworker = function (doc, req) {
  console.log('update handler')
  var form = new forms.Form(types.coworker, doc, {
    exclude: ['registrationTime']
  });

  form.validate(req);

  console.info(form, types.coworker);

  if (form.isValid()) {
    if(form.values.twitter) {
      twitterBase = 'twitter.com/'
      idx = form.values.twitter.indexOf(twitterBase)
      if(idx > -1) {
        idx += githubBase.length
        form.values.twitter = form.values.twitter.slice(idx)
      }
      if (form.values.twitter[0] != '@') {
        form.values.twitter = '@' + form.values.twitter
      }
    }
    if(form.values.github) {
      githubBase = 'github.com/'
      idx = form.values.github.indexOf(githubBase)
      if(idx > -1) {
        idx += githubBase.length
        form.values.github = form.values.github.slice(idx)
      }
      if (form.values.github[0] != '@') {
        form.values.github = '@' + form.values.github
      }
    }
    console.log(form.values);
    return [form.values, utils.redirect(req, '/')];
  }
  else {
    console.error(form)
    var content = templates.render('Coworker/list.html', req, {
      form: form.toHTML(req)
    });

    return [null, {content: content}];
  }
};