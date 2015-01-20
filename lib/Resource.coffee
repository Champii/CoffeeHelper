_ = require 'underscore'
async = require 'async'

Nodulator = require '../'
Validator = require 'validator'

validationError = (field, value, message) ->
  field: field
  value: value
  message: "The '#{field}' field with value '#{value}' #{message}"

typeCheck =
  bool: (value) -> value is true or value is false
  int: Validator.isInt
  string: (value) -> true # FIXME: call add subCheckers
  date: Validator.isDate
  email: Validator.isEmail

module.exports = (table, config, app, routes, name) ->

  class Resource

    constructor: (blob) ->
      @_table = @.__proto__.constructor._table
      @_schema = @.__proto__.constructor._schema

      @id = blob.id || null

      if @_schema?
        for field, description of @_schema when blob[field]?
          @[field] = blob[field]
      else
        for field, value of blob
          @[field] = blob[field]

    Save: (done) ->
      Resource._Validate @Serialize(), true, (err) =>
        return done err if err?

        exists = @id?

        @_table.Save @Serialize(), (err, id) =>
          return done err if err?

          if !exists
            @id = id
            Nodulator.bus.emit 'new_' + name, @Serialize()
          else
            Nodulator.bus.emit 'update_' + name, @Serialize()

          done null, @

    Delete: (done) ->
      @_table.Delete @id, (err) =>
        return done err if err?

        Nodulator.bus.emit 'delete_' + name, @Serialize()
        done()

    # Get what to send to the database
    Serialize: ->
      res = if @id? then {id: @id} else {}
      if @_schema?
        for field, description of @_schema when field isnt '_assoc'
          if typeof(config.schema[field].type) is 'function'
            res[field] = @[field].Serialize()
          else
            res[field] = @[field]
      else
        for field, description of @ when field[0] isnt '_'
          res[field] = @[field]

      res

    # Get what to send to client
    ToJSON: ->
      @Serialize()

    @_Validate: (blob, full, done) ->
      if not done?
        done = full
        full = false

      errors = []
      for field, validator of @_schema when field isnt '_assoc'
        if full and not blob[field]? and not config.schema[field].optional
          errors.push validationError field, blob[field], ' was not present.'
        else if blob[field]? and not validator(blob[field])
          errors.push validationError field, blob[field], ' was not a valid ' + config.schema[field].type

        for field, value of blob when not @_schema[field]?
          errors.push validationError field, blob[field], ' is not in schema'

      done(if errors.length then {errors} else null)

    # Fetch from id
    @Fetch: (id, done) ->
      @_table.Find id, (err, blob) =>
        return done err if err?

        @resource.Deserialize blob, done

    # Get every records satisfying given constraints
    @FetchBy: (constraints, done) ->
      @_table.FindWhere '*', contraints, (err, blob) =>
        return done err if err?

        @resource.Deserialize blob, done

    # Get every records from db
    @List: (done) ->
      @_table.Select 'id', {}, {}, (err, ids) =>
        return done err if err?

        async.map _(ids).pluck('id'), (item, done) =>
          @resource.Fetch item, done
        , done

    # Get every records satisfying given constraints
    @ListBy: (constraints, done) ->
      @_table.Select 'id', constraints, {}, (err, ids) =>
        return done err if err?

        async.map _(ids).pluck('id'), (item, done) =>
          @resource.Fetch item, done
        , done

    # Deserialize and Save
    @Create: (blob, done) ->
      @Deserialize blob, (err, resource) ->
        return done err if err?

        resource.Save done

    # Pre-Instanciation
    @Deserialize: (blob, done) ->
      @_Validate blob, true, (err) =>
        return done err if err?

        res = @
        if @_schema?
          assocs = {}
          async.each @_schema._assoc, (resource, done) =>
            resource.fetch blob, (err, instance) =>
              return done() if err? and config? and config.schema[resource.name].optional
              return done err if err?

              assocs[resource.name] = instance
              done()
          , (err) ->
            return done err if err?

            done null, new res _.extend(blob, assocs)
        else
          done null, new res blob

    @_PrepareResource: (_table, _config, _app, _routes, _name) ->
      @_table = _table
      @config = _config
      @app = _app
      @lname = _name.toLowerCase()
      @resource = @
      @_routes = _routes

      @

    @Init: ->
      @resource = @
      Nodulator.resources[@lname] = @

      if @config? and @config.schema
        @_schema = {_assoc: []}

        for field, description of @config.schema

          do (description) =>
            if description.type? and typeof description.type is 'function'
              @_schema._assoc.push
                name: field
                fetch: (blob, done) ->
                  description.type.Fetch blob[description.localKey], done
              @_schema[field] = null
            else if description.type?
              @_schema[field] = typeCheck[description.type]

      if @config? and @config.abstract
        @Extend = (name, routes, config) =>
          config = _(config).extend @config
          delete config.abstract if config? and not config.abstract
          Nodulator.Resource name, routes, config, @
      else if @_routes?
        @routes = new @_routes(@, @app, @config)

  Resource._PrepareResource(table, config, app, routes, name)
