module.exports = [
  {from: '/static/*', to: 'static/*'},
  {from: '/:id',      to: '_update/edit_coworker/:id', method: 'PUT'},
  {from: '/',         to: '_list/coworkers/coworker_get', query: {include_docs: "true", attachments: "true"}},
  {from: '*',         to: '_list/coworkers/coworker_get', query: {include_docs: "true", attachments: "true"}}
]