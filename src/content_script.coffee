url = location.href

if /redmine/.test(url) and (/\/edit$/.test(url) or /\/edit\?.+$/.test(url))
  # post message to background
  chrome.extension.sendRequest {}, (response) ->

  do (document = this.document, xhr = new XMLHttpRequest()) ->
    styleSheet = document.createElement "style"
    inlineCSS  = ".jstEditor { overflow: hidden; float: none; display: inline-block; }
  #content_text { box-sizing: border-box; position: relative; float: left; height: 89.5vh; max-height: 90vh; }
  #preview { padding-left: 10px; float: right; height: 89.5vh; max-height: 90vh; overflow: scroll; }
  #preview fieldset { margin-top: 0; }
  #preview legend { display: none; }
  .view_toggle input { display: none; }
  .view_toggle label { display: block; float: left; cursor: pointer; width: 80px; margin: 0; padding: 12px 5px; border-right: 1px solid #abb2b7; background: #bdc3c7; color: #555e64; font-size: 14px; text-align: center; line-height: 1; transition: .2s; }
  .view_toggle label:first-of-type { border-radius: 3px 0 0 3px; }
  .view_toggle label:last-of-type { border-right: 0px; border-radius: 0 3px 3px 0; }
  .view_toggle input[type=\"checkbox\"]:checked + label { background-color: #a1b91d; color: #fff; }"

    class LiveEdit
      constructor: ->
        @form        = document.getElementById "wiki_form"
        @editor      = document.getElementById "content_text"
        @origPreview = document.getElementById "preview"
        @preview     = @origPreview.cloneNode()
        @keyTimerId  = null
        @origValues  = do (p = @form.getElementsByTagName "p") =>
          target  = p[p.length - 1].getElementsByTagName("a")[0]
          params  = target.getAttribute "onclick"

          # ~ Redmine 2.0
          if /^new\sajax\.updater/i.test params
            regex   = /\(\'\w+\',\s\'(.+\/preview)\',\s.+encodeURIComponent\(\'(.+)\'\)/g
            excuted = regex.exec params

            return {
              url   : excuted[1]
              token : encodeURIComponent excuted[2]
            }
          # Redmine 2.1 ~
          else
            regex   = /\w+\(\"(.+\/preview)\"\,\s/g
            excuted = regex.exec params

            return {
              url   : excuted[1]
              token : @form.authenticity_token["value"]
            }

        @baseParams = do (i = 0) =>
          input  = @form.getElementsByTagName "input"
          params = []

          while i < input.length
            params.push @serializer(input[i])
            i++

          params.push "authenticity_token=#{@origValues.token}"
          return params.join "&"

        @initElement()
        @observeKeyEvent()
        @addViewToggle()

      initElement: ->
        @editor.parentNode.appendChild @preview
        @origPreview.parentNode.removeChild @origPreview

        styleSheet.innerText = inlineCSS
        document.body.appendChild styleSheet

        @updatePreview()

      observeKeyEvent: ->
        @editor.addEventListener "keyup", =>
          clearTimeout @keyTimerId
          @keyTimerId = setTimeout =>
            @updatePreview()
          , 1000
        , false

      serializer: (element) ->
        key = encodeURIComponent(element["name"]).replace /%20/g, "+"
        val = element["value"].replace /(\r)?\n/g, "\r\n"
        val = encodeURIComponent(val).replace /%20/g, "+"

        return "#{key}=#{val}"

      updatePreview: ->
        loader   = document.getElementById "ajax-indicator"
        callback = =>
          @editor.style.minHeight = "#{@preview.offsetHeight}px"
          loader.style.display    = "none"

        do (textContent = @serializer @editor) =>
          xhr.onreadystatechange = =>
            if xhr.readyState is 4 and xhr.status is 200
              @preview.innerHTML = xhr.responseText
              callback()
            else
              loader.style.display = "block"

          xhr.open "post", @origValues.url, true
          xhr.setRequestHeader "Content-Type", "application/x-www-form-urlencoded"
          xhr.send "#{@baseParams}&#{textContent}"

      addViewToggle: ->

        preview = document.getElementById('preview')
        content_text = document.getElementById('content_text')

        parent = document.getElementsByClassName('box tabular')[0]

        div = document.createElement('div')
        div.setAttribute('class', 'view_toggle')
        div.style.display = 'inline-block'
        parent.insertBefore(div, document.getElementsByClassName('jstEditor')[0])

        checkBox1 = document.createElement('input')
        checkBox1.setAttribute('type', 'checkbox')
        checkBox1.setAttribute('id', 'toggle_content_text')
        checkBox1.checked = true

        label1 = document.createElement('label')
        label1.setAttribute('for', 'toggle_content_text')
        label1.innerHTML = 'Editor'

        checkBox2 = document.createElement('input')
        checkBox2.setAttribute('type', 'checkbox')
        checkBox2.setAttribute('id', 'toggle_preview')
        checkBox2.checked = true

        label2 = document.createElement('label')
        label2.setAttribute('for', 'toggle_preview')
        label2.innerHTML = 'Preview'

        checkBox1.onchange = =>
          if checkBox1.checked and not checkBox2.checked
            content_text.style.width = '95vw'
            content_text.style.display = 'block'
            preview.style.width = '0'
            preview.style.display = 'none'
          else if not checkBox1.checked and checkBox2.checked
            content_text.style.width = '0'
            content_text.style.display = 'none'
            preview.style.width = '95vw'
            preview.style.display = 'block'
          else if checkBox1.checked and checkBox2.checked
            content_text.style.width = '29.5vw'
            content_text.style.display = 'block'
            preview.style.width = 'calc(69.5vw - 52px)'
            preview.style.display = 'block'
          else
            preview.style.display = 'none'
            content_text.style.display = 'none'

        checkBox2.onchange = =>
          if checkBox2.checked and not checkBox1.checked
            content_text.style.width = '0'
            content_text.style.display = 'none'
            preview.style.width = '95vw'
            preview.style.display = 'block'
          else if not checkBox2.checked and checkBox1.checked
            content_text.style.width = '95vw'
            content_text.style.display = 'block'
            preview.style.width = '0'
            preview.style.display = 'none'
          else if checkBox2.checked and checkBox1.checked
            content_text.style.width = '29.5vw'
            content_text.style.display = 'block'
            preview.style.width = 'calc(69.5vw - 52px)'
            preview.style.display = 'block'
          else
            preview.style.display = 'none'
            content_text.style.display = 'none'


        checkBox1.onchange()
        checkBox2.onchange()

        div.appendChild(checkBox1)
        div.appendChild(label1)
        div.appendChild(checkBox2)
        div.appendChild(label2)


    liveEdit = new LiveEdit()
