$ ((app) ->
  app.Views.Base = Backbone.View.extend
    tagName: "div"
    className: "container-fluid"

    pubsub_init: ->
      PubSub.subscribe "GameCollection.sort", $.proxy(this.reRender, this)

    socket_init: ->
      # turn socket listeners
      app.socket.on "EndTurn", $.proxy((data) ->
        data = JSON.parse data
        model = app.Collections.Game.get data.id
        model.view.endTurn()
        model
      , this)

      app.socket.on "StartTurn", $.proxy((data) ->
        data = JSON.parse data
        model = app.Collections.Game.get data.id
        model.view.startTurn()
        model
      , this)

      # player socket listeners
      app.socket.on "NewPlayer", $.proxy((data) ->
        model = new this.playerModel JSON.parse(data)
        app.Collections.Game.push model
        new this.playerView model
        model
      , this)

      app.socket.on "ExistingPlayers", $.proxy((data) ->
        _.each JSON.parse(data), $.proxy((model) ->
          model = new this.playerModel model
          exists = _.find app.Collections.Player.models, (player) ->
            player.get("id") == model.get("id")
          app.Collections.Player.add model if exists == -1
          app.Collections.Game.add(model) if model.get("playing") == true
          new this.playerView model
          model
        , this)
      , this)

      app.socket.on "PlayerUpdate", $.proxy((data) ->
        data = JSON.parse data
        model = app.Collections.Game.get data.id
        model.set data
        model
      , this)

      app.socket.on "PlayerRemoved", $.proxy((data) ->
        data = JSON.parse data
        model = app.Collections.Game.get data.id
        app.Collections.Game.remove model
        model
      , this)

      # monster socket listeners
      app.socket.on "NewMonster", $.proxy((data) ->
        model = new this.monsterModel JSON.parse(data)
        app.Collections.Game.push model
        new this.monsterView model
        model
      ,this)

      app.socket.on "ExistingMonsters", $.proxy((data) ->
        _.each JSON.parse(data), $.proxy((model) ->
          model = new this.monsterModel model
          exists = _.find app.Collections.Monster.models, (monster) ->
            monster.get("id") == model.get("id")
          app.Collections.Monster.add model if exists == -1
          app.Collections.Game.add(model) if model.get("playing") == true
          new this.monsterView model
          model
        , this)
      , this)

      app.socket.on "MonsterUpdate", $.proxy((data) ->
        data = JSON.parse data
        model = app.Collections.Game.get data.id
        model.set data
        model
      , this)

      app.socket.on "MonsterRemoved", $.proxy((data) ->
        data = JSON.parse data
        model = app.Collections.Game.get data.id
        app.Collections.Monster.remove model
        model
      , this)

    initialize: ->
      this.template = app.Templates.base
      this.render()

      this.playerModel = app.Models.Player
      this.playerView = app.Views.Player
      this.monsterModel = app.Models.Monster
      this.monsterView = app.Views.Monster

      this.pubsub_init()
      this.socket_init()

      this

    render: ->
      this.$el.html Mustache.render this.template
      this.$el

    reRender: () ->
      this.$el.find(".game").html ""

      _.each app.Collections.Game.models, $.proxy((member) ->
        view = member.view
        this.$el.find(".game").append view.$el
        view.postRender()
      , this)

  this
)(window.LKT)
