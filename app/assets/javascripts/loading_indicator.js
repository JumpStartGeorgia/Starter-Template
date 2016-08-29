// Shows and hides the loading indicator when users switch pages

$(document).on("turbolinks:visit", function() {
  $(".loading-indicator").fadeIn();
});

$(document).on("turbolinks:load", function() {
  $(".loading-indicator").fadeOut();
});
