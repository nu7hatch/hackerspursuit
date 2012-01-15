randOrd = ->
  Math.round(Math.random())-0.5

$(document).ready ->
  soundManager.url = "/swfs/"

  soundManager.onready ->
    soundManager.createSound
      id: 'wrong'
      url: ['/sounds/wrong.mp3', '/sounds/wrong.acc', '/sounds/wrong.ogg']
      autoLoad: true

    soundManager.createSound
      id: 'correct'
      url: ['/sounds/correct.mp3', '/sounds/correct.acc', '/sounds/correct.ogg']
      autoLoad: true

  ### Communication ###
  
  socket   = null
  started  = false

  startGame = ->
    $('#view-login').hide()
    $('#view-wait').fadeIn()
    
    $(document).keydown (event) ->
      key = if event.keyCode then event.keyCode else event.which
      
    $('#a1, #a2, #a3, #a4').click ->
      sendAnswer($(this).attr("data-answer"))
  
  connect = ->
    socket = io.connect(host, { 'port': parseInt(port) })
    socket.on "connect", ->
      id = socket.socket.sessionid
      $.getJSON "/user/auth-socket.json?id=#{id}", (data) =>
        startGame()
        if data.success

          socket.on "question.new", (question) ->
            if !started
              $('#view-wait').hide()
              $('#view-game').fadeIn()
              started = true
            
            $('.selected').removeClass('selected')
            for answer in [1..4]
              $('#a' + answer).fadeIn('fast')
              
            $('#question').text("#{question.category}: #{question.text}")

            keys = [1..4]
            keys.sort randOrd

            $('#a1').attr("data-answer", keys[0]).removeClass("selected").text(question['a' + keys[0]])
            $('#a2').attr("data-answer", keys[1]).removeClass("selected").text(question['a' + keys[1]])
            $('#a3').attr("data-answer", keys[2]).removeClass("selected").text(question['a' + keys[2]])
            $('#a4').attr("data-answer", keys[3]).removeClass("selected").text(question['a' + keys[3]])
          
          socket.on "answer.correct", (answer) ->
            console.log answer
            $('ul#answers li div[data-answer=' + answer + ']').addClass("selected")
            soundManager.play "correct"
          
          socket.on "answer.wrong", (answer) ->
            $('ul#answers li div[data-answer=' + answer + ']').addClass("selected")
            soundManager.play "wrong"
          
          socket.on "answer.twice", ->
            addAlert "ALREADY SELECTED AN ANSWER."
          
          socket.on "answer.over", ->
            addAlert "TIME IS OVER."    
            
          socket.on "question.countdown", (seconds) ->
            if started
              $('#countdown').html(seconds)
            else
              $('#countwait').html("JOINING IN #{seconds} SECONDS...")
          
          socket.on "scoreboard", (scoreboard) ->
            $('#scoreboard li').remove()
            for entry in scoreboard
              listEntry = $('<li>').html("#{entry.name}: #{entry.points}")
              $('#scoreboard').append listEntry

          socket.on "question.wait", (result) ->
            correct = result.correct
            
            if !started
              $('#countwait').html("GOOD LUCK!")
            $('#countdown').html("OVER")
              
            for answer in [1..4]
              $('ul#answers li div[data-answer=' + answer + ']').fadeOut() unless correct is "a#{answer}"
          
        else
          alert "Could not authenticate: #{data.error}"
      
  sendAnswer = (n) ->
    return unless socket?
    socket.emit('answer.set', { answer: n })
   
  ### Alerts and Notices ###
  
  addAlert = (msg) ->
    alertEntry = $('<li>').html("Alert: #{msg}").fadeIn().delay(3000).fadeOut()
    $('#alert').append alertEntry.toUpperCase()
      
  ### Views ###
  
  $('.view-content').hide()
  connect()