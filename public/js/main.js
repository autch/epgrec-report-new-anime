$(function() {
    var update_visibility = function(e) {
	$('tr.prog-BS').toggle($('#hide-ch-type input[value="BS"]').prop("checked"));
	$('tr.prog-CS').toggle($('#hide-ch-type input[value="CS"]').prop("checked"));
	$('tr.prog-GR').toggle($('#hide-ch-type input[value="GR"]').prop("checked"));

	if($('#hide-prog-status input[value="f"]').prop("checked")) {
	    $('tr.f').hide();
	}
	if($('#hide-prog-status input[value="r"]').prop("checked")) {
	    $('tr.r').hide();
	}
	$('#count-shown').text($('table tbody tr:visible').length);
    };

    var initialize_toggle = function(index, elem) {
	var $this = $(this);
	if($this.prop("checked")) $this.parent("label").button("toggle");
    };

    $('#hide-ch-type input').each(initialize_toggle);
    $('#hide-prog-status input').each(initialize_toggle);


    update_visibility();

    $("#hide-prog-status").on("change", "input", update_visibility);
    $("#hide-ch-type").on("change", "input", update_visibility);
});

