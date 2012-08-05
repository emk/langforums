$ ->
  # Allow use to customize language used in front end.
  $('.language-menu').change () ->
    #alert($(this).val())
    $.cookie("locale", $(this).val(), path: '/', expires: 30)
    location.reload()