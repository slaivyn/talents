var fields = require('couchtypes/fields');

exports.idField = function(idRegExp) {
  var buildId = function(doc) {
    return idRegExp.source.replace(/<([a-z_]*)>/g, function (match, p1) {
        return doc[p1];
      }
    )
  }
  var build_id = function(doc, id) {
    return doc.type + ':' + id
  }
  var idValidation = function(doc, value) {
    if(doc.hasOwnProperty('_deleted') && doc._deleted === true) {
      return true;
    }
    var mustBe = buildId(doc);
    if (!RegExp(mustBe).test(value)) {
      throw new Error("Incorrect id; value: '"+value+"' must be: '"+mustBe+"'");
    }
  }
  var _idValidation = function (doc, value) {
    if (doc._id != build_id(doc, value)) {
    //if (doc._id != doc.type + ":" + value) {
      throw Error('_id not corresponding to id: '+doc._id+' != '+doc.type+':'+doc.id)
    }
  }
  return fields.string({
    validators: [idValidation, _idValidation],
    regexp:     idRegExp.toString(),
    buildId:    buildId,
    build_id:   build_id,
  });
}
