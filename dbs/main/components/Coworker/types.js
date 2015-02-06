var Type        = require('couchtypes/types').Type;
var fields      = require('couchtypes/fields');
var widgets     = require('couchtypes/widgets');
var permissions = require('couchtypes/permissions');
var idField     = require('../fields').idField;
/*var dbname;

if(typeof console != "undefined") {
  var session = require('session');
  session.info(function() {
    dbname  = session.userCtx.db;
    console.log("types", session, session.userCtx, dbname)
  })
}

usernameMatchesField = function (field) {
  return function (newDoc, oldDoc, newValue, oldValue, userCtx) {
    if(!dbname) {
      dbname = userCtx.db
    }
    dbUsername = userCtx.db + '.' + oldDoc[field];
    if (userCtx.name !== dbUsername) {
      throw new Error('Username ('+ userCtx.name +') does not match field ' + field +' ('+dbUsername+')');
    }
  };
};
*/

exports.coworker = new Type('coworker', {
  permissions: {
    update: permissions.usernameMatchesField('username'),
    remove: permissions.hasRole('_admin')
  },
  fields: {
    id:               idField            (/<username>/),
    username:         fields.string      (),
    skillList:        fields.array       ({required: false}),
    website:          fields.string      ({required: false}),
    twitter:          fields.string      ({required: false}),
    github:           fields.string      ({required: false}),
    email:            fields.string      ({required: false}),
    tel:              fields.string      ({required: false}),
    registrationTime: fields.createdTime (),
    avatar:           fields.attachments ({required: false}),
  }
});
