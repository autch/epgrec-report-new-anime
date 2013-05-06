$(function() {
  $('tr.f').hide();
  $('#show-hidden-prg').parent("li").toggleClass("active");
  $('#show-hidden-prg').click(function() { $('tr.f').toggle(); $(this).parent("li").toggleClass("active"); });
  $('#show-reserved-prg').click(function() { $('tr.r').toggle(); $(this).parent("li").toggleClass("active"); });
});

