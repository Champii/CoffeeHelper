superagent = require 'superagent'
agent = superagent.agent()

class Client

  constructor: (@app) ->
    @identity =
      username: ''
      password: ''
    @request = require('supertest')(@app)

  Login: (done) ->
    @request
      .post('/api/1/test/login')
      .send(@identity)
      .expect(200)
      .end (err, res) ->
        return done err if err?

        agent.saveCookies res
        done()

    null

  Logout: (done) ->
    req = @request.post('/api/1/test/logout')

    @AttachCookie req
    req
      .expect(200)
      .end done

    null

  Get: (url, done) ->
    req = @request.get url

    @AttachCookie req
    req.expect 200, done

    null

  Post: (url, data, done) ->
    req = @request.post url

    @AttachCookie req
    req
      .send(data)
      .expect(200)
      .end done

    null

  Put: (url, data, done) ->
    req = @request.put url

    @AttachCookie req
    req
      .send(data)
      .expect(200)
      .end done

    null

  Delete: (url, done) ->
    req = @request.delete url

    @AttachCookie req
    req.expect 200, done

    null

  AttachCookie: (req) ->
    agent.attachCookies req

  SetIdentity: (login, pass) ->
    @identity.username = login
    @identity.password = pass

module.exports = Client
