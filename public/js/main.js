$(function() {
  var update_visibility = function() {
   
    $('tr.prog-BS').toggle($('input.hide-ch-type[data-ch-type="BS"]').prop("checked"));
    $('tr.prog-CS').toggle($('input.hide-ch-type[data-ch-type="CS"]').prop("checked"));
    $('tr.prog-GR').toggle($('input.hide-ch-type[data-ch-type="GR"]').prop("checked"));

    if($('input.hide-prog-status[data-prog-status="f"]').prop("checked")) {
      $('tr.f').hide();
    }
    if($('input.hide-prog-status[data-prog-status="r"]').prop("checked")) {
      $('tr.r').hide();
    }
  };

  update_visibility();

  $(document).on("change", "input.hide-prog-status", function(e) {
    update_visibility();
  });

  $(document).on("change", "input.hide-ch-type", function(e) {
    update_visibility();
  });

});

