_ = require 'underscore'
db = require('mongous').Mongous

ids = {}

module.exports = (config) ->

  class Mongo

    ->
      db().open config.host || 'localhost', config.port || 27017
      # console.log config
      if config.user
        db(config.database + '.$cmd').auth config.user, config.pass, (res) ->
          # console.log 'Mongo auth: ', res

    Select: (table, fields, where, options, done) ->
      # console.log 'Select', table, fields, where, options, done
      db(config.database + '.' + table).find where, (rows) ->
        # console.log 'rows', rows.documents
        done null, rows.documents

    Insert: (table, fields, done) ->
      #FIXME
      # callback = ->
        # fields.id = ids[table]++
      db(config.database + '.' + table).insert fields
      done null, fields

      # if not ids[table]?
      #   @_SetIds table, callback
      # else
      #   callback!

    Update: (table, fields, where, done) ->
      db(config.database + '.' + table).update {id: fields.id}, fields
      done()

    Delete: (table, where, done) ->
      db(config.database + '.' + table).remove {id: where.id}
      done null, 1

    # _SetIds: (name, done) ->
    #   # done!
    #   if !(ids[name]?)
    #     db(config.database + '.' + name).find {}, {}, {sort: {id: -1}, lim: 1}, ->
    #       ids[name] := +it.documents[0]?.id || 0
    #       ids[name]++
    #       done! if done?
    #   else
    #     done! if done?

    Drop: (table) ->
      db(config.database + '.$cmd').find({drop: table},1)

    _NextId: (name, done) ->
      db(config.database + '.' + name).find {}, {}, {sort: {id: -1}, lim: 1}, ->
        done null, +it.documents[0]?.id + 1 || 1


  new Mongo()

module.exports.AddTable = (name, config, done) ->
