var couchtypes = require('couchtypes/types');
var types      = require('./types');
var utils      = require('./utils');

exports.validate_doc_update = function(newDoc, oldDoc, userCtx) {
  var hasRole = utils.hasRole(userCtx);

  utils.assert(newDoc.hasOwnProperty('_id'), 'New doc must have a _id');

  if (!hasRole('superadmin') || !hasRole('_admin')) {
    couchtypes.validate_doc_update(types, newDoc, oldDoc, userCtx);
  }
};
