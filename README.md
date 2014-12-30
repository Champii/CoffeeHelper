# Nodulator

##### Under heavy development

## Concept

Nodulator is designed to make it more easy to create highly modulable REST APIs, with integrated ORM in CoffeeScript.

Open [exemple.coffee](https://github.com/Champii/Nodulator/blob/master/exemple.coffee) to see a full working exemple

You must understand how [express](https://github.com/strongloop/express) callback style works `(req, res, next) ->`


___
## Features

- Integrated ORM
- Integrated Routing system (with express, and highly linked with ORM)
- Multiple DB Systems
- Authentication with passport
- Permissions management
- Complex inheritance system
- Modulable
- Project generation

___
### Compatible modules and dependencies

- [Nodulator-Assets](https://github.com/Champii/Nodulator-Assets):
  - Automatic assets management
- [Nodulator-Socket](https://github.com/Champii/Nodulator-Socket):
  - Socket.io implementation for Nodulator
- [Nodulator-Angular](https://github.com/Champii/Nodulator-Angular):
  - Angular implementation for Nodulator
  - Inheritance system
  - Integrated and linked SocketIO
  - Assets management

___
## Jump To

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Resource](#resource)
  - [Basics](#basics)
  - [Class methods](#class-methods)
  - [Instance methods](#instance-methods)
- [Overriding and Inheritance](#overriding-and-inheritance)
  - [Override default behaviour](#override-default-behaviour)
  - [Abstract Class](#abstract-class)
  - [Complex inheritance system](#complex-inheritance-system)
- [Route](#route)
  - [Route Object](#route-object)
  - [DefaultRoute](#default-route-object)
  - [Route Inheritance](#route-inheritance)
- [Auth](#auth)
- [Restriction](#restriction)
- [DB Systems](#db-systems)
  - [Abstraction](#abstraction)
  - [Mysql](#mysql)
  - [MongoDB](#mongodb)
  - [SqlMem](#sqlmem)
- [Other Stuff](#other-stuff)
  - [Bus](#bus)
- [Modules](#modules)
  - [Usage](#usage)
  - [Module Hacking](#module-hacking)
- [Project Generation](#project-generation)
- [Developers](#developers)
- [Contributors](#contributors)
- [DOC](#doc)
- [TODO](#todo)
- [Changelog](#changelog)

___
## Installation

Just run :
```
npm install nodulator
```
Or check the [Project Generation](#project-generation) section

After you can require `Nodulator` as a module :

```coffeescript
Nodulator = require 'nodulator'
```

___
## Quick Start

Here is the quickiest way to play around `Nodulator`

```coffeescript
_ = require 'underscore'
Nodulator = require 'nodulator'

class PlayerRoute extends Nodulator.Route.DefaultRoute
  Config: ->

    # We create: GET => /api/1/{resource_name}/usernames
    # Get a list of every players' usernames
    @Get '/usernames', (req, res) =>

      # There is a @resource property, containing attached Resource class
      @resource.ListUsernames (err, usernames) ->
        return res.status(500).send err if err?

        res.status(200).send usernames

    # We call super() to apply Nodulator.Route.DefaultRoute behaviour
    # We called '/usernames' route before, so it won't be override by
    # default route GET => /api/1/{resource_name}/:id
    super()

    # We create: PUT => /api/1/{resource_name}/:id/levelUp
    @Put, '/:id/levelUp', (req, res) =>

      # For DefaultRoute routes with '/:id/*',
      # Fetch the corresponding Resource and put the instance in req[@resource.lname]
      # (here it can be called 'req.player' but we want to stay generic)
      req[@resource.lname].LevelUp (err, resource) ->
        return res.status(500).send err if err?

        res.status(200).send resource.ToJSON()

# We create a resource, and we attach the PlayerRoute
# The {account: true} config object tell us that it's an Account Resource
# It will hold all the authentication logic of the app
class PlayerResource extends Nodulator.Resource 'player', PlayerRoute, {account: true}

  # We create a LevelUp method
  LevelUp: (done) ->
    @level++
    @Save done

  # And a class method to get a list of usernames
  @ListUsernames: (done) ->
    @List (err, players) ->
      return done err if err?

      done null, _(players).pluck 'username'

# And we Init()
PlayerResource.Init()

```

Go inside your project folder, copy this POC in a `test.coffee` file and type in:

`$> coffee test.coffee`

Then open your favorite REST API Client ([Postman for Chrome](https://www.google.fr/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&ved=0CCMQFjAA&url=https%3A%2F%2Fchrome.google.com%2Fwebstore%2Fdetail%2Fpostman-rest-client%2Ffdmmgilgnpjigdojojpjoooidkmcomcm%3Fhl%3Den&ei=Tu6iVMqpJZDaatmGgOAL&usg=AFQjCNHaecLwAKk91gpdCY_y1x_ViIrHwQ&sig2=3FcPD7i2Id8La26xJt4PJA&bvm=bv.82001339,d.d2s) is my favorite)

and try the following routes :

```
Each route is of the following form :

{VERB}  {URL}                       ({PARAMS})                                          => (code) {ANSWER}

# Signup process
POST    '/api/1/players'            {username: 'test1', password: 'test1', level: 1}    => (200) {id: 1, username: 'test1', password: 'test1', level: 1}
POST    '/api/1/players'            {username: 'test2', password: 'test2', level: 1}    => (200) {id: 2, username: 'test2', password: 'test2', level: 1}

# Login process
POST    '/api/1/players/login'      {username: 'test1', password: 'test1'}              => (200) {}
POST    '/api/1/players/login'      {username: 'test1', password: 'badpassword'}        => (403) {}

GET     '/api/1/players'                                                                => (200) [{id: 1, username: 'test1', password: 'test1', level: 1},
                                                                                                  {id: 2, username: 'test2', password: 'test2', level: 1}]

GET     '/api/1/players/1'                                                              => (200) {id: 1, username: 'test1', password: 'test1', level: 1}
GET     '/api/1/players/2'                                                              => (200) {id: 2, username: 'test2', password: 'test2', level: 1}

PUT     '/api/1/players/2/levelUp'  {}                                                  => (200) {id: 2, username: 'test2', password: 'test2', level: 2}
PUT     '/api/1/players/2/levelUp'  {}                                                  => (200) {id: 2, username: 'test2', password: 'test2', level: 3}

GET     '/api/1/players/usernames'                                                      => (200) ['test1', 'test2']

PUT     '/api/1/players/2'          {username: 'notAUsername'}                          => (200) {id: 2, username: 'notAUsername', level: 3}

GET     '/api/1/players/usernames'                                                      => (200) ['test1', 'notAUsername']

DELETE  '/api/1/players/1'          {}                                                  => (200) {id: 1, username: 'test1', password: 'test1', level: 1}

GET     '/api/1/players/usernames'                                                      => (200) ['notAUser,ame']
```

___
## Configuration

First of all, the configuration process is absolutly optional.

If you don't give Nodulator a config, it will assume you want to use [SqlMem](#sqlmem) DB system, with no persistance at all. Usefull for heavy tests periods.

If you prefere to use a persistant system, here is the procedure :

```coffeescript
Nodulator = require 'nodulator'

Nodulator.Config
  dbType: 'Mongo'     # You can select 'SqlMem' or 'Mongo' or 'Mysql'
  dbAuth:             # Fields needed if Mongo or Mysql
    host: 'localhost'
    database: 'test'
    port: 27017       # From there, can be ignored. Default values taken
    user: 'test'      # |
    pass: 'test'      # |_
```

`Nodulator` provides 2 main Objects :

```coffeescript
Nodulator.Resource
Nodulator.Route
```

___
## Resource

#### Basics

A `Resource` is a class permitting to retrive and save a model from a DB.

Here is an exemple of creating a `Resource`

```coffeescript
PlayerResource = Nodulator.Resource 'player'

PlayerResource.Init()
```

Here, it creates a `PlayerResource`, linked with a `players` table in DB (if any), and with `/api/1/players` routes (if any)

Note the 's' concatenated with the `Resource` name. Its the real `Resource.name` of a resource

For the same name without the 's', there is a `Resource.lname` property.

##### /!\ Never forget to call Init() /!\

It's needed in order to prepare the `Resource`. All the `Nodulator`'s magic is inside this call.

If you forget it :
- The `Resource` will NOT be linked to `Route` (if any)
- It will NOT prepare `Account` system (if any)
- It will NOT prepare inheritance system so you won't be able to inherit from it
- It will NOT be linked to a corresponding table in DB
- Nothing will work or happend. Ever.

##### /!\ Please read this section again /!\

You can pass several params to `Nodulator.Resource` :

```coffeescript
Nodulator.Resource name [, Route] [, config]
```

You must provide a name, that is different of `'user'` (reserved)

You can attach a [Route](#route) and/or a config object (see [Auth](#auth)) to a `Resource`.


#### Class methods

Each `Resource` provides some 'Class methods' to manage the specific model in db :

```coffeescript
PlayerResource.Fetch(id, done)
PlayerResource.FetchBy(field, value, done)
PlayerResource.List(id, done)
PlayerResource.ListBy(field, value, done)
PlayerResource.Deserialize(blob, done)
```

The `Fetch` method take an id and return a `PlayerResource` intance to `done` callback :

```coffeescript
PlayerResource.Fetch 1, (err, player) ->
  return console.error err if err?

  [...] # Do something with player instance
```

You can also call `FetchBy` method to give a specific field to retrive.
It can be unique, or the first occurence in DB will return (depends on DB implementations)

You can list every models from this `Resource` thanks to `List` call :

```coffeescript
PlayerResource.List (err, players) ->
  return console.error err if err?

  [...] # players is an array of PlayerResource instance
```

Like `FetchBy`, you can `ListBy` a specific field.

The `Deserialize` method allow to get an instance of a given `Resource`.

Never use `new` operator directly on a `Resource`, else you might bypass the relationning system.

`Deserialize` method is used to make pre-processing work (like fetching related models) before instantiation.

#### Instance methods

A player instance has some methods :

```
player.Save(done)
    Save the model in DB. The callback take 2 arguments : (err, instance) ->

player.Delete(done)
    Delete the model from the DB. The callback take 1 argument : (err) ->

player.Serialize()
    Get every object properties, and return it in a new object.
    Generaly used to get what to be saved in DB.

player.ToJSON()
    By default, it calls Serialize().
    Generaly used to get what to send to client.
```

____
## Overriding and Inheritance

You can inherit from a `Resource` to override or enhance its default behaviour, or to make a complex class inheritance system built on `Resource`

#### Override default behaviour
In CoffeeScript its pretty easy:

```coffeescript
class UnitResource extends Nodulator.Resource 'unit'

  # Here we override the constructor to attach a weapon resource
  # Never forget to call super(blob), or the instance will never be populated by DB fields
  constructor: (blob, @weapon) ->
    super blob

  # We create a new instance method
  LevelUp: (done) ->
    @level++
    @Save done

  # Here we override the Deserialize class method, to fetch the attached WeaponResource
  @Deserialize: (blob, done) ->

    # If the resource isnt deserialized from db, don't fetch attached resource
    if !(blob.id?)
      return super blob, done

      WeaponResource.FetchByUserId blob.id, (err, weapon) =>
        res = @
        done(null, new res(blob, weapon))

  UnitResource.Init()
```

#### Abstract class

You can define an abstract class, that won't be attached to any model in DB or any `Route`

```coffeescript
class UnitResource extends Nodulator.Resource 'unit', {abstract: true}
  [...]

UnitResource.Init();
```

Of course, abstract classes are only designed to be inherited. (Please note that they can't have a `Route` attached, and other config is ignored)

#### Complex inheritance system

Given the last exemple, here is a class that inherits from `UnitResource`

```coffeescript
# Note the call to 'Extend()' method
class PlayerResource extends UnitResource.Extend 'player'

  # Give PlayerResource a new beheviour
  NewBehaviour: (args, done) ->
    [...]

  # Overriding existing UnitResource LevelUp()
  LevelUp: (done) ->
    [...]

PlayerResource.Init();
```

You can call the Extend() method either from a full `Resource` or from an `abstract` one.

Please note that if both parent and child are full `Resource`, both will have corresponding model available from ORM (here `units` and `players`)

So be carefull when creating extended `Resource`, and think about `abstract` !

___
## Route

#### Route Object

`Nodulator` provides a `Route` object, to be attached to a `Resource` object in order to describe routing process.

```coffeescript
class UnitResource extends Nodulator.Resource 'unit', Nodulator.Route
```

There is no need of `Init()` here. Ever.

Default `Nodulator.Route` do nothing. You have to inherit from it to describe routes :

```coffeescript
class UnitRoute extends Nodulator.Route

  # Override the Config() method
  Config: ->

    # And never forget to call the super()
    super()

    # Here we define: GET => /api/1/{resource_name}/:id
    @Get '/:id', (req, res) =>

      # The @resource field points to attached Resource
      @resource.Fetch req.params.id, (err, unit) ->
        return res.status(500).send err if err?

        res.status(200).send unit.ToJSON()

    # Here we define: POST => /api/1/{resource_name}
    @Post (req, res) ->
      res.status(200).end()
```

This `Route`, attached to a `Resource` (here `UnitResource`) add 2 endpoints :

```
GET  => /api/1/units/:id
POST => /api/1/units
```

Each `Route` have to implement a `Config()` method, calling `super()` and defining routes thanks to 'verbs' route calls (@Get(), @Post(), @Put(), @Delete(), @All()).

Here are all 'verb' route calls definition :

```coffeescript
Nodulator.Route.All     [endPoint = '/'], [middleware, [middleware, ...]], callback
Nodulator.Route.Get     [endPoint = '/'], [middleware, [middleware, ...]], callback
Nodulator.Route.Post    [endPoint = '/'], [middleware, [middleware, ...]], callback
Nodulator.Route.Put     [endPoint = '/'], [middleware, [middleware, ...]], callback
Nodulator.Route.Delete  [endPoint = '/'], [middleware, [middleware, ...]], callback
```

#### Default Route Object

Nodulator provides also a standard route system for lazy : `Nodulator.Route.DefaultRoute`.
It setups 5 routes (exemple when attached to a PlayerResource) :

```
GET     => /api/1/players       => List
GET     => /api/1/players/:id   => Get One
POST    => /api/1/players       => Create
PUT     => /api/1/players/:id   => Update
DELETE  => /api/1/players/:id   => Delete
```

#### Route Inheritance

You can inherit from any route object :

```coffeescript
class TestRoute extends Nodulator.Route.DefaultRoute
```
And you can override existing route by providing same association verb + url. Exemple :

```coffeescript
class TestRoute extends Nodulator.Route.DefaultRoute
  Config: ->
    super()

    # Here we override the default GET => /api/1/{resource_name}/:id
    @Get '/:id', (req, res) =>
      [...]
```
___
## Auth

Authentication is based on Passport
You can assign a `Ressource` as `AccountResource` :

```coffeescript
config =
  account: true

class PlayerResource extends Nodulator.Resource 'player', config
```

Defaults fields for authentication are `'username'` and `'password'`

You can change them (optional) :

```coffeescript
config =
  account:
    fields:
      usernameField: 'login'
      passwordField: 'pass'

class PlayerManager extends Nodulator.Resource 'player', config
```

It creates a custom method from `usernameField`

```
*FetchByUsername(username, done)

  or if customized

*FetchByLogin(login, done)

* Class methods
```

It defines 2 routes (here when attached to a `PlayerResource`) :

```
POST   => /api/1/players/login
POST   => /api/1/players/logout
```

It setup session system, and thanks to Passport,

It fills `req.user` variable to handle public/authenticated routes

You have to `extend` yourself the `post` default route (for exemple) of your `Resource` to use it as a signup route.

___
## Restriction

USER:

You can restrict access to a `Resource` :

```coffeescript
config =
  account: true
  restricted: 'user' #Can be 'user', 'auth', or an object

class PlayerResource extends Nodulator.Resource 'player', config
```

This code create a `APlayer` resource that is an account,
and only player itself can access to its resource (GET, PUT and DELETE on own /api/1/players/:id)

`POST` and `GET-without-id` are still accessible for anyone (you can override them)

/!\ 'user' keyword must only be used on account resource

AUTH:

You can restrict access to a `Resource` for authenticated users only :

```coffeescript
config =
  restricted: 'auth'

class HiddenResource extends Nodulator.Resource 'hidden', config
```

This code create a `HiddenResource` that can only be accessed by authenticated users


OBJECT:

You can restrict access to a `Resource` for users that have particular property set :

```coffeescript
config =
  restricted:
    group: 1
    x: 'test'

class HiddenResource extends Nodulator.Resource 'hidden', config
```

It will deny access to whole resource for any users that don't have theses properties set

It's not possible anymore to put a certain rule on a certain route. Theses rules apply to the whole resource.

___
## Db Systems

#### Abstraction

We defined a driver interface for some DB implementations.

It's based on SQL `Table` concept. (see [lib/connectors/sql/index.coffee](https://github.com/Champii/Nodulator/blob/master/lib/connectors/sql/index.coffee))

```coffeescript
Table.Find(id, done)
Table.FindWhere(fields, where, done)
Table.Select(fields, where, options, done)
Table.Save(blob, done)
Table.Insert(blob, done)
Table.Update(blob, where, done)
Table.Delete(id, done)
```

Every `Resource` have an associated `Table` instance that links to the good table/document in the good DB driver system

#### Mysql

Built-in `MySQL` implementation ([node-mysql](https://github.com/felixge/node-mysql/)) for `Nodulator`

Check [lib/connectors/sql/Mysql.coffee](https://github.com/Champii/Nodulator/blob/master/lib/connectors/sql/Mysql.coffee)

#### MongoDB

Built-in `MongoDB` implementation ([mongous](https://github.com/amark/mongous)) for `Nodulator`

Check [lib/connectors/sql/Mongo.coffee](https://github.com/Champii/Nodulator/blob/master/lib/connectors/sql/Mongo.coffee)

#### SqlMem

Special DB driver, built on RAM.

It provides same options as others systems do, but nothing is stored. When you stop the server, everything is deleted.

Check [lib/connectors/sql/SqlMem.coffee](https://github.com/Champii/Nodulator/blob/master/lib/connectors/sql/SqlMem.coffee)

___
## Other stuff

#### Bus

There is a `Nodulator.bus` object that is basicaly an `EventEmitter`. Every objects in `Nodulator` use this bus.

Here are the emitted events:

- On a new `Resource` being inserted in DB, sends it after a `Serialize()` call
  - `Nodulator.bus.emit 'new_' + resource_name, @Serialize()`

- On a `Resource` being updated in DB, sends it after a `Serialize()` call
  - `Nodulator.bus.emit 'update_' + resource_name, @Serialize()`

- On a `Resource` being deleted from DB, sends it after a `Serialize()` call
  - `Nodulator.bus.emit 'delete_' + resource_name, @Serialize()`

Exemple

```coffeescript
PlayerResource = Nodulator.Resource 'player'

Nodulator.on 'new_player', (player) ->
  [...] # Do something with this brand new player
```

You can override default `Bus` by setting new class to Nodulator.Bus :

```coffeescript
Nodulator = require 'nodulator'
NewBus = require './NewBus'

Nodulator.Bus = NewBus
```

Always set new `Bus` before any new `Resource` call or any added `Module`

___
## Modules

#### Usage

To inject a module into `Nodulator`, preceed this way :

```coffeescript
Nodulator = require 'nodulator'
ModuleName = require 'nodulator-ModuleName'

Nodulator.Use ModuleName
```

Replace `ModuleName` with the module's name you want to load

#### Module Hacking

If you want to create a new module for `Nodulator`, you have to export a single function, taking `Nodulator` as parameter :

```coffeescript
module.exports = (Nodulator) ->
  [...] # Your module here
```

You can extend anything you want, as the whole `Nodulator` object is passed to your function.

Be carefull to `server/loadOrder.json`.

Watch how [other modules](#compatible-modules-and-dependencies) are made !

___
## Project Generation
You can get global `Nodulator` :

```
$> npm install -g nodulator
$> Nodulator
Usage: Nodulator (init) | (install (moduleName)| remove (moduleName))
```

Nodulator provides a way of installing modules easely
```
# If no arguments, install or remove Nodulator
$> Nodulator install
$> Nodulator remove

# Will install nodulator-assets
$> Nodulator install assets

# Will remove nodulator-socket
$> Nodulator remove socket
```

Then you can launch the `init` process :
```
$> Nodulator init
```

It creates the following structure :
```
main.coffee
package.json
settings/
server/
├── index.coffee
├── loadOrder.json
├── processors/
│   └── index.coffee
└── resources/
    └── index.coffee
```

And then find for every `Nodulator` modules installed, and call their respective `init` method.

It generate a `main.coffee` and a `package.json` with every modules pre-loaded.

The `server` folder is auto-loaded (check `server/index.coffee` and every `index.coffee` in subfolders).

Folders load order is defined in `server/loadOrder.json`, and is automaticaly managed by new modules installed (they care of the order)

You can immediately start to write `Resource` in `server/resources` !

___
## Developers

Never forget that I'm always available at champii.akronym@gmail.com for any questions

___
## Contributors

- [Champii](https://github.com/champii)
- [SkinyMonkey](https://github.com/skinymonkey)

___
## DOC

```
Nodulator

  Properties :
    Nodulator.app       => the express app
    Nodulator.express   => the express module
    Nodulator.passport  => the passport module
    Nodulator.server    => the http server
    Nodulator.authApp   => if this app handle passport authentication
    Nodulator.appRoot   => the app root path
    Nodulator.bus       => official bus (EventEmitter)
    Nodulator.Route     => Route object

  Nodulator.Resource(resourceName, [Route], [config])

    Create the resource Class

  Nodulator.Config(config)

    Change config

  Nodulator.Use(module)

    Inject a module inside Nodulator

  Nodulator.ExtendDefaultConfig(config)

    Add some fields to default configuration

  Nodulator.ExtendRunProcess(process)

    Add a function to be executed at Nodulator's 'Run()' call

  Nodulator.ListEndpoints(done)

    DEBUG PURPOSE
    List every api endpoint added by application

  Nodulator.Run()

    Launch Nodulator MainLoop and set last parameters after every Resource have Init()
    Process every Module functions

Resource

(Uppercase for Class, lowercase for instance)

  Resource.Fetch(id, done)

    Take an id and return it from the DB in done callback: (err, resource) ->

  Resource.FetchBy(field, value, done)

    Take a field and a value, and return first row from the DB in done callback: (err, resource) ->

  Resource.List(done)

    Return every records in DB for this resource and give them to done: (err, resources) ->

  Resource.ListBy(field, value, done)

    Take a field and a value, and return every row from the DB in done callback: (err, resources) ->

  Resource.Deserialize(blob, done)

    Method that take the blob returned from DB to make a new instance

  resource.Save(done)

    Save the instance in DB

    If the resource doesn't exists, it create and give it an id
    It return to done the current instance

  resource.Delete(done)

    Delete the record in DB, and return affected rows in done

  resource.Serialize()

    Return every properties that aren't functions or objects or are undefined
    This method is used to get what must be saved in DB

  resource.ToJSON()

    This method is used to get what must be send to client
    Call @Serialize() by default, but can be overrided

Route

  route.Get     [url = ''], [middleware, [middleware, [...]]], done)
  route.All     [url = ''], [middleware, [middleware, [...]]], done)
  route.Post    [url = ''], [middleware, [middleware, [...]]], done)
  route.Put     [url = ''], [middleware, [middleware, [...]]], done)
  route.Delete  [url = ''], [middleware, [middleware, [...]]], done)

    Create a route.

    'url' will be concatenated with '/api/{VERSION}/{RESOURCE_NAME}'. Optional
    'middleware' are optionals
    'done' is the express app callback: (req, res, next) ->

  route.Config()

    Called when a Route is associated with a Resource.
    This call prepare every routes, and must be inherited.

```

___
## ToDo

  By order of priority

    Better tests
    Field validation
    Better error management
    Log system
    Advanced Auth (Social + custom)
    Separate Auth process from Nodulator
    New Permission system
    Better++ routing system (Auto add on custom method ?)
    Relational models

___
## ChangeLog

30/12/14: v0.0.7
  - Separated `Socket` into a new module [Nodulator-Socket](https://github.com/Champii/Nodulator-Socket)
  - Added new methods for `@Get()`, `@Post()`, `@Delete()`, `@Put()`, `@All()` in `Route`
  - Replace old method `@All()` into `@_All()`. Is now a private call.
  - Improved README (added [Modules](#modules) section)
