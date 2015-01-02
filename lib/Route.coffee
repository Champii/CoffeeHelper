_ = require 'underscore'

class Route
  apiVersion: '/api/1/'

  constructor: (@resource, @app, @config) ->
    @name = @resource.lname + 's'

    @Config()

  _Add: (type, url, middle..., done) ->
    if not done?
      done = url
      url = '/'

    done = @_AddMiddleware type, url, done
    if not @[type + url]?
      @[type + url] = done
      if middle.length
        middle.push (req, res, next) => @[type + url](req, res, next)
        @app.route(@apiVersion + @name + url)[type].apply @app.route(@apiVersion + @name + url), middle
      else
        @app.route(@apiVersion + @name + url)[type] (req, res, next) => @[type + url](req, res, next)
    else
      @[type + url] = done

  All: (args...)->
    args.unshift 'all'
    @_Add.apply @, args

  Get: (args...)->
    args.unshift 'get'
    @_Add.apply @, args

  Post: (args...)->
    args.unshift 'post'
    @_Add.apply @, args

  Put: (args...)->
    args.unshift 'put'
    @_Add.apply @, args

  Delete: (args...)->
    args.unshift 'delete'
    @_Add.apply @, args

  _AddMiddleware: (type, url, done) ->
    if !@config?
      return done

    for element, content of @config
      if typeof content is 'function'
        done = content done
      else if typeof content is 'object' and not content.prototype
        for method, wrapper of content
          if method == type
            done = wrapper done
          else
            method = method.split('-')
            if method.length > 1
              if method[0] == type and method[1] == url
                done = wrapper done
            else if method[0] == type
              done = wrapper done

    done

  Config: ->

class DefaultRoute extends Route
  Config: ->
    @_Add 'all', '/:id*', (req, res, next) =>
      if not isFinite req.params.id
        return next()

      @resource.Fetch req.params.id, (err, result) =>
        return res.status(500).send(err) if err?

        req[@resource.lname] = result
        next()

    @_Add 'get', (req, res) =>
      @resource.List (err, results) ->
        return res.status(500).send(err) if err?

        res.status(200).send _(results).invoke 'ToJSON'

    @_Add 'get', '/:id', (req, res) =>
      res.status(200).send req[@resource.lname].ToJSON()

    @_Add 'post', (req, res) =>
      @resource.Deserialize req.body, (err, result) ->
        return res.status(500).send(err) if err?

        result.Save (err) ->
          return res.status(500).send(err) if err?

          res.status(200).send result.ToJSON()

    @_Add 'put', '/:id', (req, res) =>
      _(req[@resource.lname]).extend req.body

      req[@resource.lname].Save (err) =>
        return res.status(500).send(err) if err?

        res.status(200).send req[@resource.lname].ToJSON()


    @_Add 'delete', '/:id', (req, res) =>
      req[@resource.lname].Delete (err) ->
        return res.status(500).send(err) if err?

        res.status(200).end()


Route.DefaultRoute = DefaultRoute
module.exports = Route
