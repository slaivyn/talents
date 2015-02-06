exports.coworker_get = {
  map: function(doc) {
    if(doc.type == "coworker" && doc._id)
      emit(doc.username, null);
  }
}